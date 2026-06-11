import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

interface ReminderConfig {
  key: string;
  enabled: boolean;
  lead_minutes: number;
  title_en: string;
  title_ar: string;
  body_en: string;
  body_ar: string;
}

const HOURLY_CATEGORIES = ["sports", "farm", "restaurant"];
const REMINDER_WINDOW_MIN = 5;

function pemToDer(pem: string): Uint8Array {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

function toBase64Url(value: string | Uint8Array): string {
  const str = typeof value === "string" ? value : String.fromCharCode(...value);
  return btoa(str).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

async function getFcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = toBase64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = toBase64Url(
    JSON.stringify({
      iss: sa.client_email,
      sub: sa.client_email,
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    }),
  );

  const signingInput = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${toBase64Url(new Uint8Array(sig))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!data.access_token) {
    throw new Error(`FCM token exchange failed: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

async function sendOne(
  fcmToken: string,
  title: string,
  body: string,
  projectId: string,
  accessToken: string,
  badge: number,
  data?: Record<string, string>,
): Promise<{ ok: boolean; staleToken?: boolean; error?: string }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data: data ?? {},
          android: {
            priority: "HIGH",
            // notification_count drives the app-icon badge count on launchers
            // that support it (mirrors the iOS aps.badge value).
            notification: { channel_id: "wensa_default", notification_count: badge },
          },
          apns: {
            headers: { "apns-priority": "10" },
            payload: {
              aps: { alert: { title, body }, sound: "default", badge },
            },
          },
        },
      }),
    },
  );
  if (!res.ok) {
    const err = await res.text();
    // UNREGISTERED / NOT_FOUND means the token is expired or belongs to an
    // old app registration — prune it silently rather than treating it as a
    // real delivery error.
    const staleToken =
      res.status === 404 ||
      err.includes("UNREGISTERED") ||
      err.includes("registration-token-not-registered");
    if (!staleToken) {
      console.error(`[FCM] send error for token ${fcmToken.slice(0, 20)}…: ${err}`);
    }
    return { ok: false, staleToken, error: err };
  }
  return { ok: true };
}

/// Fetch every device token for the given users → { user_id: [token, …] }.
/// One row per device, so a user signed in on several devices gets several.
async function getTokensByUser(
  supabase: any,
  userIds: string[],
): Promise<Record<string, string[]>> {
  const map: Record<string, string[]> = {};
  if (!userIds.length) return map;
  const { data } = await supabase
    .schema("profiles")
    .from("user_fcm_tokens")
    .select("user_id, token")
    .in("user_id", userIds);
  for (const row of data ?? []) {
    (map[row.user_id] ??= []).push(row.token);
  }
  return map;
}

/// Count the user's unread inbox items. Used as the app-icon badge value so it
/// reflects how many notifications are waiting, not a constant 1.
async function getUnreadCount(supabase: any, userId: string): Promise<number> {
  const { count } = await supabase
    .schema("profiles")
    .from("user_notifications")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .is("read_at", null);
  return count ?? 0;
}

/// Send one notification to all of a user's device tokens. Prunes any token
/// FCM reports as stale. Returns how many devices were reached. `badge` is the
/// app-icon badge count to display (unread inbox count including this push).
async function sendToTokens(
  supabase: any,
  tokens: string[],
  title: string,
  body: string,
  projectId: string,
  accessToken: string,
  badge: number,
  data?: Record<string, string>,
): Promise<{ sent: number; errors: number; errorMsgs: string[] }> {
  let sent = 0;
  let errors = 0;
  const errorMsgs: string[] = [];
  for (const token of tokens) {
    const r = await sendOne(token, title, body, projectId, accessToken, badge, data);
    if (r.ok) {
      sent++;
    } else if (r.staleToken) {
      console.warn(
        `[FCM] pruning stale token ${token.slice(0, 24)}…: ${r.error ?? ""}`,
      );
      await supabase
        .schema("profiles")
        .from("user_fcm_tokens")
        .delete()
        .eq("token", token);
    } else {
      errors++;
      if (r.error) errorMsgs.push(r.error);
    }
  }
  return { sent, errors, errorMsgs };
}

Deno.serve(async (_req) => {
  try {
    const saRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!saRaw) throw new Error("FIREBASE_SERVICE_ACCOUNT secret not set");
    const sa: ServiceAccount = JSON.parse(saRaw);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const accessToken = await getFcmAccessToken(sa);
    let totalSent = 0;
    let totalErrors = 0;
    const fcmErrors: string[] = [];

    const { data: reminderRows } = await supabase
      .schema("admin")
      .from("notification_reminders")
      .select("*");
    const reminders: Record<string, ReminderConfig> = {};
    for (const row of reminderRows ?? []) reminders[row.key] = row as ReminderConfig;

    // ── 1. Booking reminders (hourly + concert) ──────────────────────────────
    for (const cfgKey of ["hourly", "concert"] as const) {
      const cfg = reminders[cfgKey];
      if (!cfg || !cfg.enabled) continue;

      const lead = cfg.lead_minutes;
      const from = new Date(Date.now() + (lead - REMINDER_WINDOW_MIN) * 60_000).toISOString();
      const to   = new Date(Date.now() + (lead + REMINDER_WINDOW_MIN) * 60_000).toISOString();

      let query = supabase
        .schema("bookings")
        .from("bookings")
        .select("id, user_id, category")
        .eq("status", "confirmed")
        .eq("payment_status", "paid")
        .is("reminder_sent_at", null)
        .gte("starts_at", from)
        .lte("starts_at", to);

      if (cfgKey === "concert") {
        query = query.eq("category", "concert");
      } else {
        query = query.in("category", HOURLY_CATEGORIES);
      }

      const { data: dueBookings } = await query;
      if (!dueBookings?.length) continue;

      const userIds = [...new Set(dueBookings.map((b: any) => b.user_id as string))];
      const { data: users } = await supabase
        .schema("profiles")
        .from("app_users")
        .select("id, preferred_locale")
        .in("id", userIds);
      const userMap = Object.fromEntries((users ?? []).map((u: any) => [u.id, u]));
      const tokensByUser = await getTokensByUser(supabase, userIds);

      for (const booking of dueBookings) {
        const user = userMap[booking.user_id];
        const tokens = tokensByUser[booking.user_id] ?? [];
        if (!user || tokens.length === 0) continue;

        const isAr = (user.preferred_locale ?? "en") === "ar";
        const title = isAr ? cfg.title_ar : cfg.title_en;
        const body  = isAr ? cfg.body_ar  : cfg.body_en;

        const badge = (await getUnreadCount(supabase, booking.user_id)) + 1;
        const { sent, errors, errorMsgs } = await sendToTokens(
          supabase, tokens, title, body, sa.project_id, accessToken, badge,
          { booking_id: booking.id, kind: cfgKey },
        );

        if (sent > 0) {
          await supabase
            .schema("bookings")
            .from("bookings")
            .update({ reminder_sent_at: new Date().toISOString() })
            .eq("id", booking.id);
          await supabase
            .schema("profiles")
            .from("user_notifications")
            .insert({
              user_id: booking.user_id,
              kind: cfgKey,
              title_en: cfg.title_en,
              title_ar: cfg.title_ar,
              body_en: cfg.body_en,
              body_ar: cfg.body_ar,
              data: { booking_id: booking.id },
            });
          totalSent += sent;
        }
        if (errors > 0) {
          fcmErrors.push(...errorMsgs);
          totalErrors += errors;
        }
      }
    }

    // ── 2. Membership expiry reminders ───────────────────────────────────────
    const memCfg = reminders["membership"];
    if (memCfg && memCfg.enabled) {
      const leadMs = memCfg.lead_minutes * 60_000;
      const windowMs = 30 * 60_000;
      const targetFromIso = new Date(Date.now() + leadMs - windowMs).toISOString();
      const targetToIso   = new Date(Date.now() + leadMs + windowMs).toISOString();

      const { data: dueMemberships } = await supabase
        .schema("bookings")
        .from("memberships")
        .select("id, user_id, ends_at")
        .eq("status", "active")
        .is("reminder_sent_at", null)
        .gte("ends_at", targetFromIso)
        .lte("ends_at", targetToIso);

      if (dueMemberships?.length) {
        const userIds = [...new Set(dueMemberships.map((m: any) => m.user_id as string))];
        const { data: users } = await supabase
          .schema("profiles")
          .from("app_users")
          .select("id, preferred_locale")
          .in("id", userIds);
        const userMap = Object.fromEntries((users ?? []).map((u: any) => [u.id, u]));
        const tokensByUser = await getTokensByUser(supabase, userIds);

        for (const m of dueMemberships) {
          const user = userMap[m.user_id];
          const tokens = tokensByUser[m.user_id] ?? [];
          if (!user || tokens.length === 0) continue;

          const isAr = (user.preferred_locale ?? "en") === "ar";
          const title = isAr ? memCfg.title_ar : memCfg.title_en;
          const body  = isAr ? memCfg.body_ar  : memCfg.body_en;

          const badge = (await getUnreadCount(supabase, m.user_id)) + 1;
          const { sent, errors, errorMsgs } = await sendToTokens(
            supabase, tokens, title, body, sa.project_id, accessToken, badge,
            { membership_id: m.id, kind: "membership" },
          );

          if (sent > 0) {
            await supabase
              .schema("bookings")
              .from("memberships")
              .update({ reminder_sent_at: new Date().toISOString() })
              .eq("id", m.id);
            await supabase
              .schema("profiles")
              .from("user_notifications")
              .insert({
                user_id: m.user_id,
                kind: "membership",
                title_en: memCfg.title_en,
                title_ar: memCfg.title_ar,
                body_en: memCfg.body_en,
                body_ar: memCfg.body_ar,
                data: { membership_id: m.id },
              });
            totalSent += sent;
          }
          if (errors > 0) {
            fcmErrors.push(...errorMsgs);
            totalErrors += errors;
          }
        }
      }
    }

    // ── 3. Broadcasts & direct notifications ─────────────────────────────────
    const { data: broadcasts } = await supabase
      .schema("admin")
      .from("broadcasts")
      .select("*")
      .eq("status", "pending")
      .or(`scheduled_at.is.null,scheduled_at.lte.${new Date().toISOString()}`);

    if (broadcasts?.length) {
      const { data: allUsers } = await supabase
        .schema("profiles")
        .from("app_users")
        .select("id, preferred_locale");

      for (const broadcast of broadcasts) {
        await supabase
          .schema("admin")
          .from("broadcasts")
          .update({ status: "sending" })
          .eq("id", broadcast.id);

        const audience = broadcast.target_user_id
          ? (allUsers ?? []).filter((u: any) => u.id === broadcast.target_user_id)
          : (allUsers ?? []);
        const tokensByUser = await getTokensByUser(
          supabase, audience.map((u: any) => u.id),
        );

        // bSent counts users reached; totalSent below counts device pushes.
        let bSent = 0;
        let bErrors = 0;

        const broadcastKind = `broadcast_${broadcast.type ?? "general"}`;

        for (const user of audience) {
          const tokens = tokensByUser[user.id] ?? [];
          if (tokens.length === 0) continue;
          const isAr = (user.preferred_locale ?? "en") === "ar";
          const title = isAr ? broadcast.title_ar : broadcast.title_en;
          const body  = isAr ? broadcast.body_ar  : broadcast.body_en;
          if (!title || !body) continue;

          const badge = (await getUnreadCount(supabase, user.id)) + 1;
          const { sent, errors, errorMsgs } = await sendToTokens(
            supabase, tokens, title, body, sa.project_id, accessToken, badge,
            { broadcast_id: broadcast.id, kind: broadcastKind },
          );
          if (sent > 0) {
            await supabase
              .schema("profiles")
              .from("user_notifications")
              .insert({
                user_id: user.id,
                kind: broadcastKind,
                title_en: broadcast.title_en,
                title_ar: broadcast.title_ar,
                body_en: broadcast.body_en,
                body_ar: broadcast.body_ar,
                data: { broadcast_id: broadcast.id },
              });
            bSent++;
            totalSent += sent;
          }
          if (errors > 0) {
            fcmErrors.push(...errorMsgs);
            bErrors++;
          }
        }

        const finalStatus =
          bSent === 0 && bErrors > 0 ? "failed"
          : bErrors > 0 ? "partial"
          : "sent";

        await supabase
          .schema("admin")
          .from("broadcasts")
          .update({
            status: finalStatus,
            sent_at: new Date().toISOString(),
            sent_count: bSent,
            error_count: bErrors,
          })
          .eq("id", broadcast.id);

        // totalSent is already incremented per device push inside the loop.
        totalErrors += bErrors;
      }
    }

    console.log(`[process-notifications] sent=${totalSent} errors=${totalErrors} fcmErrors=${JSON.stringify(fcmErrors)}`);
    return new Response(
      JSON.stringify({ ok: true, sent: totalSent, errors: totalErrors, fcmErrors }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("[process-notifications] fatal:", e);
    return new Response(
      JSON.stringify({ ok: false, error: String(e) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});

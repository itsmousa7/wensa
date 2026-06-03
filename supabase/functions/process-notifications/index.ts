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
            notification: { channel_id: "wensa_default" },
          },
          apns: {
            headers: { "apns-priority": "10" },
            payload: {
              aps: { alert: { title, body }, sound: "default", badge: 1 },
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
        .select("id, fcm_token, preferred_locale")
        .in("id", userIds)
        .not("fcm_token", "is", null);
      const userMap = Object.fromEntries((users ?? []).map((u: any) => [u.id, u]));

      for (const booking of dueBookings) {
        const user = userMap[booking.user_id];
        if (!user?.fcm_token) continue;

        const isAr = (user.preferred_locale ?? "en") === "ar";
        const title = isAr ? cfg.title_ar : cfg.title_en;
        const body  = isAr ? cfg.body_ar  : cfg.body_en;

        const result = await sendOne(
          user.fcm_token, title, body, sa.project_id, accessToken,
          { booking_id: booking.id, kind: cfgKey },
        );

        if (result.ok) {
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
          totalSent++;
        } else if (result.staleToken) {
          await supabase
            .schema("profiles")
            .from("app_users")
            .update({ fcm_token: null })
            .eq("id", user.id);
        } else {
          if (result.error) fcmErrors.push(result.error);
          totalErrors++;
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
          .select("id, fcm_token, preferred_locale")
          .in("id", userIds)
          .not("fcm_token", "is", null);
        const userMap = Object.fromEntries((users ?? []).map((u: any) => [u.id, u]));

        for (const m of dueMemberships) {
          const user = userMap[m.user_id];
          if (!user?.fcm_token) continue;

          const isAr = (user.preferred_locale ?? "en") === "ar";
          const title = isAr ? memCfg.title_ar : memCfg.title_en;
          const body  = isAr ? memCfg.body_ar  : memCfg.body_en;

          const result = await sendOne(
            user.fcm_token, title, body, sa.project_id, accessToken,
            { membership_id: m.id, kind: "membership" },
          );

          if (result.ok) {
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
            totalSent++;
          } else if (result.staleToken) {
            await supabase
              .schema("profiles")
              .from("app_users")
              .update({ fcm_token: null })
              .eq("id", user.id);
          } else {
            if (result.error) fcmErrors.push(result.error);
            totalErrors++;
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
        .select("id, fcm_token, preferred_locale")
        .not("fcm_token", "is", null);

      for (const broadcast of broadcasts) {
        await supabase
          .schema("admin")
          .from("broadcasts")
          .update({ status: "sending" })
          .eq("id", broadcast.id);

        const audience = broadcast.target_user_id
          ? (allUsers ?? []).filter((u: any) => u.id === broadcast.target_user_id)
          : (allUsers ?? []);

        let bSent = 0;
        let bErrors = 0;

        const broadcastKind = `broadcast_${broadcast.type ?? "general"}`;

        for (const user of audience) {
          if (!user.fcm_token) continue;
          const isAr = (user.preferred_locale ?? "en") === "ar";
          const title = isAr ? broadcast.title_ar : broadcast.title_en;
          const body  = isAr ? broadcast.body_ar  : broadcast.body_en;
          if (!title || !body) continue;

          const result = await sendOne(
            user.fcm_token, title, body, sa.project_id, accessToken,
            { broadcast_id: broadcast.id, kind: broadcastKind },
          );
          if (result.ok) {
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
          } else if (result.staleToken) {
            // Prune the dead token so it never causes a false "partial" again
            await supabase
              .schema("profiles")
              .from("app_users")
              .update({ fcm_token: null })
              .eq("id", user.id);
          } else {
            if (result.error) fcmErrors.push(result.error);
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

        totalSent += bSent;
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

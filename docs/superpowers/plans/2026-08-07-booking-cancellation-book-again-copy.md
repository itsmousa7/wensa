# Booking Cancellation "Book Again" Copy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a booking is cancelled (with or without a refund), the push/inbox notification's body invites the user to book again, worded for the booking's type — "Book another hour!" for court sports, "Book another day!" for date/shift-based bookings.

**Architecture:** The full cancel → notify pipeline already exists live in Supabase (`booking-action` cancels/refunds a booking without ever deleting it; a DB trigger fires `booking-notification`, which builds bilingual copy and sends an FCM push + inbox row). None of this is in the local git repo. This plan pulls the one function that needs a change (`booking-notification`) into the repo, adds a category-aware call-to-action to its two copy-producing functions (`getCopy` for a plain cancellation, `getRefundCopy` for a refund), and deploys it live via the Supabase MCP tools — the same "apply live, verify live" workflow already used for recent DB migrations in this repo (see `docs/superpowers/plans/2026-08-06-farm-shift-price-override.md`).

**Tech Stack:** Deno edge function (TypeScript), deployed to Supabase project `qvozjwlkzordudkhamcu` via the `mcp__plugin_supabase_supabase__*` MCP tools — no local Supabase CLI push/deploy for this (this function isn't tracked in `supabase/config.toml` functions locally and the repo's DB migrations are already applied via MCP rather than `supabase db push`).

## Global Constraints

- No database schema changes — no new column, no new enum/check value, no new RPC. `status`/`payment_status` and the existing DB trigger already cover everything needed (see the design spec's "Out of scope" section, `docs/superpowers/specs/2026-08-07-booking-reversal-cancellation-design.md`).
- Only `booking-notification` changes. Do not touch `booking-action`, `booking-wayl-webhook`, `wayl-refund`, or any other live function.
- Booking categories: `sports` (padel/football courts, unified under one enum value — confirmed live-corrected during execution, see the note after Step 5) → hourly → "Book another hour!" / "احجز ساعة أخرى!". `farm`, `restaurant`, `concert` → date/shift-based → "Book another day!" / "احجز يومًا آخر!". Any other/unknown category also falls back to the day-based wording (matches `getCopy`'s existing `default:` branch, which already treats unrecognized categories as the non-hourly case).
- English and Arabic bodies must both change together — this app is bilingual throughout (see `ticket_status_badge.dart`'s existing `isArabic` pattern for the convention).
- Project ID for all MCP calls: `qvozjwlkzordudkhamcu`.

---

### Task 1: Pull `booking-notification` into the repo with category-aware cancellation copy

**Files:**
- Create: `supabase/functions/booking-notification/index.ts`

**Interfaces:**
- Produces: `getCopy(category, newStatus, locale)` and `getRefundCopy(placeName, amountIqd, category, locale)` — `getRefundCopy` gains a new `category: string` parameter inserted before `locale`, matching `getCopy`'s existing parameter order. The one call site in `Deno.serve` (the `isRefund` branch) is updated to pass `booking.category` through.

- [x] **Step 1: Write the full file with the copy change applied**

This function does not exist anywhere in this git repo yet (it was deployed straight to Supabase and never committed) — this step both introduces it to the repo and applies the fix in the same change, since there is no prior local version to diff against.

Create `supabase/functions/booking-notification/index.ts`:

```typescript
/**
 * booking-notification — FCM push notifications for booking status changes.
 *
 * Called by:
 *   - DB trigger (pg_net) on bookings.bookings status → confirmed / cancelled / expired
 *   - booking-wayl-webhook after payment confirmation (belt-and-suspenders)
 *
 * Payload: { booking_id: string, old_status: string, new_status: string }
 *
 * Env vars required:
 *   SUPABASE_URL               — project REST URL
 *   SUPABASE_SERVICE_ROLE_KEY  — to read booking + user data
 *   FIREBASE_SERVICE_ACCOUNT_JSON — base64-encoded Firebase service account key JSON
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ── Bilingual copy ─────────────────────────────────────────────────────────────

type Locale = "ar" | "en";

interface NotifCopy {
  title: string;
  body: string;
}

/** Booking categories billed/booked by the hour, as opposed to by the day/shift. */
const HOURLY_CATEGORIES = ["sports"];

/**
 * "Book again" call to action for a cancelled booking, worded for how that
 * category is actually booked: an hour for court sports, a day/shift for
 * everything else (farm, restaurant, concert, and any future category).
 */
function bookAgainCta(category: string, locale: Locale): string {
  const isHourly = HOURLY_CATEGORIES.includes(category);
  if (locale === "ar") {
    return isHourly ? "احجز ساعة أخرى!" : "احجز يومًا آخر!";
  }
  return isHourly ? "Book another hour!" : "Book another day!";
}

function getCopy(
  category: string,
  newStatus: string,
  locale: Locale,
): NotifCopy | null {
  const ar = locale === "ar";

  if (newStatus === "confirmed") {
    switch (category) {
      case "restaurant":
        return {
          title: ar ? "تم تأكيد حجزك في المطعم ✓" : "Reservation Confirmed ✓",
          body: ar
            ? "تم قبول حجزك من قبل المطعم. تفقد تفاصيل الحجز."
            : "Your reservation has been accepted. View your booking details.",
        };
      case "padel":
      case "football":
        return {
          title: ar ? "تم تأكيد حجزك ✓" : "Booking Confirmed ✓",
          body: ar
            ? "حجزك للملعب مؤكد. استعد للمباراة!"
            : "Your court booking is confirmed. Get ready to play!",
        };
      case "farm":
        return {
          title: ar ? "تم تأكيد حجزك ✓" : "Booking Confirmed ✓",
          body: ar
            ? "حجز المزرعة مؤكد. نراك قريباً!"
            : "Your farm booking is confirmed. See you soon!",
        };
      case "concert":
        return {
          title: ar ? "تم تأكيد تذكرتك ✓" : "Ticket Confirmed ✓",
          body: ar
            ? "تذكرتك مؤكدة. استعد للحفلة!"
            : "Your concert ticket is confirmed. Enjoy the show!",
        };
      default:
        return {
          title: ar ? "تم تأكيد الحجز ✓" : "Booking Confirmed ✓",
          body: ar
            ? "تم تأكيد حجزك بنجاح."
            : "Your booking has been confirmed.",
        };
    }
  }

  if (newStatus === "cancelled") {
    const cta = bookAgainCta(category, locale);
    return {
      title: ar ? "تم إلغاء الحجز" : "Booking Cancelled",
      body: ar
        ? `للأسف تم إلغاء حجزك. ${cta}`
        : `Your booking has been cancelled. ${cta}`,
    };
  }

  if (newStatus === "expired") {
    return {
      title: ar ? "انتهت صلاحية الحجز" : "Booking Expired",
      body: ar
        ? "انتهت صلاحية حجزك. يمكنك إجراء حجز جديد."
        : "Your booking has expired. You can make a new booking.",
    };
  }

  return null; // no notification for this status
}

function getRefundCopy(
  placeName: string | null,
  amountIqd: number | null,
  category: string,
  locale: Locale,
): NotifCopy {
  const ar = locale === "ar";
  const place = placeName ?? (ar ? "المكان" : "the venue");
  const amount = amountIqd != null ? amountIqd.toLocaleString("en-US") : "";
  const cta = bookAgainCta(category, locale);
  return {
    title: ar ? "تم إلغاء الحجز واسترجاع المبلغ" : "Booking Cancelled & Refunded",
    body: ar
      ? `تم إلغاء حجزك في ${place}${amount ? ` وتم إرجاع ${amount} د.ع إلى حسابك` : " وتم إرجاع المبلغ إلى حسابك"}. ${cta}`
      : `Your booking at ${place} was cancelled${amount ? ` and ${amount} IQD was returned to your account` : " and the amount was refunded"}. ${cta}`,
  };
}

// ── Main handler ──────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  // Project secrets use FIREBASE_SERVICE_ACCOUNT; older docs say _JSON — accept both
  // (mirrors _shared/fcm.ts). Without this, every call 500s with "FCM not configured".
  const FCM_SA_B64   = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ?? Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

  if (!FCM_SA_B64) {
    console.error("booking-notification: FIREBASE_SERVICE_ACCOUNT_JSON not set");
    return json({ error: "FCM not configured" }, 500);
  }

  try {
    const body = await req.json() as {
      booking_id?: string;
      membership_id?: string;
      old_status?: string;
      new_status?: string;
    };

    const { booking_id, membership_id, new_status } = body as {
      booking_id?: string; membership_id?: string; new_status?: string;
    };
    if ((!booking_id && !membership_id) || !new_status) {
      return json({ error: "booking_id or membership_id, and new_status are required" }, 400);
    }

    const svc = serviceHeaders(SERVICE_KEY);
    const isMembership = !!membership_id;
    const rowId = (membership_id ?? booking_id)!;
    const sourceTable = isMembership ? "memberships" : "bookings";

    // ── Fetch the row (booking or membership) ─────────────────────────────
    const selectCols = isMembership
      ? "id,user_id,place_id,payment_status,amount_iqd"
      : "id,category,user_id,place_id,event_id,payment_status,amount_iqd";
    const rowRes = await fetch(
      `${SUPABASE_URL}/rest/v1/${sourceTable}?id=eq.${rowId}&select=${selectCols}`,
      { headers: { ...svc, "Accept-Profile": "bookings" } },
    );
    const rowsJson = await rowRes.json().catch(() => []) as Array<Record<string, unknown>>;
    if (!Array.isArray(rowsJson) || !rowsJson.length) {
      console.warn(`booking-notification: ${sourceTable} not found ${rowId}`);
      return json({ skipped: true, reason: "row not found" }, 200);
    }
    const booking = {
      id: String(rowsJson[0].id),
      category: (rowsJson[0].category as string) ?? "membership",
      user_id: rowsJson[0].user_id as string,
      place_id: (rowsJson[0].place_id as string | null) ?? null,
      event_id: (rowsJson[0].event_id as string | null) ?? null,
      payment_status: (rowsJson[0].payment_status as string | null) ?? null,
      amount_iqd: (rowsJson[0].amount_iqd as number | null) ?? null,
    };

    // ── Build bilingual copy (refund-aware) ───────────────────────────────
    // Both languages: the inbox row stores en+ar, and each device is pushed in
    // its own language.
    const isRefund = new_status === "cancelled" && booking.payment_status === "refunded";
    let copyEn: NotifCopy | null;
    let copyAr: NotifCopy | null;
    let kind: string;

    if (isRefund) {
      let placeNameEn: string | null = null;
      let placeNameAr: string | null = null;
      if (booking.event_id) {
        const evRes = await fetch(
          `${SUPABASE_URL}/rest/v1/events?id=eq.${booking.event_id}&select=title_en,title_ar&limit=1`,
          { headers: { ...svc, "Accept-Profile": "content" } },
        );
        const ev = await evRes.json().catch(() => []) as Array<{ title_en?: string; title_ar?: string }>;
        placeNameEn = ev[0]?.title_en ?? null;
        placeNameAr = ev[0]?.title_ar ?? ev[0]?.title_en ?? null;
      } else if (booking.place_id) {
        const plRes = await fetch(
          `${SUPABASE_URL}/rest/v1/places?id=eq.${booking.place_id}&select=name_en,name_ar&limit=1`,
          { headers: { ...svc, "Accept-Profile": "content" } },
        );
        const pl = await plRes.json().catch(() => []) as Array<{ name_en?: string; name_ar?: string }>;
        placeNameEn = pl[0]?.name_en ?? null;
        placeNameAr = pl[0]?.name_ar ?? pl[0]?.name_en ?? null;
      }
      copyEn = getRefundCopy(placeNameEn, booking.amount_iqd, booking.category, "en");
      copyAr = getRefundCopy(placeNameAr, booking.amount_iqd, booking.category, "ar");
      kind = "booking_refund";
    } else {
      copyEn = getCopy(booking.category, new_status, "en");
      copyAr = getCopy(booking.category, new_status, "ar");
      kind = `booking_${new_status}`;
    }

    if (!copyEn || !copyAr) {
      return json({ skipped: true, reason: "no copy for this status" }, 200);
    }

    // ── Persist to the in-app notification center ─────────────────────────
    // profiles.user_notifications backs the app's inbox. Deduped on
    // (user_id, kind, data.<id>) so a re-fired trigger or a belt-and-suspenders
    // caller (e.g. booking-wayl-webhook) doesn't create duplicate inbox rows.
    // Written regardless of push tokens so the entry survives even when the user
    // has no registered device.
    const idKey = isMembership ? "membership_id" : "booking_id";
    const dupRes = await fetch(
      `${SUPABASE_URL}/rest/v1/user_notifications?user_id=eq.${booking.user_id}` +
        `&kind=eq.${kind}&data->>${idKey}=eq.${booking.id}&select=id&limit=1`,
      { headers: { ...svc, "Accept-Profile": "profiles" } },
    );
    const dupRows = dupRes.ok ? await dupRes.json().catch(() => []) as unknown[] : [];
    let inboxInserted = false;
    if (!Array.isArray(dupRows) || dupRows.length === 0) {
      const insRes = await fetch(`${SUPABASE_URL}/rest/v1/user_notifications`, {
        method: "POST",
        headers: {
          ...svc, "Accept-Profile": "profiles", "Content-Profile": "profiles",
          Prefer: "return=minimal",
        },
        body: JSON.stringify({
          user_id: booking.user_id,
          kind,
          title_en: copyEn.title,
          title_ar: copyAr.title,
          body_en: copyEn.body,
          body_ar: copyAr.body,
          data: { [idKey]: booking.id },
        }),
      });
      inboxInserted = insRes.ok;
      if (!insRes.ok) {
        console.error(
          `booking-notification: inbox insert failed ${insRes.status} ${await insRes.text().catch(() => "")}`,
        );
      }
    }

    // ── Fetch user FCM tokens (multi-device) ──────────────────────────────
    // Tokens live in profiles.user_fcm_tokens (written by the save_fcm_token
    // RPC). The legacy app_users.fcm_token column is no longer populated.
    const tokRes = await fetch(
      `${SUPABASE_URL}/rest/v1/user_fcm_tokens?user_id=eq.${booking.user_id}` +
        `&select=token,locale,updated_at&order=updated_at.desc`,
      { headers: { ...svc, "Accept-Profile": "profiles" } },
    );
    const tokenRows = await tokRes.json().catch(() => []) as Array<{
      token: string; locale: string | null; updated_at: string;
    }>;

    if (!Array.isArray(tokenRows) || !tokenRows.length) {
      console.warn(`booking-notification: no FCM token for user ${booking.user_id}`);
      return json({ success: true, inbox: inboxInserted, sent: 0, reason: "no fcm token" }, 200);
    }

    // ── Send via FCM HTTP v1 (each device in its own language) ────────────
    const sa = parseServiceAccount(FCM_SA_B64);
    const accessToken = await getFcmAccessToken(sa);
    const projectId = sa.project_id;

    let sent = 0;
    const staleTokens: string[] = [];
    for (const { token, locale } of tokenRows) {
      const copy = locale === "en" ? copyEn : copyAr;
      const fcmRes = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: copy.title, body: copy.body },
              data: {
                [idKey]: booking.id,
                kind,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
              android: { priority: "high", notification: { sound: "default" } },
              apns: { payload: { aps: { sound: "default", "content-available": 1, badge: 1 } } },
            },
          }),
        },
      );

      if (fcmRes.ok) {
        sent++;
        continue;
      }
      // FCM returns 404/UNREGISTERED for stale tokens — prune them, keep going.
      if (fcmRes.status === 404) {
        staleTokens.push(token);
        continue;
      }
      const err = await fcmRes.json().catch(() => ({}));
      console.error(
        `booking-notification: FCM error ${fcmRes.status} user=${booking.user_id}: ${JSON.stringify(err)}`,
      );
    }

    // Best-effort cleanup of dead tokens so the table doesn't accumulate them.
    for (const token of staleTokens) {
      await fetch(
        `${SUPABASE_URL}/rest/v1/user_fcm_tokens?token=eq.${encodeURIComponent(token)}`,
        { method: "DELETE", headers: { ...svc, "Accept-Profile": "profiles", "Content-Profile": "profiles" } },
      ).catch(() => {});
    }

    console.log(
      `booking-notification: user=${booking.user_id} kind=${kind} ` +
        `inbox=${inboxInserted} sent=${sent}/${tokenRows.length} stale=${staleTokens.length}`,
    );

    return json({ success: true, inbox: inboxInserted, sent, stale: staleTokens.length }, 200);

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Internal server error";
    console.error("booking-notification error:", msg);
    return json({ error: msg }, 500);
  }
});

// ── Firebase service account → OAuth2 access token ───────────────────────────
//
// Firebase HTTP v1 API requires a short-lived OAuth2 token, not the legacy
// server key. We sign a JWT with the service account's private key and exchange
// it at Google's token endpoint.

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

/**
 * The FIREBASE_SERVICE_ACCOUNT secret may be stored as either base64-encoded JSON
 * (older convention) or the raw JSON string. Accept both so a mis-set secret
 * doesn't silently break every push.
 */
function parseServiceAccount(raw: string): ServiceAccount {
  const trimmed = raw.trim();
  const json = trimmed.startsWith("{") ? trimmed : atob(trimmed.replace(/\s+/g, ""));
  return JSON.parse(json) as ServiceAccount;
}

async function getFcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    sub: sa.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");

  const unsignedJwt = `${encode(header)}.${encode(payload)}`;

  // Import the RSA private key
  const pemBody = sa.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const keyDer = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sigBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedJwt),
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBuffer)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const signedJwt = `${unsignedJwt}.${sig}`;

  // Exchange JWT for access token
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signedJwt,
    }),
  });

  if (!tokenRes.ok) {
    const err = await tokenRes.text();
    throw new Error(`Google token exchange failed: ${err}`);
  }

  const tokenJson = await tokenRes.json() as { access_token: string };
  return tokenJson.access_token;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function serviceHeaders(serviceKey: string): Record<string, string> {
  return {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    "Content-Type": "application/json",
    Prefer: "return=representation",
  };
}
```

- [x] **Step 2: Diff against the live source to confirm the change is scoped correctly**

Re-fetch the currently-deployed source and compare mentally against the file just written — the only differences should be: the new `HOURLY_CATEGORIES` array, the new `bookAgainCta()` function, the `cancelled` branch of `getCopy()` using it, `getRefundCopy()` gaining the `category` parameter and using it, and the one call site passing `booking.category` through.

```
mcp__plugin_supabase_supabase__get_edge_function
  project_id: qvozjwlkzordudkhamcu
  function_slug: booking-notification
```

Expected: everything outside the areas listed above is byte-for-byte identical to Step 1's file (confirms no accidental behavior change to confirmation/expiry copy, dedup logic, FCM sending, or token pruning).

- [x] **Step 3: Deploy the updated function**

Call `mcp__plugin_supabase_supabase__deploy_edge_function` with:
- `project_id`: `qvozjwlkzordudkhamcu`
- `name`: `booking-notification`
- `entrypoint_path`: `supabase/functions/booking-notification/index.ts` (matches the path convention already live for `process-notifications`, the one other function tracked in this repo — confirmed via `list_edge_functions`, whose `entrypoint_path` for `process-notifications` is `.../source/supabase/functions/process-notifications/index.ts`)
- `verify_jwt`: `false` (must explicitly match the function's current live setting — confirmed via `list_edge_functions`: `booking-notification` has `"verify_jwt":false`, since it's invoked by a DB trigger via `pg_net` and by `booking-wayl-webhook` using the anon key, neither of which carries a user JWT; flipping this to `true` would break both callers)
- `files`: a single entry, `{ "name": "supabase/functions/booking-notification/index.ts", "content": <the full text from Step 1> }`

- [x] **Step 4: Verify the deployed source contains the new copy**

```
mcp__plugin_supabase_supabase__get_edge_function
  project_id: qvozjwlkzordudkhamcu
  function_slug: booking-notification
```

Expected: the returned source contains `"Book another hour!"`, `"Book another day!"`, `"احجز ساعة أخرى!"`, `"احجز يومًا آخر!"`, and `getRefundCopy(placeNameEn, booking.amount_iqd, booking.category, "en")`.

- [x] **Step 5: Confirm the category taxonomy matches the live enum**

This was checked during design against a local migration file, which turned out to be stale — re-confirm against the live enum directly, so `HOURLY_CATEGORIES` doesn't miss a real category:

```
mcp__plugin_supabase_supabase__execute_sql
  project_id: qvozjwlkzordudkhamcu
  query: SELECT unnest(enum_range(NULL::bookings.booking_category))::text AS category;
```

Expected: exactly `padel`, `football`, `farm`, `concert`, `restaurant` — five rows, matching what `HOURLY_CATEGORIES` and the `getCopy`/`bookAgainCta` logic assume. If a new category has been added since, add it to `HOURLY_CATEGORIES` (if hourly) — the day-based wording is already the default for anything not in that list, so a new date-based category needs no code change.

> **Execution note (2026-08-07):** Step 5 caught a real discrepancy. The live
> result was actually `sports`, `farm`, `concert`, `restaurant` — four rows,
> not five. `padel`/`football` had already been merged into a single
> `sports` value at the **database enum level itself** (a separate,
> app-wide migration unifying court-sports categories — confirmed via
> `supabase/migrations/20260505000002_create_court_booking_unified.sql`
> and `lib/features/booking/domain/models/booking_enums.dart`'s own
> `case 'sports': return BookingCategory.hourly;`), not merely in the
> display-layer `content.places.booking_category` taxonomy the design spec
> already knew about. The Step 1 code above has been corrected in place to
> `HOURLY_CATEGORIES = ["sports"]` to match — this is what was actually
> written, deployed (v32), and committed. The original Step 1 draft used
> `["padel", "football"]`; that version was live for one deploy (v31) before
> being caught by task review and fixed in commit `947c11f`.

- [x] **Step 6: Commit**

```bash
git add supabase/functions/booking-notification/index.ts
git commit -m "feat(notifications): add category-aware 'book again' CTA to cancellation copy"
```

Executed as two commits: `1314df2` (initial, stale taxonomy) and `947c11f`
(fix: `HOURLY_CATEGORIES` corrected to `["sports"]` per the Step 5 note
above).

# Cash Payment — Backend (Supabase) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a booking or membership be created with `payment_method: "cash"` instead of Wayl e-payment — confirmed immediately, no gateway link, tracked separately for reporting.

**Architecture:** Add `payment_method` to `bookings`/`memberships` and `cash_enabled` to `merchants`. `create-booking` and `create-membership` grow a cash branch that mirrors the existing free/dashboard-booking branch (immediate confirm, no Wayl call). `booking-action`'s cancel path and `get-transactions` both need small changes so cash rows behave correctly downstream. `content.places_mobile` and `content.events_mobile` both expose `cash_enabled` so the mobile app knows whether to offer Cash for place bookings and for concert/GA tickets respectively.

**Tech Stack:** Supabase Postgres (migrations via `apply_migration`), Deno edge functions (deployed via `deploy_edge_function`), PostgREST.

**Project ID:** `qvozjwlkzordudkhamcu` (all `mcp__plugin_supabase_supabase__*` calls use this).

## Global Constraints

- This project's live schema has drifted from the local `supabase/migrations/` tree (several columns like `dashboard_payment_required`, `guest_name`, `wayl_code` exist live but were never captured in a local migration file). Do not trust local migration files as ground truth — verify against live schema (via `execute_sql` on `information_schema`/`pg_constraint`/`pg_get_functiondef`) before writing any migration that touches an existing table/function.
- Several edge functions referenced here (`create-membership`, `get-transactions`, `booking-action`) have **no local source file** — only a live deployed version. Pull current source with `mcp__plugin_supabase_supabase__get_edge_function` before editing, edit it, then write the result to a local file under `supabase/functions/<slug>/index.ts` (creating the directory) before deploying — this brings the function under version control as a side effect, which is an improvement worth keeping.
- Deploy edge functions with `mcp__plugin_supabase_supabase__deploy_edge_function`, not the Supabase CLI (no local CLI link is assumed).
- Apply schema changes with `mcp__plugin_supabase_supabase__apply_migration`, which both records a migration file and applies it live — use this instead of raw `execute_sql` for anything DDL.
- IQD amounts are always whole integers; no currency conversion in this feature.

---

### Task 1: Schema — `payment_method` + `cash_enabled` columns, and expose cash_enabled to mobile

**Files:**
- Create (via `apply_migration`, which writes it into `supabase/migrations/`): a migration named `add_cash_payment_method`
- Modify (via `apply_migration`): `content.places_mobile` and `content.events_mobile` view definitions

**Interfaces:**
- Produces: `bookings.bookings.payment_method` (`text`, `'wayl'|'cash'`, default `'wayl'`), `bookings.memberships.payment_method` (same), `business.merchants.cash_enabled` (`boolean`, default `true`), `content.places_mobile.cash_enabled` and `content.events_mobile.cash_enabled` (`boolean`, nullable — LEFT JOIN can produce null for a place/event with no merchant row).

- [ ] **Step 1: Verify current constraints and view, live**

Run via `mcp__plugin_supabase_supabase__execute_sql` (project `qvozjwlkzordudkhamcu`):

```sql
select conname, pg_get_constraintdef(oid) from pg_constraint
where conrelid = 'bookings.bookings'::regclass and contype = 'c';

select column_name from information_schema.columns
where table_schema = 'business' and table_name = 'merchants' and column_name = 'cash_enabled';
```

Expected: no `cash_enabled` column yet (query returns 0 rows); `bookings_payment_status_check` already allows `pending, paid, failed, free, refunded, cancelled` (confirmed as of this plan's writing — reconfirm in case it changed).

- [ ] **Step 2: Apply the migration**

Call `mcp__plugin_supabase_supabase__apply_migration` with `project_id: "qvozjwlkzordudkhamcu"`, `name: "add_cash_payment_method"`, and this SQL:

```sql
ALTER TABLE bookings.bookings
  ADD COLUMN payment_method text NOT NULL DEFAULT 'wayl'
    CHECK (payment_method IN ('wayl', 'cash'));

ALTER TABLE bookings.memberships
  ADD COLUMN payment_method text NOT NULL DEFAULT 'wayl'
    CHECK (payment_method IN ('wayl', 'cash'));

ALTER TABLE business.merchants
  ADD COLUMN cash_enabled boolean NOT NULL DEFAULT true;

CREATE OR REPLACE VIEW content.places_mobile AS
 SELECT p.id,
    p.merchant_id,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'category_id'::text)::uuid
            ELSE p.category_id
        END AS category_id,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'name_ar'::text
            ELSE p.name_ar
        END AS name_ar,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'name_en'::text
            ELSE p.name_en
        END AS name_en,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'description_ar'::text
            ELSE p.description_ar
        END AS description_ar,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'description_en'::text
            ELSE p.description_en
        END AS description_en,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'city'::text
            ELSE p.city
        END AS city,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'area'::text
            ELSE p.area
        END AS area,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'address_text'::text
            ELSE p.address_text
        END AS address_text,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'latitude'::text)::double precision
            ELSE p.latitude
        END AS latitude,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'longitude'::text)::double precision
            ELSE p.longitude
        END AS longitude,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'cover_image_url'::text
            ELSE p.cover_image_url
        END AS cover_image_url,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'is_new'::text)::boolean
            ELSE p.is_new
        END AS is_new,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'is_trending'::text)::boolean
            ELSE p.is_trending
        END AS is_trending,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'is_verified'::text)::boolean
            ELSE p.is_verified
        END AS is_verified,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN (p.approved_snapshot ->> 'is_featured'::text)::boolean
            ELSE p.is_featured
        END AS is_featured,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot -> 'opening_hours'::text
            ELSE p.opening_hours
        END AS opening_hours,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'phone'::text
            ELSE p.phone
        END AS phone,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'instagram_url'::text
            ELSE p.instagram_url
        END AS instagram_url,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'website_url'::text
            ELSE p.website_url
        END AS website_url,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot -> 'additional_images'::text
            ELSE p.additional_images
        END AS additional_images,
    p.view_count,
    p.saves_count,
    p.reviews_count,
    p.shares_count,
    p.checkins_count,
    p.hotness_score,
    p.created_at,
    p.updated_at,
    'approved'::text AS place_status,
    m.logo_url,
    p.booking_category,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'city_ar'::text
            ELSE p.city_ar
        END AS city_ar,
        CASE
            WHEN p.place_status <> 'approved'::text AND p.approved_snapshot IS NOT NULL THEN p.approved_snapshot ->> 'area_ar'::text
            ELSE p.area_ar
        END AS area_ar,
    m.cash_enabled
   FROM content.places p
     LEFT JOIN business.merchants m ON m.id = p.merchant_id
  WHERE p.place_status = 'approved'::text OR p.place_status = 'pending_review'::text AND p.approved_snapshot IS NOT NULL;

CREATE OR REPLACE VIEW content.events_mobile AS
 SELECT e.id,
    e.place_id,
    e.merchant_id,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'title_ar'::text
            ELSE e.title_ar
        END AS title_ar,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'title_en'::text
            ELSE e.title_en
        END AS title_en,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'description_ar'::text
            ELSE e.description_ar
        END AS description_ar,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'description_en'::text
            ELSE e.description_en
        END AS description_en,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'cover_image_url'::text
            ELSE e.cover_image_url
        END AS cover_image_url,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'start_date'::text)::timestamp with time zone
            ELSE e.start_date
        END AS start_date,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'end_date'::text)::timestamp with time zone
            ELSE e.end_date
        END AS end_date,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'ticket_price'::text)::numeric
            ELSE e.ticket_price
        END AS ticket_price,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'ticket_url'::text
            ELSE e.ticket_url
        END AS ticket_url,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'city'::text
            ELSE e.city
        END AS city,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'is_featured'::text)::boolean
            ELSE e.is_featured
        END AS is_featured,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'latitude'::text)::double precision
            ELSE e.latitude
        END AS latitude,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN (e.approved_snapshot ->> 'longitude'::text)::double precision
            ELSE e.longitude
        END AS longitude,
    e.view_count,
    e.saves_count,
    e.reviews_count,
    e.shares_count,
    e.checkins_count,
    e.hotness_score,
    e.created_at,
    e.updated_at,
    'approved'::text AS event_status,
    m.logo_url,
    COALESCE(m.is_verified, false) AS is_verified,
    e.bookings_count,
        CASE
            WHEN e.event_status <> 'approved'::text AND e.approved_snapshot IS NOT NULL THEN e.approved_snapshot ->> 'city_ar'::text
            ELSE e.city_ar
        END AS city_ar,
    m.cash_enabled
   FROM content.events e
     LEFT JOIN business.merchants m ON m.id = e.merchant_id
  WHERE e.event_status = 'approved'::text OR e.event_status = 'pending_review'::text AND e.approved_snapshot IS NOT NULL;
```

In both views, only the final `m.cash_enabled` line is new — every other line is reproduced verbatim from each view's live definition (Postgres requires the full `CREATE OR REPLACE VIEW` body; it forbids removing or reordering existing output columns, so the new one must be appended last).

- [ ] **Step 2: Verify**

```sql
select payment_method from bookings.bookings limit 1;
select payment_method from bookings.memberships limit 1;
select cash_enabled from business.merchants limit 1;
select cash_enabled from content.places_mobile limit 1;
select cash_enabled from content.events_mobile limit 1;
```

All five should succeed with `cash_enabled`/`payment_method` populated (`true`/`'wayl'` on existing rows via the defaults).

- [ ] **Step 3: Commit the migration file**

`apply_migration` already wrote the file into `supabase/migrations/`. Confirm it exists and commit it:

```bash
git status supabase/migrations/
git add supabase/migrations/*add_cash_payment_method*.sql
git commit -m "feat(db): add payment_method to bookings/memberships and cash_enabled to merchants"
```

---

### Task 2: `create-booking` — cash branch

**Files:**
- Create locally (source pulled from live in Step 1): `supabase/functions/create-booking/index.ts` — this file already exists locally; modify it directly.

**Interfaces:**
- Consumes: `payment_method?: "wayl" | "cash"` on the request body (new, optional field on `BookingPayload`'s base).
- Produces: response shape unchanged for the Wayl path; for the new cash path, `{ booking_id?, group_id?, cash: true, amount_iqd, source }` (no `payment_url`, no `hold_until`, no `reference_id`).

- [ ] **Step 1: Add `payment_method` to the request type**

In `supabase/functions/create-booking/index.ts`, modify the `BasePaylod` interface (around line 37):

```ts
interface BasePaylod {
  category: BookingCategory;
  redirect_url?: string;
  promo_code?: string;
  guest_name?: string; // dashboard: name the booking is held under
  client?: "dashboard"; // dashboard-only hint; narrows `source` (see below)
  payment_method?: "wayl" | "cash"; // customer's choice; default "wayl"
}
```

- [ ] **Step 2: Look up `cash_enabled` and branch before the Wayl link is created**

Insert a new branch immediately after the existing free-path block (after line 335, `}` closing the `if (isDashboardBooking && ...)` block, and before the `// ── Create Wayl payment link ──` comment at line 337):

```ts
    // ── Cash path: customer pays the merchant in person ─────────────────────
    if (body.payment_method === "cash") {
      if (!(await cashEnabled(SUPABASE_URL, svc, ctx.merchantId))) {
        // Roll back the pending row(s) — same cleanup as the promo-rejected path.
        if (isGroup) {
          await fetch(
            `${SUPABASE_URL}/rest/v1/bookings?group_id=eq.${rpcResult.group_id}`,
            { method: "DELETE", headers: { ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings" } },
          );
        } else {
          await fetch(
            `${SUPABASE_URL}/rest/v1/bookings?id=eq.${rpcResult.id}`,
            { method: "DELETE", headers: { ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings" } },
          );
        }
        return json({ error: "cash_disabled" }, 400);
      }
      const cashFilter = isGroup ? `group_id=eq.${rpcResult.group_id}` : `id=eq.${rpcResult.id}`;
      const cashPatch = isGroup
        ? {
            status: "confirmed", payment_status: "paid", payment_method: "cash",
            hold_until: null, source, guest_name: body.guest_name ?? null,
          }
        : {
            status:               "confirmed",
            payment_status:       "paid",
            payment_method:       "cash",
            hold_until:           null,
            amount_iqd:           finalIqd,
            original_amount_iqd:  subtotalIqd,
            discount_amount_iqd:  discountAmount,
            discount_source:      discountSource,
            promo_code:           discountSource === "promo" ? promoCode : null,
            promo_code_id:        promoCodeId,
            auto_discount_id:     autoDiscountId,
            merchant_discount_id: merchantDiscountId,
            source,
            guest_name:           body.guest_name ?? null,
          };
      await fetch(`${SUPABASE_URL}/rest/v1/bookings?${cashFilter}`, {
        method: "PATCH",
        headers: { ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings" },
        body: JSON.stringify(cashPatch),
      });
      return json({
        booking_id: !isGroup ? rpcResult.id : undefined,
        group_id:   isGroup  ? rpcResult.group_id : undefined,
        cash:       true,
        amount_iqd: finalIqd,
        source,
      }, 200);
    }

```

- [ ] **Step 3: Add the `cashEnabled` helper**

Add this function next to `dashboardPaymentRequired` (after line 954):

```ts
/** Whether the merchant accepts cash payment for bookings. */
async function cashEnabled(
  supabaseUrl: string,
  svc: Record<string, string>,
  merchantId: string | null,
): Promise<boolean> {
  if (!merchantId) return false; // safe default: no merchant to hand cash to
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/merchants?id=eq.${merchantId}&select=cash_enabled`,
      { headers: { ...svc, "Accept-Profile": "business" } },
    );
    if (res.ok) {
      const [row] = await res.json() as { cash_enabled: boolean | null }[];
      if (row && row.cash_enabled === false) return false;
    }
  } catch { /* default true */ }
  return true;
}
```

- [ ] **Step 4: Deploy and verify**

Call `mcp__plugin_supabase_supabase__deploy_edge_function` with `project_id: "qvozjwlkzordudkhamcu"`, `slug: "create-booking"`, the updated file content.

Verify with a live curl (replace `$JWT` with a real mobile-app user's access token and use a real `place_id`/`court_id` for an hourly place with `cash_enabled = true`):

```bash
curl -sS -X POST "https://qvozjwlkzordudkhamcu.supabase.co/functions/v1/create-booking" \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d '{"category":"hourly","place_id":"<place>","court_id":"<court>","starts_at":"<iso>","hours":1,"payment_method":"cash"}'
```

Expected: `200` with `{"booking_id": "...", "cash": true, "amount_iqd": <n>, "source": "mobile_app"}`, no `payment_url` key. Then:

```sql
select status, payment_status, payment_method, hold_until from bookings.bookings where id = '<booking_id>';
```

Expected: `confirmed | paid | cash | NULL`. Wait 90 seconds and re-check — the row must still be `confirmed` (the `bookings_expire_holds` cron only touches `status = 'pending'`, so this booking must never have been at risk).

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/create-booking/index.ts
git commit -m "feat(create-booking): add cash payment method, confirmed immediately"
```

---

### Task 3: `create-membership` — cash branch (mirrors Task 2)

**Files:**
- Create: `supabase/functions/create-membership/index.ts` (pulled live via `get_edge_function` in Task 1 — this is the first time this function is captured locally).

**Interfaces:**
- Consumes: `payment_method?: "wayl" | "cash"` on the request body.
- Produces: for cash, `{ membership_id, cash: true, amount_iqd, source }` (no `payment_url`).

- [ ] **Step 1: Save the pulled source locally**

Write the content retrieved via `get_edge_function(project_id: "qvozjwlkzordudkhamcu", function_slug: "create-membership")` to `supabase/functions/create-membership/index.ts` (create the directory).

- [ ] **Step 2: Add `payment_method` to the request body type**

Modify the inline body type (currently):

```ts
    const body = await req.json() as {
      place_id?: string;
      plan_id?: string;
      redirect_url?: string;
      force?: boolean;
      promo_code?: string;
      guest_name?: string;
      client?: "dashboard";
    };
```

to:

```ts
    const body = await req.json() as {
      place_id?: string;
      plan_id?: string;
      redirect_url?: string;
      force?: boolean;
      promo_code?: string;
      guest_name?: string;
      client?: "dashboard";
      payment_method?: "wayl" | "cash";
    };
```

- [ ] **Step 3: Insert the cash branch**

Insert immediately after the existing free-path block closes (after the `return json({ membership_id: membershipId, free: true, ... }, 200); }` block) and before `// ── Create Wayl payment link for the FINAL amount ──`:

```ts
    // ── Cash path: customer pays the merchant in person ─────────────────────
    if (body.payment_method === "cash") {
      if (!(await cashEnabled(SUPABASE_URL, svc, merchantId))) {
        await fetch(
          `${SUPABASE_URL}/rest/v1/memberships?id=eq.${membershipId}`,
          { method: "DELETE", headers: { ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings" } },
        );
        return json({ error: "cash_disabled" }, 400);
      }
      await fetch(`${SUPABASE_URL}/rest/v1/memberships?id=eq.${membershipId}`, {
        method: "PATCH",
        headers: { ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings" },
        body: JSON.stringify({
          status:              "active",
          payment_status:      "paid",
          payment_method:      "cash",
          amount_iqd:          finalIqd,
          original_amount_iqd: subtotalIqd,
          discount_amount_iqd: discountAmount,
          discount_source:     discountSource,
          promo_code:          discountSource === "promo" ? promoCode : null,
          promo_code_id:       promoCodeId,
          auto_discount_id:    autoDiscountId,
          source,
          guest_name:          body.guest_name ?? null,
        }),
      });
      return json({ membership_id: membershipId, cash: true, amount_iqd: finalIqd, source }, 200);
    }

```

- [ ] **Step 4: Add the `cashEnabled` helper**

Add next to `dashboardPaymentRequired` in this file (identical body to Task 2's helper — this file doesn't share code with `create-booking`, each edge function is an isolated Deno module):

```ts
/** Whether the merchant accepts cash payment for memberships. */
async function cashEnabled(
  supabaseUrl: string,
  svc: Record<string, string>,
  merchantId: string | null,
): Promise<boolean> {
  if (!merchantId) return false;
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/merchants?id=eq.${merchantId}&select=cash_enabled`,
      { headers: { ...svc, "Accept-Profile": "business" } },
    );
    if (res.ok) {
      const [row] = await res.json() as { cash_enabled: boolean | null }[];
      if (row && row.cash_enabled === false) return false;
    }
  } catch { /* default true */ }
  return true;
}
```

- [ ] **Step 5: Deploy and verify**

Deploy via `mcp__plugin_supabase_supabase__deploy_edge_function` (`slug: "create-membership"`). Curl with a real `place_id`/`plan_id`:

```bash
curl -sS -X POST "https://qvozjwlkzordudkhamcu.supabase.co/functions/v1/create-membership" \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d '{"place_id":"<place>","plan_id":"<plan>","payment_method":"cash"}'
```

Expected: `200` with `{"membership_id": "...", "cash": true, ...}`. Then:

```sql
select status, payment_status, payment_method from bookings.memberships where id = '<membership_id>';
```

Expected: `active | paid | cash`.

- [ ] **Step 6: Commit**

```bash
git add supabase/functions/create-membership/index.ts
git commit -m "feat(create-membership): add cash payment method, activated immediately"
```

---

### Task 4: `booking-action` — cash bookings must plain-cancel, not Wayl-refund

**Files:**
- Create locally (pulled live): `supabase/functions/booking-action/index.ts`, `supabase/functions/_shared/wayl.ts`, `supabase/functions/booking-action/refund.ts`

**Why this task exists:** cash bookings are stored with `payment_status = 'paid'` (so they count correctly in revenue totals) but have no `payment_id` (no Wayl link was ever created). `booking-action`'s cancel logic currently branches purely on `payment_status === "paid"` and tries to refund at Wayl using `payment_id` as the reference — for a cash booking that reference is `null`, so cancelling one today would hit `"No refundable payment found"` and fail outright. This task adds the one condition needed to route cash bookings to the plain-cancel branch instead.

**Interfaces:**
- No change to the function's external contract (`{ id, action, is_membership? }` in, `{ success, status }` out) — internal branching only.

- [ ] **Step 1: Save the pulled source locally**

Write `functions/booking-action/index.ts`, `functions/_shared/wayl.ts`, `functions/booking-action/refund.ts` (from `get_edge_function(function_slug: "booking-action")`) to `supabase/functions/booking-action/index.ts`, `supabase/functions/_shared/wayl.ts`, `supabase/functions/booking-action/refund.ts` respectively.

- [ ] **Step 2: Fetch `payment_method` alongside the other row fields**

In `supabase/functions/booking-action/index.ts`, modify the row lookup query (currently `select=id,merchant_id,status,payment_status,paid_at,group_id,payment_id,amount_iqd`):

```ts
    const rowRes = await fetch(
      `${SUPABASE_URL}/rest/v1/${table}?id=eq.${id}&select=id,merchant_id,status,payment_status,paid_at,group_id,payment_id,amount_iqd,payment_method&limit=1`,
      { headers: { ...svc, "Accept-Profile": "bookings" } },
    );
```

and its type annotation:

```ts
    const rows = await rowRes.json() as Array<{
      id: string; merchant_id: string | null; status: string; payment_status: string | null;
      paid_at: string | null; group_id: string | null;
      payment_id: string | null; amount_iqd: number | null; payment_method: string | null;
    }>;
```

- [ ] **Step 3: Exclude cash from the refund branch**

Change:

```ts
    if (row.payment_status === "paid") {
      // Paid → refund at Wayl then cancel, within the 60-minute window.
```

to:

```ts
    if (row.payment_status === "paid" && row.payment_method !== "cash") {
      // Paid → refund at Wayl then cancel, within the 60-minute window.
```

The existing final fallback (`// Free / unpaid → plain cancel`) already handles everything that isn't `refunded` or `(paid && not cash)` — a cash booking now falls through to it unchanged, setting `status: "cancelled", payment_status: "cancelled"`. No other edit needed in this function.

- [ ] **Step 4: Deploy and verify**

Deploy via `deploy_edge_function` (`slug: "booking-action"`). Using a cash booking id created in Task 2's verification:

```bash
curl -sS -X POST "https://qvozjwlkzordudkhamcu.supabase.co/functions/v1/booking-action" \
  -H "Authorization: Bearer $STAFF_JWT" -H "Content-Type: application/json" \
  -d '{"id":"<cash_booking_id>","action":"cancel"}'
```

Expected: `200 {"success": true, "status": "cancelled"}` — not a 409 "No refundable payment found". Then confirm a Wayl-paid booking still refunds normally (existing behavior unchanged) by repeating against any `payment_status = 'paid'` row with `payment_method = 'wayl'` and a real `payment_id` you're OK refunding in test, or by code review alone if no safe test row exists — the diff is a single added `&&` clause and is easy to verify by inspection if a live refund test isn't practical.

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/booking-action/index.ts supabase/functions/_shared/wayl.ts supabase/functions/booking-action/refund.ts
git commit -m "fix(booking-action): cash bookings cancel directly instead of attempting a Wayl refund"
```

---

### Task 5: `get-transactions` — surface cash as its own `paymentMethod`

**Files:**
- Create locally (pulled live): `supabase/functions/get-transactions/index.ts`

**Why this task exists:** this function already synthesizes transaction-feed rows directly from `bookings`/`memberships` (not just gateway webhook logs) — `bookingLogs`/`membershipLogs` in the existing code. Cash bookings already pass its `payment_status=in.(paid,refunded,free)` filter (cash is `paid`) and will already appear in the feed once fetched — the only gap is that `paymentMethod` is currently computed as `isFree ? "—" : hp ? "HyperPay" : "Wayl"`, which would mislabel a cash row as `"Wayl"`. This task fixes just that label so the dashboard can tell them apart.

**Interfaces:**
- Produces: `body.paymentMethod` is now `"Cash"` for rows where the underlying booking/membership has `payment_method = 'cash'`, in addition to the existing `"Wayl"`/`"HyperPay"`/`"—"` values.

- [ ] **Step 1: Save the pulled source locally**

Write the content from `get_edge_function(function_slug: "get-transactions")` to `supabase/functions/get-transactions/index.ts`.

- [ ] **Step 2: Include `payment_method` in the bookings/memberships select lists**

Change the two `fetchAllRows` calls (currently):

```ts
      fetchAllRows(
        `${SUPABASE_URL}/rest/v1/bookings?payment_status=in.(paid,refunded,free)&select=id,created_at,user_id,category,amount_iqd,payment_id,wayl_code,payment_status,place_id,commission_pct,source&order=created_at.desc`,
        bookingsHeaders
      ),
      fetchAllRows(
        `${SUPABASE_URL}/rest/v1/memberships?payment_status=in.(paid,refunded,free)&select=id,created_at,user_id,merchant_id,amount_iqd,payment_id,wayl_code,payment_status,commission_pct,source&order=created_at.desc`,
        bookingsHeaders
      ),
```

to:

```ts
      fetchAllRows(
        `${SUPABASE_URL}/rest/v1/bookings?payment_status=in.(paid,refunded,free)&select=id,created_at,user_id,category,amount_iqd,payment_id,wayl_code,payment_status,payment_method,place_id,commission_pct,source&order=created_at.desc`,
        bookingsHeaders
      ),
      fetchAllRows(
        `${SUPABASE_URL}/rest/v1/memberships?payment_status=in.(paid,refunded,free)&select=id,created_at,user_id,merchant_id,amount_iqd,payment_id,wayl_code,payment_status,payment_method,commission_pct,source&order=created_at.desc`,
        bookingsHeaders
      ),
```

- [ ] **Step 3: Use `payment_method` in the label logic**

In `bookingLogs` construction, change:

```ts
        paymentMethod: isFree ? "—" : hp ? "HyperPay" : "Wayl",
```

to:

```ts
        paymentMethod: isFree ? "—" : b.payment_method === "cash" ? "Cash" : hp ? "HyperPay" : "Wayl",
```

Make the identical change in `membershipLogs` construction (same line pattern, using `m.payment_method` — the mapped variable there is `m`, not `b`):

```ts
        paymentMethod: isFree ? "—" : m.payment_method === "cash" ? "Cash" : hp ? "HyperPay" : "Wayl",
```

- [ ] **Step 4: Deploy and verify**

Deploy via `deploy_edge_function` (`slug: "get-transactions"`). Curl as an admin:

```bash
curl -sS "https://qvozjwlkzordudkhamcu.supabase.co/functions/v1/get-transactions" \
  -H "Authorization: Bearer $ADMIN_JWT" | python3 -c "import json,sys; rows=json.load(sys.stdin); print([r for r in rows if r['body'].get('paymentMethod')=='Cash'][:2])"
```

Expected: the cash booking/membership created in Tasks 2–3's verification appears with `"paymentMethod": "Cash"`.

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/get-transactions/index.ts
git commit -m "feat(get-transactions): label cash bookings/memberships distinctly from Wayl"
```

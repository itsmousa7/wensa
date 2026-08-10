/**
 * create-membership — creates a membership record + Wayl payment link.
 *
 * Flow:
 *   1. Validate caller JWT
 *   2. Look up place context (merchant_id, category_id) and user purchase history
 *      so promo eligibility (first_purchase_at_place / new_customer) can be
 *      evaluated server-side.
 *   3. Call bookings.create_membership RPC (inserts pending row at subtotal)
 *   4. Apply discount server-side (promo OR auto), persist audit columns + final
 *      amount on the membership row.
 *   5. Create a Wayl payment link for the *final* amount.
 *   6. Persist payment reference + commission, return
 *      { membership_id, payment_url, reference_id }.
 *
 * referenceId format:
 *   membership_{membership_id}_{timestamp}
 *
 * Env vars required:
 *   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY
 *   WAYL_API_KEY, WAYL_WEBHOOK_SECRET, WAYL_WEBHOOK_URL
 *   WAYL_ENV               — "live" | "test" (default: "live")
 *   APP_DEEP_LINK_BASE     — e.g. "wansa://payment"
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const WAYL_BASE = "https://api.thewayl.com";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const SUPABASE_URL        = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_KEY         = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const WAYL_API_KEY        = Deno.env.get("WAYL_API_KEY")!;
  const WAYL_WEBHOOK_SECRET = Deno.env.get("WAYL_WEBHOOK_SECRET")!;
  const WAYL_WEBHOOK_URL    = Deno.env.get("WAYL_BOOKING_WEBHOOK_URL") ?? Deno.env.get("WAYL_WEBHOOK_URL")!;
  const APP_DEEP_LINK       = Deno.env.get("APP_DEEP_LINK_BASE") ?? "wansa://payment";
  const WAYL_ENV            = Deno.env.get("WAYL_ENV") ?? "live";

  try {
    // ── Auth ────────────────────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) return json({ error: "Missing authorization" }, 401);
    const jwt = authHeader.slice(7);

    let callerId: string;
    try {
      const b64 = jwt.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
      const payload = JSON.parse(atob(b64));
      if (!payload.sub) throw new Error("no sub");
      callerId = payload.sub;
    } catch {
      return json({ error: "Unauthorized" }, 401);
    }

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
    if (!body.place_id) return json({ error: "place_id is required" }, 400);
    if (!body.plan_id)  return json({ error: "plan_id is required" }, 400);

    const svc = serviceHeaders(SERVICE_KEY);
    const promoCode = body.promo_code?.trim().toUpperCase() || null;

    const { source: callerRole, merchantId: callerMerchantId } =
      await deriveCaller(SUPABASE_URL, svc, callerId);

    // ── Look up place context (merchant_id, category_id) ───────────────────
    let merchantId: string | null = null;
    let categoryId: string | null = null;
    try {
      const placeRes = await fetch(
        `${SUPABASE_URL}/rest/v1/places?id=eq.${body.place_id}&select=merchant_id,category_id`,
        { headers: { ...svc, "Accept-Profile": "content" } },
      );
      if (placeRes.ok) {
        const [place] = await placeRes.json() as { merchant_id: string | null; category_id: string | null }[];
        merchantId = place?.merchant_id ?? null;
        categoryId = place?.category_id ?? null;
      }
    } catch { /* best-effort */ }

    // Dashboard powers (book on behalf of a customer, free path) are limited to
    // admins and to a merchant acting on its OWN merchant. A merchant hitting
    // another merchant's place is treated as a regular paying customer.
    const hasDashboardRole = callerRole === "admin" ||
      (callerRole === "merchant" && callerMerchantId !== null && callerMerchantId === merchantId);
    // An admin/merchant account can ALSO buy through the mobile app as an ordinary
    // customer (e.g. testing their own place's membership from their phone) —
    // `hasDashboardRole` alone can't tell those apart since it's role+ownership
    // only. `client: "dashboard"` is a hint the admin/merchant dashboards'
    // CreateBookingModal sends (the mobile app never does). It is the gate for
    // EVERY dashboard-only power: the free-purchase path (payment toggle OFF) and
    // the `source` label. Without it, a merchant buying their own place's
    // membership from the MOBILE app would hit the free path when their toggle is
    // off, returning { free: true } with no payment_url — the app then errors on
    // the missing link while the membership is already created. Gating on the
    // hint keeps the toggle scoped to the dashboard; mobile always requires payment.
    const isDashboardPurchase = hasDashboardRole && body.client === "dashboard";
    const source = isDashboardPurchase ? callerRole : "mobile_app";
    // Dashboard memberships are owned by the staff caller; guest_name is the label.
    const effectiveUserId = callerId;

    // ── Purchase history (BEFORE inserting the new pending row) ────────────
    const { isFirstPurchaseAtPlace, isNewCustomer } = await fetchPurchaseHistory(
      SUPABASE_URL, svc, effectiveUserId, body.place_id,
    );

    // ── Create the pending membership row ──────────────────────────────────
    const rpcResult = await callRpc(SUPABASE_URL, jwt, "create_membership", {
      p_place_id: body.place_id,
      p_plan_id:  body.plan_id,
      p_force:    body.force ?? false,
    });

    const membershipId = rpcResult.id as string;
    const subtotalIqd  = rpcResult.amount_iqd as number;
    const ts           = Date.now();
    const referenceId  = `membership_${membershipId}_${ts}`;

    // ── Apply discount server-side ─────────────────────────────────────────
    const discount = await resolveDiscount({
      supabaseUrl:    SUPABASE_URL,
      jwt,
      svc,
      orderType:      "memberships",
      orderId:        membershipId,
      amount:         subtotalIqd,
      categoryId,
      merchantId,
      placeId:        body.place_id,
      promoCode,
      isFirstPurchaseAtPlace,
      isNewCustomer,
    });

    if (discount.kind === "promo_invalid") {
      // Clean up the pending row so the user isn't stuck with a row attached
      // to a rejected promo. amount_iqd has CHECK > 0, so deleting is simplest.
      await fetch(
        `${SUPABASE_URL}/rest/v1/memberships?id=eq.${membershipId}`,
        { method: "DELETE", headers: { ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings" } },
      );
      return json({ error: `Promo code rejected: ${discount.reason}` }, 400);
    }

    const finalIqd        = discount.finalAmount;
    const discountAmount  = discount.discountAmount;
    const discountSource  = discount.source;            // 'promo' | 'auto' | null
    const promoCodeId     = discount.promoCodeId;
    const autoDiscountId  = discount.autoDiscountId;

    // ── Free path: dashboard membership for a merchant with payment toggle OFF ──
    if (isDashboardPurchase && !(await dashboardPaymentRequired(SUPABASE_URL, svc, merchantId))) {
      await fetch(`${SUPABASE_URL}/rest/v1/memberships?id=eq.${membershipId}`, {
        method: "PATCH",
        headers: { ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings" },
        body: JSON.stringify({
          status:              "active",
          payment_status:      "free",
          commission_pct:      0,
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
      return json({ membership_id: membershipId, free: true, amount_iqd: finalIqd, source }, 200);
    }

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

    // ── Create Wayl payment link for the FINAL amount ──────────────────────
    // Carry referenceId + category to the redirect target so the post-payment
    // landing page (mobile deep link OR the dashboard confirmation page) can
    // look the membership up on a fresh page load. A caller-supplied
    // redirect_url is treated as a base; we append the params either way.
    const redirectBase = body.redirect_url ?? APP_DEEP_LINK;
    const redirectSep  = redirectBase.includes("?") ? "&" : "?";
    const redirectUrl  = `${redirectBase}${redirectSep}referenceId=${referenceId}&category=membership`;

    const waylBody = {
      env:            WAYL_ENV,
      referenceId,
      total:          finalIqd,
      currency:       "IQD",
      customParameter: membershipId,
      lineItem: [
        { label: "Gym membership", amount: finalIqd, type: "increase" },
      ],
      webhookUrl:     WAYL_WEBHOOK_URL,
      webhookSecret:  WAYL_WEBHOOK_SECRET,
      redirectionUrl: redirectUrl,
    };

    const waylRes = await fetch(`${WAYL_BASE}/api/v1/links`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-WAYL-AUTHENTICATION": WAYL_API_KEY,
      },
      body: JSON.stringify(waylBody),
    });

    if (!waylRes.ok) {
      const waylErr = await waylRes.json().catch(() => ({}));
      throw new Error(`Wayl error ${waylRes.status}: ${JSON.stringify(waylErr)}`);
    }

    const waylJson = await waylRes.json() as { data: { id: string; url: string; code?: string } };
    const paymentUrl = waylJson.data.url;
    const waylCode   = waylJson.data.code;

    // ── Look up merchant commission to snapshot onto membership ────────────
    // Priority: temp override (when current Asia/Baghdad date is in window)
    //           → merchant.commission_percentage → 12% default.
    let commissionPct: number = 12;
    if (merchantId) {
      try {
        const merchantRes = await fetch(
          `${SUPABASE_URL}/rest/v1/merchants?id=eq.${merchantId}` +
          `&select=commission_percentage,temp_commission_percentage,temp_commission_from,temp_commission_to`,
          { headers: { ...svc, "Accept-Profile": "business" } },
        );
        if (merchantRes.ok) {
          const [merchant] = await merchantRes.json() as {
            commission_percentage: number | null;
            temp_commission_percentage: number | null;
            temp_commission_from: string | null;
            temp_commission_to:   string | null;
          }[];
          commissionPct = resolveCommissionPct(merchant);
        }
      } catch { /* default 12% */ }
    }

    // ── Persist payment_id, commission, and discount audit on the row ──────
    await fetch(
      `${SUPABASE_URL}/rest/v1/memberships?id=eq.${membershipId}`,
      {
        method: "PATCH",
        headers: {
          ...svc,
          "Accept-Profile": "bookings",
          "Content-Profile": "bookings",
        },
        body: JSON.stringify({
          payment_id:          referenceId,
          commission_pct:      commissionPct,
          amount_iqd:          finalIqd,
          original_amount_iqd: subtotalIqd,
          discount_amount_iqd: discountAmount,
          discount_source:     discountSource,
          promo_code:          discountSource === "promo" ? promoCode : null,
          promo_code_id:       promoCodeId,
          auto_discount_id:    autoDiscountId,
          source,
          guest_name:          body.guest_name ?? null,
          ...(waylCode ? { wayl_code: waylCode } : {}),
        }),
      },
    );

    return json({
      membership_id: membershipId,
      payment_url:   paymentUrl,
      reference_id:  referenceId,
      amount_iqd:    finalIqd,
      original_amount_iqd: subtotalIqd,
      discount_amount_iqd: discountAmount,
    }, 200);

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Internal server error";
    console.error("create-membership error:", msg);
    return json({ error: msg }, 500);
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

interface DiscountResolved {
  kind: "ok" | "promo_invalid";
  finalAmount: number;
  discountAmount: number;
  source: "promo" | "auto" | null;
  promoCodeId: string | null;
  autoDiscountId: string | null;
  reason?: string;
}

async function resolveDiscount(args: {
  supabaseUrl: string;
  jwt: string;
  svc: Record<string, string>;
  orderType: string;
  orderId: string;
  amount: number;
  categoryId: string | null;
  merchantId: string | null;
  placeId: string;
  promoCode: string | null;
  isFirstPurchaseAtPlace: boolean;
  isNewCustomer: boolean;
}): Promise<DiscountResolved> {
  const base: DiscountResolved = {
    kind: "ok",
    finalAmount: args.amount,
    discountAmount: 0,
    source: null,
    promoCodeId: null,
    autoDiscountId: null,
  };

  if (args.amount <= 0) return base;

  // 1) Promo code (takes precedence when supplied)
  if (args.promoCode) {
    const result = await callRpcSchema(args.supabaseUrl, args.jwt, "business", "redeem_promo_code", {
      p_code:                args.promoCode,
      p_order_type:          args.orderType,
      p_amount:              args.amount,
      p_order_id:            args.orderId,
      p_category_id:         args.categoryId,
      p_merchant_id:         args.merchantId,
      p_place_id:            args.placeId,
      p_is_first_purchase_at_place: args.isFirstPurchaseAtPlace,
      p_is_new_customer:            args.isNewCustomer,
    });

    if (result && (result as { valid?: boolean }).valid) {
      const r = result as { promo_code_id: string; discount_amount: number; final_amount: number };
      return {
        kind: "ok",
        finalAmount:   Math.round(r.final_amount),
        discountAmount: Math.round(r.discount_amount),
        source: "promo",
        promoCodeId: r.promo_code_id,
        autoDiscountId: null,
      };
    }
    return {
      ...base,
      kind: "promo_invalid",
      reason: (result as { reason?: string })?.reason ?? "invalid",
    };
  }

  // 2) Auto-discount fallback
  const auto = await callRpcSchema(args.supabaseUrl, args.jwt, "business", "preview_auto_discount", {
    p_order_type:  args.orderType,
    p_amount:      args.amount,
    p_category_id: args.categoryId,
    p_merchant_id: args.merchantId,
    p_place_id:    args.placeId,
  });

  if (auto && (auto as { valid?: boolean }).valid) {
    const r = auto as { auto_discount_id: string; discount_amount: number; final_amount: number };
    return {
      kind: "ok",
      finalAmount:    Math.round(r.final_amount),
      discountAmount: Math.round(r.discount_amount),
      source: "auto",
      promoCodeId: null,
      autoDiscountId: r.auto_discount_id,
    };
  }

  return base;
}

async function fetchPurchaseHistory(
  supabaseUrl: string,
  svc: Record<string, string>,
  userId: string,
  placeId: string | null,
): Promise<{ isFirstPurchaseAtPlace: boolean; isNewCustomer: boolean }> {
  try {
    const [bRes, mRes, bPlaceRes, mPlaceRes] = await Promise.all([
      fetch(
        `${supabaseUrl}/rest/v1/bookings?user_id=eq.${userId}&select=id&limit=1`,
        { headers: { ...svc, "Accept-Profile": "bookings" } },
      ),
      fetch(
        `${supabaseUrl}/rest/v1/memberships?user_id=eq.${userId}&select=id&limit=1`,
        { headers: { ...svc, "Accept-Profile": "bookings" } },
      ),
      placeId
        ? fetch(
            `${supabaseUrl}/rest/v1/bookings?user_id=eq.${userId}&place_id=eq.${placeId}&select=id&limit=1`,
            { headers: { ...svc, "Accept-Profile": "bookings" } },
          )
        : Promise.resolve(null),
      placeId
        ? fetch(
            `${supabaseUrl}/rest/v1/memberships?user_id=eq.${userId}&place_id=eq.${placeId}&select=id&limit=1`,
            { headers: { ...svc, "Accept-Profile": "bookings" } },
          )
        : Promise.resolve(null),
    ]);

    const bookings    = bRes.ok ? await bRes.json() as { id: string }[] : [];
    const memberships = mRes.ok ? await mRes.json() as { id: string }[] : [];
    const bookingsAtPlace    = bPlaceRes && bPlaceRes.ok ? await bPlaceRes.json() as { id: string }[] : [];
    const membershipsAtPlace = mPlaceRes && mPlaceRes.ok ? await mPlaceRes.json() as { id: string }[] : [];
    const anyCount = bookings.length + memberships.length;

    return {
      isFirstPurchaseAtPlace: placeId
        ? bookingsAtPlace.length === 0 && membershipsAtPlace.length === 0
        : false,
      isNewCustomer: anyCount === 0,
    };
  } catch {
    return { isFirstPurchaseAtPlace: false, isNewCustomer: false };
  }
}

async function callRpc(
  supabaseUrl: string,
  jwt: string,
  rpcName: string,
  args: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  return await callRpcSchema(supabaseUrl, jwt, "bookings", rpcName, args) as Record<string, unknown>;
}

async function callRpcSchema(
  supabaseUrl: string,
  jwt: string,
  schema: string,
  rpcName: string,
  args: Record<string, unknown>,
): Promise<unknown> {
  const res = await fetch(`${supabaseUrl}/rest/v1/rpc/${rpcName}`, {
    method: "POST",
    headers: {
      apikey: Deno.env.get("SUPABASE_ANON_KEY")!,
      Authorization: `Bearer ${jwt}`,
      "Content-Type": "application/json",
      "Content-Profile": schema,
    },
    body: JSON.stringify(args),
  });

  const data = await res.json();
  if (!res.ok) {
    const msg = (data as { message?: string; error?: string })?.message
      ?? (data as { error?: string })?.error
      ?? `RPC ${rpcName} failed ${res.status}`;
    throw new Error(msg);
  }
  return data;
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Derive the caller's role and (for merchants) their own merchant id.
 *  Unspoofable: based on the authenticated caller id, not client input.
 *  The returned `merchantId` is used to scope merchant dashboard-powers to the
 *  merchant's OWN places (prevents cross-tenant on-behalf-of / free booking). */
async function deriveCaller(
  supabaseUrl: string,
  svc: Record<string, string>,
  callerId: string,
): Promise<{ source: "admin" | "merchant" | "mobile_app"; merchantId: string | null }> {
  try {
    const adminRes = await fetch(
      `${supabaseUrl}/rest/v1/admin_roles?user_id=eq.${callerId}&select=user_id&limit=1`,
      { headers: { ...svc, "Accept-Profile": "admin" } },
    );
    if (adminRes.ok && (await adminRes.json() as unknown[]).length > 0) {
      return { source: "admin", merchantId: null };
    }
  } catch { /* fall through */ }
  try {
    const merchRes = await fetch(
      `${supabaseUrl}/rest/v1/merchants?user_id=eq.${callerId}&select=id&limit=1`,
      { headers: { ...svc, "Accept-Profile": "business" } },
    );
    if (merchRes.ok) {
      const [row] = await merchRes.json() as { id: string }[];
      if (row?.id) return { source: "merchant", merchantId: row.id };
    }
  } catch { /* fall through */ }
  return { source: "mobile_app", merchantId: null };
}

/** Whether the merchant requires payment for dashboard-created bookings. */
async function dashboardPaymentRequired(
  supabaseUrl: string,
  svc: Record<string, string>,
  merchantId: string | null,
): Promise<boolean> {
  if (!merchantId) return true; // safe default: require payment
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/merchants?id=eq.${merchantId}&select=dashboard_payment_required`,
      { headers: { ...svc, "Accept-Profile": "business" } },
    );
    if (res.ok) {
      const [row] = await res.json() as { dashboard_payment_required: boolean | null }[];
      if (row && row.dashboard_payment_required === false) return false;
    }
  } catch { /* default true */ }
  return true;
}

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
    if (!res.ok) return false;
    const [row] = await res.json() as { cash_enabled: boolean | null }[];
    return row?.cash_enabled !== false;
  } catch {
    return false;
  }
}

function serviceHeaders(serviceKey: string): Record<string, string> {
  return {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    "Content-Type": "application/json",
    Prefer: "return=minimal",
  };
}

/** Today's date in Asia/Baghdad as "YYYY-MM-DD". Comparing lexicographically
 *  against the DATE columns returned by PostgREST is safe.
 */
function todayBaghdadISO(): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Baghdad",
    year: "numeric", month: "2-digit", day: "2-digit",
  }).formatToParts(new Date());
  let y = "", mo = "", da = "";
  for (const p of parts) {
    if (p.type === "year") y = p.value;
    else if (p.type === "month") mo = p.value;
    else if (p.type === "day") da = p.value;
  }
  return `${y}-${mo}-${da}`;
}

function resolveCommissionPct(merchant: {
  commission_percentage: number | null;
  temp_commission_percentage: number | null;
  temp_commission_from: string | null;
  temp_commission_to:   string | null;
} | undefined): number {
  if (!merchant) return 12;
  const tempPct = merchant.temp_commission_percentage;
  const from = merchant.temp_commission_from?.slice(0, 10) ?? null;
  const to   = merchant.temp_commission_to?.slice(0, 10) ?? null;
  if (tempPct != null && from && to) {
    const today = todayBaghdadISO();
    if (today >= from && today <= to) return Number(tempPct);
  }
  if (merchant.commission_percentage != null) return Number(merchant.commission_percentage);
  return 12;
}

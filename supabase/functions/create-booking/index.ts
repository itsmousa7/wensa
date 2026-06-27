/**
 * create-booking — orchestrates booking creation + Wayl payment link.
 *
 * Flow:
 *   1. Validate caller JWT
 *   2. Resolve place/event context (merchant_id, category_id) and purchase history
 *   3. Call the appropriate bookings.create_* RPC (inserts pending row(s))
 *   4. Apply discount server-side (promo OR auto), persist audit columns +
 *      final amount on the booking row(s).
 *   5. Create a Wayl payment link for the *final* amount
 *   6. Return { booking_id?, group_id?, payment_url, hold_until, reference_id }
 *
 * referenceId format:
 *   bookings:  booking_{booking_id}_{timestamp}
 *   concerts:  booking_venue_{group_id}_{timestamp}
 *
 * Env vars required:
 *   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY
 *   WAYL_API_KEY, WAYL_WEBHOOK_SECRET, WAYL_WEBHOOK_URL
 *   WAYL_ENV               — "live" | "test" (default: "live")
 *   APP_DEEP_LINK_BASE     — e.g. "wansa://payment"
 *   MERCHANT_PORTAL_URL    — e.g. "http://localhost:5173" (QR deep-link host)
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const WAYL_BASE = "https://api.thewayl.com";

// ── Types ─────────────────────────────────────────────────────────────────────

type BookingCategory = "hourly" | "shift" | "reservation" | "venue_seat" | "general_admission" | "membership";

interface BasePaylod {
  category: BookingCategory;
  redirect_url?: string;
  promo_code?: string;
  guest_name?: string; // dashboard: name the booking is held under
}

interface HourlyPayload extends BasePaylod {
  category: "hourly";
  place_id: string;
  court_id: string;
  starts_at: string;
  hours: number;
}

interface ShiftPayload extends BasePaylod {
  category: "shift";
  place_id: string;
  date: string;
  shift_type: "day" | "night" | "full";
}

interface VenueSeatPayload extends BasePaylod {
  category: "venue_seat";
  event_id: string;
  seat_ids: string[];
}

interface GeneralAdmissionPayload extends BasePaylod {
  category: "general_admission";
  event_id: string;
  section_id: string;
  quantity: number;
}

interface ReservationPayload extends BasePaylod {
  category: "reservation";
  place_id: string;
  starts_at: string;
  party_size: number;
  seating_option_id?: string;
}

type BookingPayload = HourlyPayload | ShiftPayload | VenueSeatPayload | GeneralAdmissionPayload | ReservationPayload;

/** Event ticket categories (venue seats + general admission). Events are NEVER
 *  discounted — auto/promo/merchant discounts apply to place bookings only. */
function isEventCategory(cat: BookingCategory): boolean {
  return cat === "venue_seat" || cat === "general_admission";
}

// ── Main handler ──────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const SUPABASE_URL    = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_KEY     = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const WAYL_API_KEY    = Deno.env.get("WAYL_API_KEY")!;
  const WAYL_WEBHOOK_SECRET = Deno.env.get("WAYL_WEBHOOK_SECRET")!;
  const WAYL_WEBHOOK_URL    = Deno.env.get("WAYL_BOOKING_WEBHOOK_URL") ?? Deno.env.get("WAYL_WEBHOOK_URL")!;
  const APP_DEEP_LINK   = Deno.env.get("APP_DEEP_LINK_BASE") ?? "wansa://payment";
  const WAYL_ENV        = Deno.env.get("WAYL_ENV") ?? "live";

  try {
    // ── Auth ───────────────────────────────────────────────────────────────
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

    const body = await req.json() as BookingPayload;
    if (!body.category) return json({ error: "category is required" }, 400);

    const svc = serviceHeaders(SERVICE_KEY);
    const promoCode = body.promo_code?.trim().toUpperCase() || null;

    const { source: callerRole, merchantId: callerMerchantId } =
      await deriveCaller(SUPABASE_URL, svc, callerId);

    // ── Resolve place/event context (merchant_id, category_id) ─────────────
    const ctx = await resolveContext(SUPABASE_URL, svc, body);
    if (!ctx) return json({ error: "Unable to resolve booking context" }, 400);

    // Dashboard powers (book on behalf of a customer, free path) are limited to
    // admins and to a merchant acting on its OWN merchant. A merchant hitting
    // another merchant's place is treated as a regular paying customer; the
    // unspoofable `source` label reflects that.
    const isDashboard = callerRole === "admin" ||
      (callerRole === "merchant" && callerMerchantId !== null && callerMerchantId === ctx.merchantId);
    const source = isDashboard ? callerRole : "mobile_app";
    // Dashboard bookings are owned by the staff caller; guest_name is the label.
    const effectiveUserId = callerId;

    // ── Purchase history (BEFORE inserting the new pending row) ────────────
    const { isFirstPurchaseAtPlace, isNewCustomer } = await fetchPurchaseHistory(
      SUPABASE_URL, svc, effectiveUserId, ctx.placeId,
    );

    // ── Call the appropriate RPC ───────────────────────────────────────────
    let rpcResult: Record<string, unknown>;
    let referenceId: string;
    let customParameter: string;
    let subtotalIqd: number;
    let lineItemLabel: string;
    const ts = Date.now();

    if (body.category === "hourly") {
      const p = body as HourlyPayload;
      rpcResult = await callRpc(SUPABASE_URL, jwt, "bookings", "create_court_booking", {
        p_place_id:  p.place_id,
        p_court_id:  p.court_id,
        p_starts_at: p.starts_at,
        p_hours:     p.hours,
      });
      subtotalIqd     = rpcResult.amount_iqd as number;
      referenceId     = `booking_${rpcResult.id}_${ts}`;
      customParameter = String(rpcResult.id);
      lineItemLabel   = `Hourly court booking — ${p.hours}h`;

    } else if (body.category === "shift") {
      const p = body as ShiftPayload;
      rpcResult = await callRpc(SUPABASE_URL, jwt, "bookings", "create_farm_booking", {
        p_place_id:   p.place_id,
        p_date:       p.date,
        p_shift_type: p.shift_type,
      });
      subtotalIqd     = rpcResult.amount_iqd as number;
      referenceId     = `booking_${rpcResult.id}_${ts}`;
      customParameter = String(rpcResult.id);
      lineItemLabel   = `Shift booking — ${p.shift_type} shift`;

    } else if (body.category === "venue_seat") {
      const p = body as VenueSeatPayload;
      rpcResult = await callRpc(SUPABASE_URL, jwt, "bookings", "create_concert_booking", {
        p_event_id: p.event_id,
        p_seat_ids: p.seat_ids,
      });
      subtotalIqd     = rpcResult.total_iqd as number;
      referenceId     = `booking_venue_${rpcResult.group_id}_${ts}`;
      customParameter = String(rpcResult.group_id);
      lineItemLabel   = `Seat / Venue ticket(s) × ${rpcResult.seat_count}`;

    } else if (body.category === "general_admission") {
      const p = body as GeneralAdmissionPayload;
      rpcResult = await callRpc(SUPABASE_URL, jwt, "bookings", "create_ga_booking", {
        p_event_id:   p.event_id,
        p_section_id: p.section_id,
        p_quantity:   p.quantity,
      });
      subtotalIqd     = rpcResult.total_iqd as number;
      referenceId     = `booking_${rpcResult.id}_${ts}`;
      customParameter = String(rpcResult.id);
      lineItemLabel   = `General admission × ${rpcResult.quantity}`;

    } else if (body.category === "reservation") {
      const p = body as ReservationPayload;
      rpcResult = await callRpc(SUPABASE_URL, jwt, "bookings", "create_restaurant_booking", {
        p_place_id:          p.place_id,
        p_starts_at:         p.starts_at,
        p_party_size:        p.party_size,
        p_seating_option_id: p.seating_option_id ?? null,
      });
      subtotalIqd     = (rpcResult.amount_iqd as number) ?? 0;
      referenceId     = `booking_${rpcResult.id}_${ts}`;
      customParameter = String(rpcResult.id);
      lineItemLabel   = `Reservation — party of ${p.party_size}`;

    } else {
      return json({ error: "Unsupported category" }, 400);
    }

    // ── Apply discount server-side ─────────────────────────────────────────
    const isGroup = isGroupCategory(body.category);
    const orderIdForRedeem = isGroup
      ? (rpcResult.group_id as string)
      : (rpcResult.id as string);

    // Merchant hourly discounts apply per-slot on hourly bookings only.
    const hourlyContext = body.category === "hourly"
      ? {
          startsAt:     (body as HourlyPayload).starts_at,
          hours:        (body as HourlyPayload).hours,
          pricePerHour: (body as HourlyPayload).hours > 0
            ? Math.round(subtotalIqd / (body as HourlyPayload).hours)
            : subtotalIqd,
        }
      : null;

    // Events (venue seats + general admission) are NEVER discounted — discounts
    // are a place-booking concept only. Skip all discount resolution so an
    // app-wide auto-discount (applies_to: 'bookings') can't bleed onto tickets.
    const discount: DiscountResolved = isEventCategory(body.category)
      ? {
          kind: "ok",
          finalAmount:    subtotalIqd,
          discountAmount: 0,
          source:         null,
          promoCodeId:    null,
          autoDiscountId: null,
          merchantDiscountId: null,
        }
      : await resolveDiscount({
          supabaseUrl:    SUPABASE_URL,
          serviceKey:     SERVICE_KEY,
          jwt,
          orderType:      "bookings",
          orderId:        orderIdForRedeem,
          amount:         subtotalIqd,
          categoryId:     ctx.categoryId,
          merchantId:     ctx.merchantId,
          placeId:        ctx.placeId,
          promoCode,
          isFirstPurchaseAtPlace,
          isNewCustomer,
          hourlyContext,
        });

    if (discount.kind === "promo_invalid") {
      // Roll back the pending row(s) so the user isn't pinned to a rejected promo.
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
      return json({ error: `Promo code rejected: ${discount.reason}` }, 400);
    }

    const finalIqd           = discount.finalAmount;
    const discountAmount     = discount.discountAmount;
    const discountSource     = discount.source;
    const promoCodeId        = discount.promoCodeId;
    const autoDiscountId     = discount.autoDiscountId;
    const merchantDiscountId = discount.merchantDiscountId;

    // ── Free path: dashboard booking for a merchant with payment toggle OFF ──
    if (isDashboard && !(await dashboardPaymentRequired(SUPABASE_URL, svc, ctx.merchantId))) {
      const freeFilter = isGroup ? `group_id=eq.${rpcResult.group_id}` : `id=eq.${rpcResult.id}`;
      const freePatch = isGroup
        ? { status: "confirmed", payment_status: "free", commission_pct: 0, source, guest_name: body.guest_name ?? null }
        : {
            status:               "confirmed",
            payment_status:       "free",
            commission_pct:       0,
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
      await fetch(`${SUPABASE_URL}/rest/v1/bookings?${freeFilter}`, {
        method: "PATCH",
        headers: { ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings" },
        body: JSON.stringify(freePatch),
      });
      return json({
        booking_id:  !isGroup ? rpcResult.id : undefined,
        group_id:    isGroup  ? rpcResult.group_id : undefined,
        free:        true,
        amount_iqd:  finalIqd,
        source,
      }, 200);
    }

    // ── Create Wayl payment link for the FINAL amount ──────────────────────
    // Always carry referenceId + category to the redirect target so the post-
    // payment landing page (mobile deep link OR the dashboard confirmation page)
    // can look the booking up on a fresh page load. A caller-supplied
    // redirect_url is treated as a base; we append the params either way.
    const redirectBase = body.redirect_url ?? APP_DEEP_LINK;
    const redirectSep  = redirectBase.includes("?") ? "&" : "?";
    const redirectUrl  = `${redirectBase}${redirectSep}referenceId=${referenceId}&category=${body.category}`;

    const waylBody = {
      env:             WAYL_ENV,
      referenceId,
      total:           finalIqd,
      currency:        "IQD",
      customParameter,
      lineItem: [
        { label: lineItemLabel, amount: finalIqd, type: "increase" },
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

    // ── Look up merchant commission to snapshot onto booking ───────────────
    // Priority: temp override (when current Asia/Baghdad date is in window)
    //           → merchant.commission_percentage → 12% default.
    let commissionPct: number = 12;
    if (ctx.merchantId) {
      try {
        const merchantRes = await fetch(
          `${SUPABASE_URL}/rest/v1/merchants?id=eq.${ctx.merchantId}` +
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

    // ── Persist payment reference, commission, and discount audit ──────────
    if (!isGroup) {
      await fetch(
        `${SUPABASE_URL}/rest/v1/bookings?id=eq.${rpcResult.id}`,
        {
          method: "PATCH",
          headers: { ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings" },
          body: JSON.stringify({
            payment_id:           referenceId,
            commission_pct:       commissionPct,
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
            ...(waylCode ? { wayl_code: waylCode } : {}),
          }),
        },
      );
    } else {
      // venue_seat: discount is on the group total. We snapshot original/final
      // totals + audit on every row; per-seat amount_iqd stays per-seat for
      // reporting/refund granularity. Since concert UI doesn't expose promo,
      // discount here is auto-only and applies to all seats in the group.
      await fetch(
        `${SUPABASE_URL}/rest/v1/bookings?group_id=eq.${rpcResult.group_id}`,
        {
          method: "PATCH",
          headers: { ...svc, "Accept-Profile": "bookings", "Content-Profile": "bookings" },
          body: JSON.stringify({
            commission_pct:      commissionPct,
            original_amount_iqd: null, // per-seat, see below
            discount_source:     discountSource,
            auto_discount_id:    autoDiscountId,
            source,
            guest_name:          body.guest_name ?? null,
            ...(waylCode ? { wayl_code: waylCode } : {}),
          }),
        },
      );
      // For seats: we don't try to split per-seat — keep per-seat amount_iqd
      // unchanged and rely on group-level total + audit columns to reconcile.
    }

    return json({
      booking_id:  !isGroup ? rpcResult.id : undefined,
      group_id:    isGroup  ? rpcResult.group_id : undefined,
      payment_url: paymentUrl,
      hold_until:  rpcResult.hold_until ?? rpcResult.expires_at,
      reference_id: referenceId,
      amount_iqd:          finalIqd,
      original_amount_iqd: subtotalIqd,
      discount_amount_iqd: discountAmount,
    }, 200);

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Internal server error";
    console.error("create-booking error:", msg);
    return json({ error: msg }, 500);
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

interface BookingContext {
  placeId: string | null;
  merchantId: string | null;
  categoryId: string | null;
}

async function resolveContext(
  supabaseUrl: string,
  svc: Record<string, string>,
  body: BookingPayload,
): Promise<BookingContext | null> {
  try {
    if (body.category === "venue_seat" || body.category === "general_admission") {
      const eventId = (body as VenueSeatPayload | GeneralAdmissionPayload).event_id;
      const evRes = await fetch(
        `${supabaseUrl}/rest/v1/events?id=eq.${eventId}&select=merchant_id,place_id`,
        { headers: { ...svc, "Accept-Profile": "content" } },
      );
      const [ev] = evRes.ok ? await evRes.json() as { merchant_id: string | null; place_id: string | null }[] : [];
      let categoryId: string | null = null;
      if (ev?.place_id) {
        const plRes = await fetch(
          `${supabaseUrl}/rest/v1/places?id=eq.${ev.place_id}&select=category_id`,
          { headers: { ...svc, "Accept-Profile": "content" } },
        );
        const [pl] = plRes.ok ? await plRes.json() as { category_id: string | null }[] : [];
        categoryId = pl?.category_id ?? null;
      }
      return { placeId: ev?.place_id ?? null, merchantId: ev?.merchant_id ?? null, categoryId };
    }
    const placeId = (body as HourlyPayload | ShiftPayload | ReservationPayload).place_id;
    const plRes = await fetch(
      `${supabaseUrl}/rest/v1/places?id=eq.${placeId}&select=merchant_id,category_id`,
      { headers: { ...svc, "Accept-Profile": "content" } },
    );
    const [pl] = plRes.ok ? await plRes.json() as { merchant_id: string | null; category_id: string | null }[] : [];
    return { placeId, merchantId: pl?.merchant_id ?? null, categoryId: pl?.category_id ?? null };
  } catch {
    return null;
  }
}

interface DiscountResolved {
  kind: "ok" | "promo_invalid";
  finalAmount: number;
  discountAmount: number;
  source: "promo" | "auto" | "merchant" | null;
  promoCodeId: string | null;
  autoDiscountId: string | null;
  merchantDiscountId: string | null;
  reason?: string;
}

interface HourlyContext {
  startsAt: string;       // ISO timestamp of the first slot
  hours: number;          // number of consecutive 1h slots
  pricePerHour: number;   // integer IQD per hour
}

async function resolveDiscount(args: {
  supabaseUrl: string;
  serviceKey: string;
  jwt: string;
  orderType: string;
  orderId: string;
  amount: number;
  categoryId: string | null;
  merchantId: string | null;
  placeId: string | null;
  promoCode: string | null;
  isFirstPurchaseAtPlace: boolean;
  isNewCustomer: boolean;
  hourlyContext: HourlyContext | null;
}): Promise<DiscountResolved> {
  const base: DiscountResolved = {
    kind: "ok",
    finalAmount: args.amount,
    discountAmount: 0,
    source: null,
    promoCodeId: null,
    autoDiscountId: null,
    merchantDiscountId: null,
  };

  if (args.amount <= 0) return base;

  // Step 1: merchant hourly discount applies to the raw subtotal.
  let merchantAmt = 0;
  let merchantDiscId: string | null = null;
  if (args.hourlyContext && args.placeId && args.merchantId) {
    const m = await previewMerchantHourly({
      supabaseUrl:   args.supabaseUrl,
      serviceKey:    args.serviceKey,
      placeId:       args.placeId,
      merchantId:    args.merchantId,
      startsAt:      args.hourlyContext.startsAt,
      hours:         args.hourlyContext.hours,
      pricePerHour:  args.hourlyContext.pricePerHour,
      amount:        args.amount,
    });
    merchantAmt = m.discountAmount;
    merchantDiscId = m.merchantDiscountId;
  }
  const afterMerchant = args.amount - merchantAmt;

  // Step 2: promo (if any) stacks on top — it applies to the post-merchant amount.
  if (args.promoCode) {
    const result = await callRpc(args.supabaseUrl, args.jwt, "business", "redeem_promo_code", {
      p_code:               args.promoCode,
      p_order_type:         args.orderType,
      p_amount:             afterMerchant,
      p_order_id:           args.orderId,
      p_category_id:        args.categoryId,
      p_merchant_id:        args.merchantId,
      p_place_id:           args.placeId,
      p_is_first_purchase_at_place: args.isFirstPurchaseAtPlace,
      p_is_new_customer:            args.isNewCustomer,
    });

    if (result && (result as { valid?: boolean }).valid) {
      const r = result as { promo_code_id: string; discount_amount: number; final_amount: number };
      const promoDisc  = Math.round(r.discount_amount);
      const finalAfter = Math.round(r.final_amount);
      return {
        kind: "ok",
        finalAmount:    finalAfter,
        discountAmount: merchantAmt + promoDisc,
        source: "promo",
        promoCodeId: r.promo_code_id,
        autoDiscountId: null,
        merchantDiscountId: merchantDiscId,
      };
    }
    return {
      ...base,
      kind: "promo_invalid",
      reason: (result as { reason?: string })?.reason ?? "invalid",
    };
  }

  // No promo: compare auto vs merchant_hourly; biggest wins. They never stack.
  let autoAmt = 0;
  let autoId: string | null = null;
  const auto = await callRpc(args.supabaseUrl, args.jwt, "business", "preview_auto_discount", {
    p_order_type:  args.orderType,
    p_amount:      args.amount,
    p_category_id: args.categoryId,
    p_merchant_id: args.merchantId,
    p_place_id:    args.placeId,
  });
  if (auto && (auto as { valid?: boolean }).valid) {
    const r = auto as { auto_discount_id: string; discount_amount: number };
    autoAmt = Math.round(r.discount_amount);
    autoId  = r.auto_discount_id;
  }

  if (merchantAmt > 0 && merchantAmt >= autoAmt) {
    return {
      kind: "ok",
      finalAmount:    afterMerchant,
      discountAmount: merchantAmt,
      source: "merchant",
      promoCodeId: null,
      autoDiscountId: null,
      merchantDiscountId: merchantDiscId,
    };
  }
  if (autoAmt > 0) {
    return {
      kind: "ok",
      finalAmount:    args.amount - autoAmt,
      discountAmount: autoAmt,
      source: "auto",
      promoCodeId: null,
      autoDiscountId: autoId,
      merchantDiscountId: null,
    };
  }

  return base;
}

/** Picks the largest applicable business.merchant_discounts row for an
 *  hourly booking. Each selected hour at a discounted hour_slot earns the
 *  full percent off that hour's price; non-discounted hours stay at full price.
 */
async function previewMerchantHourly(args: {
  supabaseUrl: string;
  serviceKey: string;
  placeId: string;
  merchantId: string;
  startsAt: string;
  hours: number;
  pricePerHour: number;
  amount: number;
}): Promise<{ discountAmount: number; merchantDiscountId: string | null }> {
  try {
    const url =
      `${args.supabaseUrl}/rest/v1/merchant_discounts` +
      `?select=id,percent,max_discount_amount,applies_to_all_places,place_ids,` +
      `time_mode,hour_slots,hour_start,hour_end,discount_dates,starts_at,expires_at,is_active` +
      `&merchant_id=eq.${args.merchantId}&is_active=eq.true`;
    const res = await fetch(url, {
      headers: {
        apikey: args.serviceKey,
        Authorization: `Bearer ${args.serviceKey}`,
        "Accept-Profile": "business",
      },
    });
    if (!res.ok) return { discountAmount: 0, merchantDiscountId: null };
    const rows = await res.json() as Array<{
      id: string;
      percent: number | string;
      max_discount_amount: number | string | null;
      applies_to_all_places: boolean;
      place_ids: string[] | null;
      time_mode: "all_day" | "hours";
      hour_slots: number[] | null;
      hour_start: string | null;
      hour_end: string | null;
      discount_dates: string[] | null;
      starts_at: string | null;
      expires_at: string | null;
      is_active: boolean;
    }>;

    const now = new Date();
    const firstSlot = new Date(args.startsAt);
    if (Number.isNaN(firstSlot.getTime())) {
      return { discountAmount: 0, merchantDiscountId: null };
    }
    // Per-slot (hour-of-day, YYYY-MM-DD date) tuples in Asia/Baghdad — the
    // timezone the admin uses when configuring merchant_discounts.hour_slots
    // and discount_dates. Deno Deploy runs in UTC, so Date.getHours() would
    // be off by 3 hours and silently zero out evening discounts.
    const tzFmt = new Intl.DateTimeFormat("en-CA", {
      timeZone:  "Asia/Baghdad",
      year:      "numeric",
      month:     "2-digit",
      day:       "2-digit",
      hour:      "2-digit",
      hour12:    false,
    });
    const slotInfos: { hour: number; dateStr: string }[] = [];
    for (let i = 0; i < args.hours; i++) {
      const d = new Date(firstSlot.getTime() + i * 60 * 60 * 1000);
      let y = "", mo = "", da = "", hr = "";
      for (const p of tzFmt.formatToParts(d)) {
        if (p.type === "year")  y  = p.value;
        else if (p.type === "month") mo = p.value;
        else if (p.type === "day")   da = p.value;
        else if (p.type === "hour")  hr = p.value;
      }
      slotInfos.push({
        hour:    parseInt(hr, 10) % 24, // Intl can return "24" at midnight
        dateStr: `${y}-${mo}-${da}`,
      });
    }

    let bestAmt = 0;
    let bestId: string | null = null;
    for (const r of rows) {
      if (!r.is_active) continue;
      if (r.starts_at && new Date(r.starts_at) > now) continue;
      if (r.expires_at && new Date(r.expires_at) < now) continue;
      if (!r.applies_to_all_places) {
        const ids = r.place_ids ?? [];
        if (!ids.includes(args.placeId)) continue;
      }
      const percent = Number(r.percent);
      if (!(percent > 0)) continue;

      const matchesHour = (h: number): boolean => {
        if (r.time_mode === "all_day") return true;
        if (r.hour_slots && r.hour_slots.length > 0) {
          return r.hour_slots.includes(h);
        }
        const parseH = (s: string | null): number | null => {
          if (!s) return null;
          const parts = s.split(":");
          const n = parseInt(parts[0] ?? "", 10);
          return Number.isFinite(n) ? n : null;
        };
        const s = parseH(r.hour_start);
        const e = parseH(r.hour_end);
        if (s === null || e === null) return false;
        if (e > s) return h >= s && h < e;
        return h >= s || h < e;
      };
      // discount_dates: when non-empty, the slot date must be in the list.
      const dateAllowList = Array.isArray(r.discount_dates)
        ? r.discount_dates.map((s) => String(s).slice(0, 10))
        : [];
      const matchesDate = (dateStr: string): boolean =>
        dateAllowList.length === 0 || dateAllowList.includes(dateStr);

      let discountedHours = 0;
      for (const info of slotInfos) {
        if (matchesDate(info.dateStr) && matchesHour(info.hour)) {
          discountedHours++;
        }
      }
      if (discountedHours === 0) continue;

      let amt = Math.round((args.pricePerHour * discountedHours * percent) / 100);
      const cap = r.max_discount_amount == null ? null : Number(r.max_discount_amount);
      if (cap != null && Number.isFinite(cap) && amt > cap) amt = Math.round(cap);
      if (amt > args.amount) amt = args.amount;
      if (amt > bestAmt) {
        bestAmt = amt;
        bestId = r.id;
      }
    }
    return { discountAmount: bestAmt, merchantDiscountId: bestId };
  } catch {
    return { discountAmount: 0, merchantDiscountId: null };
  }
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

/** Today's date in Asia/Baghdad as "YYYY-MM-DD" — the timezone the admin
 *  picks dates in. Comparing lexicographically against the DATE columns
 *  returned by PostgREST (also "YYYY-MM-DD" strings) is safe.
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

function isGroupCategory(cat: BookingCategory): boolean {
  return cat === "venue_seat";
}

function serviceHeaders(serviceKey: string): Record<string, string> {
  return {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    "Content-Type": "application/json",
    Prefer: "return=minimal",
  };
}

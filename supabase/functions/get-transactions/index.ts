/**
 * get-transactions — returns webhook_logs rows to authenticated admins.
 *
 * The webhook_logs table requires service-role access (RLS blocks JWT reads).
 * This function validates the caller is an admin, then queries using
 * the service role key.
 *
 * Output: webhook_logs rows ordered by created_at desc
 *
 * Env vars required:
 *   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Page through a PostgREST listing until an empty page. A single request is
// silently truncated at the project's max-rows setting (default 1000), which
// would drop transactions from the feed and corrupt the financial totals.
async function fetchAllRows(urlBase: string, headers: Record<string, string>): Promise<any[]> {
  const out: any[] = [];
  let offset = 0;
  while (offset < 500000) {
    const res = await fetch(`${urlBase}&limit=1000&offset=${offset}`, { headers });
    if (!res.ok) {
      // Throw rather than return partial data — silently missing rows would
      // corrupt the financial totals computed from this feed.
      const err = await res.text();
      throw new Error(`fetch ${urlBase.split("?")[0].split("/rest/v1/")[1]} failed (${res.status}): ${err}`);
    }
    const page = await res.json() as any[];
    out.push(...page);
    if (page.length === 0) break;
    offset += page.length;
  }
  return out;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return json([], 200);
  if (req.method !== "GET") return json({ error: "Method not allowed" }, 405);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  try {
    // ── Auth: require valid Bearer token ──────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return json({ error: "Missing authorization" }, 401);
    }
    const jwt = authHeader.slice(7);

    // Verify the caller's JWT is valid
    const userRes = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { Authorization: `Bearer ${jwt}`, apikey: SERVICE_KEY },
    });
    if (!userRes.ok) return json({ error: "Invalid token" }, 401);
    const userData = await userRes.json();
    const userId = userData?.id;
    if (!userId) return json({ error: "Invalid token" }, 401);

    // Verify caller is an admin
    const adminCheck = await fetch(
      `${SUPABASE_URL}/rest/v1/admin_roles?user_id=eq.${userId}&select=user_id&limit=1`,
      { headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Accept-Profile": "admin" } }
    );
    if (!adminCheck.ok) return json({ error: "Admin check failed" }, 500);
    const adminRows = await adminCheck.json();
    if (!Array.isArray(adminRows) || adminRows.length === 0) {
      return json({ error: "Forbidden: admin access required" }, 403);
    }

    // ── Fetch webhook_logs using service role ─────────────────────────────────
    const baseHeaders = { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, Accept: "application/json" };
    const bookingsHeaders = { ...baseHeaders, "Accept-Profile": "bookings" };

    // ── Fetch all transaction sources (paged past the max-rows cap) ──────────
    const [logs, rawBookings, rawMemberships, rawPayTx] = await Promise.all([
      fetchAllRows(
        `${SUPABASE_URL}/rest/v1/webhook_logs?select=*&order=created_at.desc`,
        baseHeaders
      ),
      fetchAllRows(
        `${SUPABASE_URL}/rest/v1/bookings?payment_status=in.(paid,refunded,free)&select=id,created_at,user_id,category,amount_iqd,payment_id,wayl_code,payment_status,payment_method,place_id,commission_pct,source&order=created_at.desc`,
        bookingsHeaders
      ),
      fetchAllRows(
        `${SUPABASE_URL}/rest/v1/memberships?payment_status=in.(paid,refunded,free)&select=id,created_at,user_id,merchant_id,amount_iqd,payment_id,wayl_code,payment_status,payment_method,commission_pct,source&order=created_at.desc`,
        bookingsHeaders
      ),
      fetchAllRows(
        `${SUPABASE_URL}/rest/v1/payment_transactions?select=*&order=created_at.desc`,
        bookingsHeaders
      ),
    ]);
    // Only successful rows surface in the feed (failed attempts are noise here).
    const successPayTx = rawPayTx.filter((t: any) => t.status === "success");
    const payTxByBooking: Record<string, any> = {};
    const payTxByGroupRef: Record<string, any> = {};   // payment_id (reference) → tx, for concert rows
    const payTxByMembership: Record<string, any> = {};
    for (const t of successPayTx) {
      if (t.booking_id) payTxByBooking[t.booking_id] = t;
      if (t.group_id && t.reference_id) payTxByGroupRef[t.reference_id] = t;
      if (t.membership_id) payTxByMembership[t.membership_id] = t;
    }

    // ── Collect IDs for enrichment ────────────────────────────────────────────
    const placeIdSet = new Set<string>();
    const userIdSet = new Set<string>();
    const planMerchantIdSet = new Set<string>();
    const bannerIdSet = new Set<string>();

    for (const b of rawBookings) {
      if (b.place_id) placeIdSet.add(b.place_id);
      if (b.user_id) userIdSet.add(b.user_id);
    }
    for (const m of rawMemberships) {
      if (m.user_id) userIdSet.add(m.user_id);
    }
    for (const log of logs) {
      const ref: string = log.body?.referenceId ?? "";
      if (ref.startsWith("wansa_")) {
        const mid = ref.slice(6, 42);
        if (mid.length === 36) planMerchantIdSet.add(mid);
      } else if (ref.startsWith("banner_")) {
        const bid = ref.slice(7, 43);
        if (bid) bannerIdSet.add(bid);
      }
    }

    // ── Fetch enrichment data in parallel ─────────────────────────────────────
    const [placesData, usersData, bannersData] = await Promise.all([
      placeIdSet.size > 0
        ? fetch(
            `${SUPABASE_URL}/rest/v1/places?id=in.(${[...placeIdSet].join(",")})&select=id,merchant_id`,
            { headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, Accept: "application/json", "Accept-Profile": "content" } }
          ).then(r => r.ok ? r.json() as Promise<any[]> : Promise.resolve([]))
        : Promise.resolve([]),
      userIdSet.size > 0
        ? fetch(
            `${SUPABASE_URL}/rest/v1/app_users?id=in.(${[...userIdSet].join(",")})&select=id,first_name,second_name,phone`,
            { headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, Accept: "application/json", "Accept-Profile": "profiles" } }
          ).then(r => r.ok ? r.json() as Promise<any[]> : Promise.resolve([]))
        : Promise.resolve([]),
      bannerIdSet.size > 0
        ? fetch(
            `${SUPABASE_URL}/rest/v1/promoted_banners?id=in.(${[...bannerIdSet].join(",")})&select=id,merchant_id`,
            { headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, Accept: "application/json", "Accept-Profile": "business" } }
          ).then(r => r.ok ? r.json() as Promise<any[]> : Promise.resolve([]))
        : Promise.resolve([]),
    ]);

    // ── Build lookup maps ──────────────────────────────────────────────────────
    const placeToMerchant: Record<string, string> = {};
    for (const p of placesData as any[]) placeToMerchant[p.id] = p.merchant_id;

    const userNameMap: Record<string, string> = {};
    const userPhoneMap: Record<string, string> = {};
    for (const u of usersData as any[]) {
      userNameMap[u.id] = [u.first_name, u.second_name].filter(Boolean).join(" ") || u.phone || u.id.slice(0, 8).toUpperCase();
      if (u.phone) userPhoneMap[u.id] = u.phone;
    }

    const bannerToMerchant: Record<string, string> = {};
    for (const b of bannersData as any[]) bannerToMerchant[b.id] = b.merchant_id;

    const merchantIdSet = new Set<string>([...planMerchantIdSet]);
    for (const mid of Object.values(placeToMerchant)) if (mid) merchantIdSet.add(mid);
    for (const mid of Object.values(bannerToMerchant)) if (mid) merchantIdSet.add(mid);
    for (const m of rawMemberships) if (m.merchant_id) merchantIdSet.add(m.merchant_id);
    for (const t of successPayTx) if (t.merchant_id) merchantIdSet.add(t.merchant_id);

    const merchantNameMap: Record<string, string> = {};
    if (merchantIdSet.size > 0) {
      const merchantsRes = await fetch(
        `${SUPABASE_URL}/rest/v1/merchants?id=in.(${[...merchantIdSet].join(",")})&select=id,business_name`,
        { headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, Accept: "application/json", "Accept-Profile": "business" } }
      );
      if (merchantsRes.ok) {
        const merchants = await merchantsRes.json() as any[];
        for (const m of merchants) merchantNameMap[m.id] = m.business_name;
      }
    }

    // ── Build booking logs ─────────────────────────────────────────────────────
    const bookingLogs = rawBookings.map((b: any) => {
      const merchantId = placeToMerchant[b.place_id] ?? "";
      const isFree = b.payment_status === "free";
      const hp = payTxByBooking[b.id] ?? (b.payment_id ? payTxByGroupRef[b.payment_id] : undefined);
      return {
        id: `bkg_${b.id}`,
        created_at: b.created_at,
        status: "booking_paid",
        refunded: b.payment_status === "refunded",
        merchant_id: merchantId,
        merchant_name: merchantNameMap[merchantId] ?? "",
        commission_pct: b.commission_pct ?? null,
        source: b.source ?? "mobile_app",
        body: {
          referenceId: b.payment_id ?? "",
          total: b.amount_iqd ?? 0,
          paymentStatus: isFree ? "Free" : "Paid",
          paymentMethod: isFree ? "—" : b.payment_method === "cash" ? "Cash" : hp ? "HyperPay" : "E-Payment",
          customer: { name: userNameMap[b.user_id] ?? (b.user_id ?? "").slice(0, 8).toUpperCase(), phone: userPhoneMap[b.user_id] ?? "" },
          items: [{ label: b.category ?? "" }],
          // `wayl_code` is a retired column kept only so pre-HyperPay rows still
          // show the reference their money was collected under.
          code: hp?.unique_id ?? b.wayl_code ?? "—",
          ...(hp ? {
            uniqueId: hp.unique_id ?? undefined,
            rrn: hp.rrn ?? undefined,
            resultCode: hp.result_code ?? undefined,
            resultDescription: hp.result_description ?? undefined,
            merchantTransactionId: hp.merchant_transaction_id ?? undefined,
            cardScope: hp.card_scope ?? undefined,
            clearingInstituteName: hp.clearing_institute_name ?? undefined,
            paymentBrand: hp.payment_brand ?? undefined,
          } : {}),
        },
      };
    });

    // ── Build membership logs ─────────────────────────────────────────────────
    const membershipLogs = rawMemberships.map((m: any) => {
      const isFree = m.payment_status === "free";
      const hp = payTxByMembership[m.id];
      return {
        id: `mem_${m.id}`,
        created_at: m.created_at,
        status: "membership_paid",
        refunded: m.payment_status === "refunded",
        merchant_id: m.merchant_id ?? "",
        merchant_name: merchantNameMap[m.merchant_id] ?? "",
        commission_pct: m.commission_pct ?? null,
        source: m.source ?? "mobile_app",
        body: {
          referenceId: m.payment_id ?? "",
          total: m.amount_iqd ?? 0,
          paymentStatus: isFree ? "Free" : "Paid",
          paymentMethod: isFree ? "—" : m.payment_method === "cash" ? "Cash" : hp ? "HyperPay" : "E-Payment",
          customer: { name: userNameMap[m.user_id] ?? (m.user_id ?? "").slice(0, 8).toUpperCase(), phone: userPhoneMap[m.user_id] ?? "" },
          items: [{ label: "membership" }],
          // `wayl_code` is a retired column kept only so pre-HyperPay rows still
          // show the reference their money was collected under.
          code: hp?.unique_id ?? m.wayl_code ?? "—",
          ...(hp ? {
            uniqueId: hp.unique_id ?? undefined,
            rrn: hp.rrn ?? undefined,
            resultCode: hp.result_code ?? undefined,
            resultDescription: hp.result_description ?? undefined,
            merchantTransactionId: hp.merchant_transaction_id ?? undefined,
            cardScope: hp.card_scope ?? undefined,
            clearingInstituteName: hp.clearing_institute_name ?? undefined,
            paymentBrand: hp.payment_brand ?? undefined,
          } : {}),
        },
      };
    });

    // ── HyperPay plan/banner payments (no webhook_logs rows exist for these) ──
    const planBannerLogs = successPayTx
      .filter((t: any) => t.intent === "plan" || t.intent === "banner")
      .map((t: any) => ({
        id: `ptx_${t.id}`,
        created_at: t.created_at,
        status: `${t.intent}_paid`,
        refunded: false,
        merchant_id: t.merchant_id ?? "",
        merchant_name: merchantNameMap[t.merchant_id] ?? "",
        commission_pct: null,
        source: "merchant_dashboard",
        body: {
          referenceId: t.reference_id ?? "",
          total: t.amount_iqd ?? 0,
          paymentStatus: "Paid",
          paymentMethod: "HyperPay",
          customer: { name: merchantNameMap[t.merchant_id] ?? "—" },
          items: [{ label: t.intent }],
          code: t.unique_id ?? "—",
          uniqueId: t.unique_id ?? undefined,
          rrn: t.rrn ?? undefined,
          resultCode: t.result_code ?? undefined,
          resultDescription: t.result_description ?? undefined,
          merchantTransactionId: t.merchant_transaction_id ?? undefined,
          cardScope: t.card_scope ?? undefined,
          clearingInstituteName: t.clearing_institute_name ?? undefined,
          paymentBrand: t.payment_brand ?? undefined,
        },
      }));

    // ── Enrich webhook logs with merchant_name ─────────────────────────────────
    const enrichedLogs = logs.map((log: any) => {
      const ref: string = log.body?.referenceId ?? "";
      let merchantId = "";
      if (ref.startsWith("wansa_")) {
        merchantId = ref.slice(6, 42);
      } else if (ref.startsWith("banner_")) {
        merchantId = bannerToMerchant[ref.slice(7, 43)] ?? "";
      }
      return { ...log, merchant_id: merchantId, merchant_name: merchantNameMap[merchantId] ?? "", source: "mobile_app" };
    });

    // ── Merge and sort by date desc ───────────────────────────────────────────
    const allLogs = [...enrichedLogs, ...bookingLogs, ...membershipLogs, ...planBannerLogs].sort(
      (a: any, b: any) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );

    return json(allLogs, 200);

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Internal server error";
    console.error("get-transactions error:", msg);
    return json({ error: msg }, 500);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

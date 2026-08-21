/**
 * _shared/hyperpay.ts — HyperPay (OPPWA COPYandPAY) gateway helpers.
 *
 * Ported from the working Python UAT integration (hyper-db-uat/app.py).
 *
 * Env vars (Supabase Edge Function secrets):
 *   HYPERPAY_ENV — the ONLY switch between the two credential sets.
 *                  "live"/"prod" ⇒ production, anything else (incl. unset) ⇒ test.
 *
 *   Per-environment credentials (preferred — both sets can live side by side,
 *   so flipping HYPERPAY_ENV is the whole cutover):
 *     HYPERPAY_TEST_ENTITY_ID  / HYPERPAY_LIVE_ENTITY_ID   — checkout entity
 *     HYPERPAY_TEST_AUTH_TOKEN / HYPERPAY_LIVE_AUTH_TOKEN  — Bearer token
 *     HYPERPAY_TEST_RECURRING_ENTITY_ID / HYPERPAY_LIVE_RECURRING_ENTITY_ID
 *                                                          — recurring (MIT) channel
 *     HYPERPAY_TEST_BASE       / HYPERPAY_LIVE_BASE        — optional host override
 *
 *   Legacy unscoped fallbacks (still read when the scoped one is unset):
 *     HYPERPAY_ENTITY_ID, HYPERPAY_AUTH_TOKEN,
 *     HYPERPAY_RECURRING_ENTITY_ID, HYPERPAY_BASE
 *
 * RECURRING CHANNEL (critical):
 *   HyperPay issues a SEPARATE entity for merchant-initiated recurring charges.
 *   Every MIT charge on a stored token MUST be sent to that entity — see
 *   buildRegistrationChargeParams(), which uses recurringEntityId, not entityId.
 *   When the recurring entity is unset it falls back to entityId, which is what
 *   the single-entity deployment has always done.
 *
 * SUCCESS RULE (critical, per business requirement):
 *   test: any "successfully processed in test mode" code — 000.100.1xx
 *         (e.g. 000.100.110 integrator, 000.100.112 connector test mode)
 *         PLUS 000.000.000 (a test entity can still answer with the live
 *         success code; the deployed callers have always accepted it).
 *   prod: only result.code === "000.000.000" is a successful payment
 *   Any other FINAL code is a failure; result.description is shown to the merchant.
 *   HYPERPAY_ENV is a RAW env string: "live" and "prod" both mean production,
 *   anything else (including unset) means test — see normalizeEnv().
 *
 * Code classes:
 *   pending   000.200.*            — shopper still completing (3DS challenge)
 *   transient 800.120.100 / 900.*  — rate limit / comms; never a final result
 */

export type HyperPayEnv = "test" | "prod";

export interface HyperPayConfig {
  entityId: string;
  /** Recurring (MIT) channel entity. Falls back to entityId when unconfigured. */
  recurringEntityId: string;
  authToken: string;
  env: HyperPayEnv;
  base: string;
}

export interface HyperPayResult {
  id?: string;                      // payment/transaction id
  registrationId?: string;          // token, present when createRegistration succeeded
  merchantTransactionId?: string;
  card?: {
    bin?: string;
    last4Digits?: string;
    holder?: string;
    expiryMonth?: string;
    expiryYear?: string;
  };
  paymentBrand?: string;
  result?: { code?: string; description?: string };
  resultDetails?: Record<string, unknown>;
  [key: string]: unknown;
}

/**
 * Normalise the RAW HYPERPAY_ENV value. Deployments set it to "live" (see
 * create-booking / charge-saved-card), so a bare `as HyperPayEnv` cast would
 * silently select TEST rules for a production entity.
 */
export function normalizeEnv(raw: string | undefined | null): HyperPayEnv {
  const v = (raw ?? "").trim().toLowerCase();
  return v === "live" || v === "prod" ? "prod" : "test";
}

/** Env prefix carrying the credentials for a given environment. */
export function envPrefix(env: HyperPayEnv): "HYPERPAY_LIVE_" | "HYPERPAY_TEST_" {
  return env === "prod" ? "HYPERPAY_LIVE_" : "HYPERPAY_TEST_";
}

/**
 * Read a credential for `env`, preferring the scoped secret and falling back to
 * the legacy unscoped one. Blank/whitespace values count as unset — an empty
 * secret must not shadow the fallback (or, worse, be sent as an entityId).
 */
export function readScoped(
  suffix: string,
  env: HyperPayEnv,
  get: (k: string) => string | undefined = (k) => Deno.env.get(k),
): string | undefined {
  const clean = (v: string | undefined) => {
    const t = (v ?? "").trim();
    return t === "" ? undefined : t;
  };
  return clean(get(envPrefix(env) + suffix)) ?? clean(get("HYPERPAY_" + suffix));
}

export const DEFAULT_BASE_PROD = "https://eu-prod.oppwa.com";
export const DEFAULT_BASE_TEST = "https://eu-test.oppwa.com";

/**
 * Guard against the cutover's sharpest edge: a leftover unscoped HYPERPAY_BASE
 * pinned to the test host would silently route LIVE payments to eu-test (and
 * vice versa). Fail loudly instead of taking money on the wrong host.
 */
export function assertBaseMatchesEnv(base: string, env: HyperPayEnv): void {
  const b = base.toLowerCase();
  const wrong = env === "prod" ? "eu-test." : "eu-prod.";
  if (b.includes(wrong)) {
    throw new Error(
      `HYPERPAY_BASE (${base}) points at the ${env === "prod" ? "TEST" : "PROD"} host ` +
        `while HYPERPAY_ENV selects ${env}. Set ${envPrefix(env)}BASE (or clear HYPERPAY_BASE).`,
    );
  }
}

export function cfg(): HyperPayConfig {
  const env = normalizeEnv(Deno.env.get("HYPERPAY_ENV"));
  const entityId = readScoped("ENTITY_ID", env);
  const authToken = readScoped("AUTH_TOKEN", env);
  if (!entityId || !authToken) {
    throw new Error(
      `${envPrefix(env)}ENTITY_ID / ${envPrefix(env)}AUTH_TOKEN not configured ` +
        `(HYPERPAY_ENV=${env}); no legacy HYPERPAY_ENTITY_ID / HYPERPAY_AUTH_TOKEN either`,
    );
  }
  // Recurring charges must go to the dedicated recurring entity; a deployment
  // that has not been given one keeps the historical single-entity behaviour.
  const recurringEntityId = readScoped("RECURRING_ENTITY_ID", env) ?? entityId;
  const base = readScoped("BASE", env) ??
    (env === "prod" ? DEFAULT_BASE_PROD : DEFAULT_BASE_TEST);
  assertBaseMatchesEnv(base, env);
  return { entityId, recurringEntityId, authToken, env, base };
}

// ── Pure helpers (unit-tested in hyperpay_test.ts) ──────────────────────────

export const SUCCESS_CODE_PROD = "000.000.000";
/** "Request successfully processed in '…Test Mode'" — 000.100.110/111/112 etc. */
export const TEST_SUCCESS_RE = /^000\.100\.1\d{2}$/;

/**
 * Success rule per environment. `env` is the RAW HYPERPAY_ENV string (or an
 * already-normalised HyperPayEnv) — "live"/"prod" ⇒ prod rules, else test.
 *   prod — exact 000.000.000 (a real, live-processed payment)
 *   test — any 000.100.1xx "successfully processed in test mode" code,
 *          or 000.000.000
 * This is THE authoritative classifier: verify-payment and charge-saved-card
 * both import it (they used to hand-roll divergent copies).
 */
export function isPaymentSuccessful(code: string | undefined | null, env: string | undefined | null): boolean {
  if (!code) return false;
  if (normalizeEnv(env) === "prod") return code === SUCCESS_CODE_PROD;
  return TEST_SUCCESS_RE.test(code) || code === SUCCESS_CODE_PROD;
}

/** Canonical name used by the payment functions. */
export const isPaid = isPaymentSuccessful;

/** Shopper still completing the payment (e.g. inside the 3DS challenge). */
export function isPending(code: string | undefined | null): boolean {
  return !!code && code.startsWith("000.200");
}

/** Rate limit / communication errors — retry later, never a final result. */
export function isTransient(code: string | undefined | null): boolean {
  return code === "800.120.100" || (!!code && code.startsWith("900."));
}

/**
 * 200.300.404 "invalid or missing parameter" on a registration-payment (MIT)
 * charge — in practice this is the acquirer rejecting a REUSED
 * merchantTransactionId, not a card decline. charge-saved-card derives a
 * DETERMINISTIC id per (kind, id) to prevent double-charging on a genuine
 * double-tap; the cost is that if an earlier attempt for the same id was
 * ever sent (even one that came back pending/transient and was never
 * persisted, so we have no local record of it), a later attempt resubmits
 * the identical id and the acquirer answers 200.300.404 for the
 * resubmission itself — regardless of whether the original charge was
 * captured. So this must be treated the same as isPending/isTransient: the
 * outcome is UNKNOWN, never a confirmed decline. (Observed in production:
 * HyperPay's own portal showed the transaction settled while this code
 * caused the booking to be auto-cancelled — see charge-saved-card.)
 */
export function isDuplicateMerchantTxnId(code: string | undefined | null): boolean {
  return code === "200.300.404";
}

export interface CheckoutOptions {
  amount: number;                   // IQD, integer (0-decimal currency)
  merchantTransactionId?: string;   // omitted entirely when not provided
  tokenize: boolean;                // createRegistration + CIT standing instruction
}

/** Params for POST /v1/checkouts. */
export function buildCheckoutParams(o: CheckoutOptions, c: Pick<HyperPayConfig, "entityId" | "env">): Record<string, string> {
  const params: Record<string, string> = {
    entityId: c.entityId,
    amount: String(o.amount),
    currency: "IQD",
    paymentType: "DB",
    integrity: "true",
  };
  if (o.merchantTransactionId) params.merchantTransactionId = o.merchantTransactionId;
  // Do NOT send customer.*/billing.* here: the acquirer rejected that block with
  // 800.100.156 "transaction declined (format error)". The working UAT body omits
  // them entirely. (3DS simulator params are optional and also omitted.)
  // testMode is NOT sent in either environment — the body is identical in test
  // and prod, and a test entity routes to its own simulator without it.
  if (o.tokenize) {
    // Initial customer-initiated transaction that also stores the card.
    params.createRegistration = "true";
    params["standingInstruction.mode"] = "INITIAL";
    params["standingInstruction.source"] = "CIT";
    params["standingInstruction.type"] = "UNSCHEDULED";
    params["standingInstruction.recurringType"] = "STANDING_ORDER";
  }
  return params;
}

export interface RegistrationChargeOptions {
  amount: number;
  merchantTransactionId: string;
  initialTransactionId?: string | null;
}

/**
 * Params for POST /v1/registrations/{id}/payments (merchant-initiated charge).
 *
 * Sends the RECURRING channel entity — HyperPay provisions a separate entity
 * for MIT/recurring traffic and rejects repeated standing-instruction charges
 * on the plain checkout entity. Falls back to entityId only when no recurring
 * entity is configured.
 */
export function buildRegistrationChargeParams(
  o: RegistrationChargeOptions,
  c: Pick<HyperPayConfig, "entityId" | "env"> & { recurringEntityId?: string },
): Record<string, string> {
  const params: Record<string, string> = {
    entityId: c.recurringEntityId || c.entityId,
    amount: String(o.amount),
    currency: "IQD",
    paymentType: "DB",
    merchantTransactionId: o.merchantTransactionId,
    "standingInstruction.mode": "REPEATED",
    "standingInstruction.source": "MIT",
    "standingInstruction.type": "UNSCHEDULED",
  };
  // No testMode, matching buildCheckoutParams. This is a merchant-initiated
  // (MIT) charge on a stored token — exempt from the 3DS challenge, so it also
  // carries no 3Dsimulator params.
  if (o.initialTransactionId) {
    params["standingInstruction.initialTransactionId"] = o.initialTransactionId;
  }
  return params;
}

// ── OPPWA HTTP calls ────────────────────────────────────────────────────────

/** Form-encoded POST; OPPWA returns JSON bodies on both success and HTTP errors. */
async function postForm(url: string, params: Record<string, string>, authToken: string): Promise<HyperPayResult> {
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Authorization: `Bearer ${authToken}`,
    },
    body: new URLSearchParams(params).toString(),
  });
  return await res.json() as HyperPayResult;
}

/** Create a checkout session. Returns { id: checkoutId, integrity } (or an error result). */
export async function createCheckout(o: CheckoutOptions, c: HyperPayConfig): Promise<HyperPayResult & { integrity?: string }> {
  return await postForm(`${c.base}/v1/checkouts`, buildCheckoutParams(o, c), c.authToken);
}

/**
 * Fetch the payment result for a checkout.
 * WARNING: one-time consumable — the first call that returns a FINAL result
 * consumes the session; later calls get 200.300.404 "No payment session found".
 * Callers must persist a final outcome before responding.
 *
 * The HTTP status is returned alongside the body: OPPWA answers declines with
 * a non-2xx status AND a result code, so callers distinguish "declined" from
 * "the status call itself broke" (non-2xx with no result code ⇒ retryable).
 */
export async function getPaymentStatus(
  checkoutId: string,
  c: HyperPayConfig,
): Promise<{ httpStatus: number; result: HyperPayResult }> {
  const url = `${c.base}/v1/checkouts/${encodeURIComponent(checkoutId)}/payment?entityId=${c.entityId}`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${c.authToken}` } });
  const body = await res.json().catch(() => ({})) as HyperPayResult;
  return { httpStatus: res.status, result: body };
}

/** Charge a stored registration token (server-to-server MIT). Synchronous result. */
export async function chargeRegistration(
  registrationId: string,
  o: RegistrationChargeOptions,
  c: HyperPayConfig,
): Promise<HyperPayResult> {
  const url = `${c.base}/v1/registrations/${encodeURIComponent(registrationId)}/payments`;
  return await postForm(url, buildRegistrationChargeParams(o, c), c.authToken);
}

// ── Payment detail extraction (RRN, card scope) ─────────────────────────────

export interface PaymentDetails {
  uniqueId: string | null;               // OPPWA payment id
  merchantTransactionId: string | null;
  rrn: string | null;
  clearingInstituteName: string | null;
  cardScope: "local" | "international" | null;
  paymentBrand: string | null;
}

/**
 * Extract audit fields from a final OPPWA payment result.
 *
 * RRN: local connectors (ZainCash/PostBridge) carry it inside pipe-delimited
 * resultDetails.ConnectorTxID2 — but NOT at a fixed position (observed both
 * "STAN|RRN|…" and "STAN|connectorRef|RRN|…"), so take the first all-digit
 * 12-char field after the leading STAN. International MPGS puts it in
 * resultDetails["transaction.receipt"]. Never throws — absent fields ⇒ null.
 *
 * card_scope: a local-rail transaction is recognized by its ConnectorTxID2
 * RRN (only local connectors emit it) or a clearingInstituteName containing
 * "mada"; otherwise any non-empty clearingInstituteName (SAIB MPGS,
 * Switch MPGS) is international.
 */
export function extractPaymentDetails(result: HyperPayResult): PaymentDetails {
  const details = (result.resultDetails ?? {}) as Record<string, unknown>;
  const str = (v: unknown): string | null =>
    typeof v === "string" && v.trim() !== "" ? v : null;

  const ctx2 = str(details["ConnectorTxID2"]);
  const ctx2Fields = ctx2 ? ctx2.split("|").slice(1).map((f) => f.trim()) : [];
  const pipeRrn = ctx2Fields.find((f) => /^\d{12}$/.test(f)) ??
    ctx2Fields.find((f) => /^\d{6,}$/.test(f)) ?? null;
  const rrn = pipeRrn ?? str(details["transaction.receipt"]);

  const clearingInstituteName = str(details["clearingInstituteName"]);
  const cardScope: "local" | "international" | null =
    pipeRrn !== null || (clearingInstituteName ?? "").toLowerCase().includes("mada")
      ? "local"
      : clearingInstituteName !== null ? "international" : null;

  return {
    uniqueId: str(result.id),
    merchantTransactionId: str(result.merchantTransactionId),
    rrn,
    clearingInstituteName,
    cardScope,
    paymentBrand: str(result.paymentBrand),
  };
}

// ── Payment reversal (RV) ────────────────────────────────────────────────────
// Ported from the admin-dashboard repo, which has run this against the live
// acquirer. booking-action uses it to reverse HyperPay bookings.

/**
 * RV (reverse/void) request params for an original payment's unique id.
 * `entityIdOverride` lets the caller reverse on the recurring channel — an RV
 * must be sent to the SAME entity that captured the payment.
 */
export function buildReverseParams(
  c: Pick<HyperPayConfig, "entityId" | "env">,
  entityIdOverride?: string,
): Record<string, string> {
  // No testMode in either environment — see buildCheckoutParams.
  return {
    entityId: entityIdOverride || c.entityId,
    paymentType: "RV",
  };
}

/**
 * Reverse (void) a captured HyperPay payment by its original unique_id.
 *
 * The caller (booking-action) cannot tell a CIT checkout payment from an MIT
 * saved-card charge, and the two were captured on different entities. So: try
 * the checkout entity, and if that fails and a distinct recurring entity is
 * configured, retry there once. A successful RV never reaches the retry, and a
 * genuinely declined RV just declines twice — so the fallback cannot double-void.
 */
export async function reversePayment(
  uniqueId: string,
  c: HyperPayConfig,
): Promise<{ ok: boolean; code?: string; description?: string }> {
  const url = `${c.base}/v1/payments/${encodeURIComponent(uniqueId)}`;
  const attempt = async (entityId: string) => {
    const j = await postForm(url, buildReverseParams(c, entityId), c.authToken);
    const code = j.result?.code;
    return { ok: isPaymentSuccessful(code, c.env), code, description: j.result?.description };
  };

  const first = await attempt(c.entityId);
  if (first.ok || !c.recurringEntityId || c.recurringEntityId === c.entityId) {
    return first;
  }
  console.log(
    `hyperpay: RV on checkout entity failed (code=${first.code}); retrying on recurring entity uid=${uniqueId}`,
  );
  const second = await attempt(c.recurringEntityId);
  return second.ok ? second : first;
}

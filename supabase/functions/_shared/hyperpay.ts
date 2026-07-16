/**
 * _shared/hyperpay.ts — HyperPay (OPPWA COPYandPAY) gateway helpers.
 *
 * Ported from the working Python UAT integration (hyper-db-uat/app.py).
 *
 * Env vars required (Supabase Edge Function secrets):
 *   HYPERPAY_ENTITY_ID   — OPPWA entity id
 *   HYPERPAY_AUTH_TOKEN  — OPPWA Bearer token
 *   HYPERPAY_ENV         — "test" | "prod"  (default "test")
 *   HYPERPAY_BASE        — optional; defaults to eu-test/eu-prod.oppwa.com by env
 *
 * SUCCESS RULE (critical, per business requirement):
 *   test: any "successfully processed in test mode" code — 000.100.1xx
 *         (e.g. 000.100.110 integrator, 000.100.112 connector test mode)
 *   prod: only result.code === "000.000.000" is a successful payment
 *   Any other FINAL code is a failure; result.description is shown to the merchant.
 *
 * Code classes:
 *   pending   000.200.*            — shopper still completing (3DS challenge)
 *   transient 800.120.100 / 900.*  — rate limit / comms; never a final result
 */

export type HyperPayEnv = "test" | "prod";

export interface HyperPayConfig {
  entityId: string;
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

export function cfg(): HyperPayConfig {
  const entityId = Deno.env.get("HYPERPAY_ENTITY_ID");
  const authToken = Deno.env.get("HYPERPAY_AUTH_TOKEN");
  const env = (Deno.env.get("HYPERPAY_ENV") ?? "test") as HyperPayEnv;
  if (!entityId || !authToken) {
    throw new Error("HYPERPAY_ENTITY_ID / HYPERPAY_AUTH_TOKEN not configured");
  }
  const base = Deno.env.get("HYPERPAY_BASE") ??
    (env === "prod" ? "https://eu-prod.oppwa.com" : "https://eu-test.oppwa.com");
  return { entityId, authToken, env, base };
}

// ── Pure helpers (unit-tested in hyperpay_test.ts) ──────────────────────────

export const SUCCESS_CODE_PROD = "000.000.000";
/** "Request successfully processed in '…Test Mode'" — 000.100.110/111/112 etc. */
export const TEST_SUCCESS_RE = /^000\.100\.1\d{2}$/;

/**
 * Success rule per environment:
 *   prod — exact 000.000.000 (a real, live-processed payment)
 *   test — any 000.100.1xx "successfully processed in test mode" code
 */
export function isPaymentSuccessful(code: string | undefined | null, env: HyperPayEnv): boolean {
  if (!code) return false;
  return env === "prod" ? code === SUCCESS_CODE_PROD : TEST_SUCCESS_RE.test(code);
}

/** Shopper still completing the payment (e.g. inside the 3DS challenge). */
export function isPending(code: string | undefined | null): boolean {
  return !!code && code.startsWith("000.200");
}

/** Rate limit / communication errors — retry later, never a final result. */
export function isTransient(code: string | undefined | null): boolean {
  return code === "800.120.100" || (!!code && code.startsWith("900."));
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
  if (c.env === "test") params.testMode = "EXTERNAL";
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

/** Params for POST /v1/registrations/{id}/payments (merchant-initiated charge). */
export function buildRegistrationChargeParams(o: RegistrationChargeOptions, c: Pick<HyperPayConfig, "entityId" | "env">): Record<string, string> {
  const params: Record<string, string> = {
    entityId: c.entityId,
    amount: String(o.amount),
    currency: "IQD",
    paymentType: "DB",
    merchantTransactionId: o.merchantTransactionId,
    "standingInstruction.mode": "REPEATED",
    "standingInstruction.source": "MIT",
    "standingInstruction.type": "UNSCHEDULED",
  };
  // EXTERNAL to match buildCheckoutParams. This is a merchant-initiated (MIT)
  // charge on a stored token — exempt from the 3DS challenge, so it carries no
  // 3Dsimulator params.
  if (c.env === "test") params.testMode = "EXTERNAL";
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
 */
export async function getPaymentStatus(checkoutId: string, c: HyperPayConfig): Promise<HyperPayResult> {
  const url = `${c.base}/v1/checkouts/${encodeURIComponent(checkoutId)}/payment?entityId=${c.entityId}`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${c.authToken}` } });
  return await res.json() as HyperPayResult;
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
 * RRN: local connectors (ZainCash/PostBridge) encode it as the 2nd pipe field
 * of resultDetails.ConnectorTxID2 ("STAN|RRN|…"); international MPGS puts it
 * in resultDetails["transaction.receipt"]. Never throws — absent fields ⇒ null.
 *
 * card_scope: clearingInstituteName containing "mada" (any case) is a local
 * (Mada) transaction — covers test "MADA via INET PostBridge" and live
 * "Mada via Position"; any other non-empty name (SAIB MPGS, Switch MPGS) is
 * international.
 */
export function extractPaymentDetails(result: HyperPayResult): PaymentDetails {
  const details = (result.resultDetails ?? {}) as Record<string, unknown>;
  const str = (v: unknown): string | null =>
    typeof v === "string" && v.trim() !== "" ? v : null;

  const ctx2 = str(details["ConnectorTxID2"]);
  const pipeRrn = ctx2 ? (ctx2.split("|")[1]?.trim() || null) : null;
  const rrn = pipeRrn ?? str(details["transaction.receipt"]);

  const clearingInstituteName = str(details["clearingInstituteName"]);
  const cardScope = clearingInstituteName === null
    ? null
    : clearingInstituteName.toLowerCase().includes("mada") ? "local" : "international";

  return {
    uniqueId: str(result.id),
    merchantTransactionId: str(result.merchantTransactionId),
    rrn,
    clearingInstituteName,
    cardScope,
    paymentBrand: str(result.paymentBrand),
  };
}

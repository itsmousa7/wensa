/**
 * Unit tests for the pure helpers in _shared/hyperpay.ts.
 * Run: deno test --allow-env --allow-net=none _shared/hyperpay_test.ts
 */

import { assert, assertEquals, assertFalse, assertThrows } from "jsr:@std/assert";
import {
  assertBaseMatchesEnv,
  buildCheckoutParams,
  buildRegistrationChargeParams,
  buildReverseParams,
  DEFAULT_BASE_PROD,
  DEFAULT_BASE_TEST,
  envPrefix,
  extractPaymentDetails,
  isDuplicateMerchantTxnId,
  isPaid,
  isPaymentSuccessful,
  isPending,
  isTransient,
  normalizeEnv,
  readScoped,
} from "./hyperpay.ts";

// ── isPaymentSuccessful — success matrix ────────────────────────────────────
Deno.test("isPaymentSuccessful: whole 000.100.1xx test-mode family succeeds in test", () => {
  assert(isPaymentSuccessful("000.100.110", "test")); // integrator test mode
  assert(isPaymentSuccessful("000.100.112", "test")); // connector test mode
  assert(isPaymentSuccessful("000.100.111", "test"));
  // ...but a test-mode code is never a success in prod
  assertFalse(isPaymentSuccessful("000.100.110", "prod"));
  assertFalse(isPaymentSuccessful("000.100.112", "prod"));
});

Deno.test("isPaymentSuccessful: 000.000.000 succeeds in BOTH envs", () => {
  // A test entity can still answer with the live success code; the deployed
  // callers have always accepted it, and the shared helper now matches them.
  assert(isPaymentSuccessful("000.000.000", "prod"));
  assert(isPaymentSuccessful("000.000.000", "test"));
});

// ── env normalisation — "live" is what the deployments actually set ─────────
Deno.test("normalizeEnv: live/prod ⇒ prod, everything else ⇒ test", () => {
  assertEquals(normalizeEnv("live"), "prod");
  assertEquals(normalizeEnv("prod"), "prod");
  assertEquals(normalizeEnv("LIVE"), "prod");
  assertEquals(normalizeEnv(" Prod "), "prod");
  assertEquals(normalizeEnv("test"), "test");
  assertEquals(normalizeEnv("sandbox"), "test");
  assertEquals(normalizeEnv(undefined), "test");
  assertEquals(normalizeEnv(null), "test");
  assertEquals(normalizeEnv(""), "test");
});

Deno.test('isPaymentSuccessful: env="live" applies PROD rules, not test rules', () => {
  // Regression: HYPERPAY_ENV is set to "live" by create-booking/charge-saved-card.
  // A `as HyperPayEnv` cast used to make "live" fall through to TEST rules,
  // which would accept a test-mode code as a real payment in production.
  assertFalse(isPaymentSuccessful("000.100.110", "live"));
  assertFalse(isPaymentSuccessful("000.100.112", "live"));
  assert(isPaymentSuccessful("000.000.000", "live"));
});

Deno.test("isPaid: alias of isPaymentSuccessful — the one classifier both functions use", () => {
  assertEquals(isPaid, isPaymentSuccessful);
  assert(isPaid("000.100.110", "test"));
  assert(isPaid("000.000.000", "test"));
  assert(isPaid("000.000.000", "live"));
  assertFalse(isPaid("000.100.110", "live"));
  assertFalse(isPaid("800.100.156", "test"));
  assertFalse(isPaid("800.100.156", "live"));
});

Deno.test("isPaymentSuccessful: test-mode family is never a success in prod", () => {
  assertFalse(isPaymentSuccessful("000.100.110", "prod"));
  assertFalse(isPaymentSuccessful("000.100.112", "prod"));
});

Deno.test("isPaymentSuccessful: near-miss code is failure in either env", () => {
  assertFalse(isPaymentSuccessful("000.000.100", "test"));
  assertFalse(isPaymentSuccessful("000.000.100", "prod"));
  assertFalse(isPaymentSuccessful("000.100.200", "test")); // not a 000.100.1xx
});

Deno.test("isPaymentSuccessful: undefined/null/empty are failure", () => {
  assertFalse(isPaymentSuccessful(undefined, "test"));
  assertFalse(isPaymentSuccessful(null, "test"));
  assertFalse(isPaymentSuccessful("", "test"));
  assertFalse(isPaymentSuccessful(undefined, "prod"));
  assertFalse(isPaymentSuccessful(null, "prod"));
  assertFalse(isPaymentSuccessful("", "prod"));
});

// ── isPending — 000.200.* ───────────────────────────────────────────────────
Deno.test("isPending", () => {
  assert(isPending("000.200.000"));
  assert(isPending("000.200.100"));
  assertFalse(isPending("000.100.110"));
  assertFalse(isPending(undefined));
  assertFalse(isPending(null));
  assertFalse(isPending(""));
});

// ── isTransient — 800.120.100 or 900.* ──────────────────────────────────────
Deno.test("isTransient", () => {
  assert(isTransient("800.120.100"));
  assert(isTransient("900.100.300"));
  assertFalse(isTransient("800.100.100"));
  assertFalse(isTransient("000.200.000"));
  assertFalse(isTransient(undefined));
  assertFalse(isTransient(null));
  assertFalse(isTransient(""));
});

// ── isDuplicateMerchantTxnId — 200.300.404 on a MIT retry ───────────────────
Deno.test("isDuplicateMerchantTxnId", () => {
  assert(isDuplicateMerchantTxnId("200.300.404"));
  assertFalse(isDuplicateMerchantTxnId("800.100.156"));
  assertFalse(isDuplicateMerchantTxnId("000.200.000"));
  assertFalse(isDuplicateMerchantTxnId("900.100.300"));
  assertFalse(isDuplicateMerchantTxnId(undefined));
  assertFalse(isDuplicateMerchantTxnId(null));
  assertFalse(isDuplicateMerchantTxnId(""));
});

// ── REQUEST-BODY KEY SETS (the 800.100.156 guard) ───────────────────────────
// This acquirer answers 800.100.156 "transaction declined (format error)" to
// ANY deviation in the outgoing body — an extra key (customer.*/billing.*), a
// missing key, a renamed key. These assertions pin the EXACT key set of every
// request shape we send. If one fails, do not "fix" the expectation: the
// change to the builder is what is wrong.

const CHECKOUT_BASE = ["amount", "currency", "entityId", "integrity", "merchantTransactionId", "paymentType"];
const TOKENIZE_KEYS = [
  "createRegistration",
  "standingInstruction.mode",
  "standingInstruction.recurringType",
  "standingInstruction.source",
  "standingInstruction.type",
];

Deno.test("buildCheckoutParams: EXACT key set — test env, no tokenize", () => {
  const p = buildCheckoutParams(
    { amount: 25000, merchantTransactionId: "booking-abc", tokenize: false },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(Object.keys(p).sort(), [...CHECKOUT_BASE].sort());
});

Deno.test("buildCheckoutParams: EXACT key set — prod env, no tokenize", () => {
  const p = buildCheckoutParams(
    { amount: 25000, merchantTransactionId: "booking-abc", tokenize: false },
    { entityId: "ent1", env: "prod" },
  );
  assertEquals(Object.keys(p).sort(), [...CHECKOUT_BASE].sort());
});

Deno.test("buildCheckoutParams: EXACT key set — test env, tokenize", () => {
  const p = buildCheckoutParams(
    { amount: 25000, merchantTransactionId: "booking-abc", tokenize: true },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(
    Object.keys(p).sort(),
    [...CHECKOUT_BASE, ...TOKENIZE_KEYS].sort(),
  );
});

Deno.test("buildCheckoutParams: EXACT key set — prod env, tokenize (the live app shape)", () => {
  const p = buildCheckoutParams(
    { amount: 25000, merchantTransactionId: "booking-abc", tokenize: true },
    { entityId: "ent1", env: "prod" },
  );
  assertEquals(Object.keys(p).sort(), [...CHECKOUT_BASE, ...TOKENIZE_KEYS].sort());
});

Deno.test("buildCheckoutParams: merchantTransactionId is OMITTED, never sent empty", () => {
  const p = buildCheckoutParams({ amount: 1, tokenize: false }, { entityId: "ent1", env: "prod" });
  assertEquals(
    Object.keys(p).sort(),
    CHECKOUT_BASE.filter((k) => k !== "merchantTransactionId").sort(),
  );
  assertFalse("merchantTransactionId" in p);
});

Deno.test("buildCheckoutParams: no customer.*/billing.* key ever leaks in", () => {
  for (const env of ["test", "prod"] as const) {
    for (const tokenize of [false, true]) {
      const p = buildCheckoutParams(
        { amount: 1, merchantTransactionId: "m", tokenize },
        { entityId: "ent1", env },
      );
      for (const k of Object.keys(p)) {
        assertFalse(k.startsWith("customer."), `unexpected key ${k}`);
        assertFalse(k.startsWith("billing."), `unexpected key ${k}`);
        assertFalse(k.startsWith("3D"), `unexpected key ${k}`);
      }
    }
  }
});

const MIT_BASE = [
  "amount",
  "currency",
  "entityId",
  "merchantTransactionId",
  "paymentType",
  "standingInstruction.mode",
  "standingInstruction.source",
  "standingInstruction.type",
];

Deno.test("buildRegistrationChargeParams: EXACT key set — test env, with initialTransactionId", () => {
  const p = buildRegistrationChargeParams(
    { amount: 5000, merchantTransactionId: "mit-1", initialTransactionId: "init-123" },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(
    Object.keys(p).sort(),
    [...MIT_BASE, "standingInstruction.initialTransactionId"].sort(),
  );
});

Deno.test("buildRegistrationChargeParams: EXACT key set — prod env, no initialTransactionId", () => {
  const p = buildRegistrationChargeParams(
    { amount: 5000, merchantTransactionId: "mit-1" },
    { entityId: "ent1", env: "prod" },
  );
  assertEquals(Object.keys(p).sort(), [...MIT_BASE].sort());
});

// ── RECURRING CHANNEL ROUTING ───────────────────────────────────────────────
// HyperPay provisions a SEPARATE entity for merchant-initiated recurring
// charges. Every MIT charge must carry it; the checkout entity must never be
// substituted when a recurring entity is configured.

Deno.test("buildRegistrationChargeParams: MIT charge goes to the RECURRING entity", () => {
  const p = buildRegistrationChargeParams(
    { amount: 5000, merchantTransactionId: "mit-1" },
    { entityId: "checkout-ent", recurringEntityId: "recurring-ent", env: "prod" },
  );
  assertEquals(p.entityId, "recurring-ent");
  // routing must not disturb the pinned key set (800.100.156 guard)
  assertEquals(Object.keys(p).sort(), [...MIT_BASE].sort());
});

Deno.test("buildRegistrationChargeParams: falls back to entityId when no recurring entity", () => {
  for (const c of [
    { entityId: "checkout-ent", env: "test" as const },
    { entityId: "checkout-ent", recurringEntityId: "", env: "test" as const },
  ]) {
    const p = buildRegistrationChargeParams({ amount: 1, merchantTransactionId: "mit-1" }, c);
    assertEquals(p.entityId, "checkout-ent");
  }
});

Deno.test("buildCheckoutParams: the CHECKOUT entity is never the recurring one", () => {
  // The initial CIT checkout (even when it tokenizes) stays on the checkout
  // entity — only the later MIT charge moves to the recurring channel.
  const p = buildCheckoutParams(
    { amount: 1, merchantTransactionId: "booking-1", tokenize: true },
    { entityId: "checkout-ent", env: "prod" },
  );
  assertEquals(p.entityId, "checkout-ent");
});

Deno.test("buildReverseParams: RV honours the entity override (reverse where it was captured)", () => {
  assertEquals(buildReverseParams({ entityId: "checkout-ent", env: "prod" }).entityId, "checkout-ent");
  assertEquals(
    buildReverseParams({ entityId: "checkout-ent", env: "prod" }, "recurring-ent").entityId,
    "recurring-ent",
  );
  // an empty override must not blank the entityId
  assertEquals(buildReverseParams({ entityId: "checkout-ent", env: "prod" }, "").entityId, "checkout-ent");
});

// ── TEST/LIVE CREDENTIAL SELECTION ──────────────────────────────────────────
// HYPERPAY_ENV is the single switch: the scoped secret for the selected env
// wins, the legacy unscoped secret is the fallback.

const ENV_FIXTURE: Record<string, string> = {
  HYPERPAY_TEST_ENTITY_ID: "test-ent",
  HYPERPAY_TEST_AUTH_TOKEN: "test-tok",
  HYPERPAY_LIVE_ENTITY_ID: "live-ent",
  HYPERPAY_LIVE_AUTH_TOKEN: "live-tok",
  HYPERPAY_ENTITY_ID: "legacy-ent",
  HYPERPAY_AUTH_TOKEN: "legacy-tok",
};
const fake = (over: Record<string, string> = {}) => {
  const m = { ...ENV_FIXTURE, ...over };
  return (k: string) => m[k];
};

Deno.test("readScoped: live env reads HYPERPAY_LIVE_*, test env reads HYPERPAY_TEST_*", () => {
  assertEquals(readScoped("ENTITY_ID", "prod", fake()), "live-ent");
  assertEquals(readScoped("AUTH_TOKEN", "prod", fake()), "live-tok");
  assertEquals(readScoped("ENTITY_ID", "test", fake()), "test-ent");
  assertEquals(readScoped("AUTH_TOKEN", "test", fake()), "test-tok");
});

Deno.test("readScoped: falls back to the legacy unscoped secret", () => {
  const only = (k: string) => ({ HYPERPAY_ENTITY_ID: "legacy-ent" } as Record<string, string>)[k];
  assertEquals(readScoped("ENTITY_ID", "prod", only), "legacy-ent");
  assertEquals(readScoped("ENTITY_ID", "test", only), "legacy-ent");
  assertEquals(readScoped("AUTH_TOKEN", "test", only), undefined);
});

Deno.test("readScoped: a blank scoped secret does NOT shadow the fallback", () => {
  // An entityId of "" would be sent to the acquirer verbatim — 800.100.156.
  assertEquals(readScoped("ENTITY_ID", "prod", fake({ HYPERPAY_LIVE_ENTITY_ID: "   " })), "legacy-ent");
  assertEquals(readScoped("ENTITY_ID", "prod", fake({ HYPERPAY_LIVE_ENTITY_ID: "" })), "legacy-ent");
  // and values are trimmed, never passed through with whitespace
  assertEquals(readScoped("ENTITY_ID", "prod", fake({ HYPERPAY_LIVE_ENTITY_ID: " live-ent \n" })), "live-ent");
});

Deno.test("readScoped: unset everywhere ⇒ undefined", () => {
  assertEquals(readScoped("RECURRING_ENTITY_ID", "prod", () => undefined), undefined);
});

Deno.test("envPrefix maps the normalised env to its secret prefix", () => {
  assertEquals(envPrefix("prod"), "HYPERPAY_LIVE_");
  assertEquals(envPrefix("test"), "HYPERPAY_TEST_");
  assertEquals(envPrefix(normalizeEnv("live")), "HYPERPAY_LIVE_");
});

Deno.test("assertBaseMatchesEnv: a stale test host under live env throws (and vice versa)", () => {
  // The exact cutover trap: an unscoped HYPERPAY_BASE left pinned to eu-test
  // would silently route LIVE money to the test host.
  assertThrows(() => assertBaseMatchesEnv("https://eu-test.oppwa.com", "prod"));
  assertThrows(() => assertBaseMatchesEnv("https://eu-prod.oppwa.com", "test"));
  assertBaseMatchesEnv(DEFAULT_BASE_PROD, "prod");
  assertBaseMatchesEnv(DEFAULT_BASE_TEST, "test");
  // a non-oppwa proxy host is not second-guessed
  assertBaseMatchesEnv("https://gateway.example.com", "prod");
});

// ── merchantTransactionId invariants ────────────────────────────────────────
// Both construction sites must produce ≤32 chars with NO underscore — either
// violation is answered with 800.100.156.
function assertValidMerchantTxnId(id: string) {
  assert(id.length <= 32, `merchantTransactionId too long (${id.length}): ${id}`);
  assertFalse(id.includes("_"), `merchantTransactionId contains "_": ${id}`);
  assert(id.length > 0, "merchantTransactionId is empty");
}

/** create-booking/index.ts formula. */
function bookingMerchantTxnId(id: string, isGroup: boolean): string {
  return (isGroup ? `booking-venue-${id}` : `booking-${id}`).slice(0, 32);
}

/** charge-saved-card/index.ts formula. */
function mitMerchantTxnId(): string {
  return `mit-${crypto.randomUUID().replace(/-/g, "").slice(0, 28)}`;
}

Deno.test("merchantTransactionId: create-booking formula stays ≤32 and underscore-free", () => {
  const uuid = "3f9a1c2e-4b5d-6e7f-8a9b-0c1d2e3f4a5b";
  assertValidMerchantTxnId(bookingMerchantTxnId(uuid, false));
  assertValidMerchantTxnId(bookingMerchantTxnId(uuid, true));
  // a pathological id must still be truncated, not passed through
  assertValidMerchantTxnId(bookingMerchantTxnId("x".repeat(200), true));
  assertEquals(bookingMerchantTxnId(uuid, false).length, 32);
  // underscores must never be introduced by the prefix itself
  assertEquals(bookingMerchantTxnId("abc", false), "booking-abc");
  assertEquals(bookingMerchantTxnId("abc", true), "booking-venue-abc");
});

Deno.test("merchantTransactionId: charge-saved-card MIT formula stays ≤32 and underscore-free", () => {
  for (let i = 0; i < 200; i++) {
    const id = mitMerchantTxnId();
    assertValidMerchantTxnId(id);
    assertEquals(id.length, 32);
    assert(id.startsWith("mit-"));
  }
});

Deno.test("merchantTransactionId: a valid id survives buildCheckoutParams/buildRegistrationChargeParams unchanged", () => {
  const id = bookingMerchantTxnId("3f9a1c2e-4b5d-6e7f-8a9b-0c1d2e3f4a5b", false);
  const c = buildCheckoutParams({ amount: 1, merchantTransactionId: id, tokenize: true }, { entityId: "e", env: "prod" });
  assertEquals(c.merchantTransactionId, id);
  assertValidMerchantTxnId(c.merchantTransactionId);
  const m = buildRegistrationChargeParams({ amount: 1, merchantTransactionId: id }, { entityId: "e", env: "prod" });
  assertEquals(m.merchantTransactionId, id);
  assertValidMerchantTxnId(m.merchantTransactionId);
});

// ── buildCheckoutParams ─────────────────────────────────────────────────────
Deno.test("buildCheckoutParams: base body, no tokenize", () => {
  const p = buildCheckoutParams(
    { amount: 25000, merchantTransactionId: "tx1", tokenize: false },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(p.entityId, "ent1");
  assertEquals(p.amount, "25000");
  assertEquals(p.currency, "IQD");
  assertEquals(p.paymentType, "DB");
  assertEquals(p.integrity, "true");
  assertEquals(p.merchantTransactionId, "tx1");
  // non-tokenize omits registration/CIT
  assertEquals(p.createRegistration, undefined);
  assertEquals(p["standingInstruction.mode"], undefined);
  assertEquals(p["standingInstruction.source"], undefined);
  assertEquals(p["standingInstruction.type"], undefined);
});

// ── testMode is GONE from every request shape ───────────────────────────────
// It used to be sent as EXTERNAL in the test env. Now no builder emits it in
// either environment, so the outgoing body is byte-identical between test and
// live and the live cutover cannot change the request shape.
Deno.test("testMode is never sent — any builder, either env", () => {
  const bodies = [
    buildCheckoutParams({ amount: 1, merchantTransactionId: "tx", tokenize: false }, { entityId: "e", env: "test" }),
    buildCheckoutParams({ amount: 1, merchantTransactionId: "tx", tokenize: false }, { entityId: "e", env: "prod" }),
    buildCheckoutParams({ amount: 1, merchantTransactionId: "tx", tokenize: true }, { entityId: "e", env: "test" }),
    buildCheckoutParams({ amount: 1, merchantTransactionId: "tx", tokenize: true }, { entityId: "e", env: "prod" }),
    buildRegistrationChargeParams({ amount: 1, merchantTransactionId: "m" }, { entityId: "e", env: "test" }),
    buildRegistrationChargeParams({ amount: 1, merchantTransactionId: "m" }, { entityId: "e", env: "prod" }),
    buildReverseParams({ entityId: "e", env: "test" }),
    buildReverseParams({ entityId: "e", env: "prod" }),
  ];
  for (const b of bodies) {
    assertFalse("testMode" in b, `testMode leaked back in: ${JSON.stringify(b)}`);
  }
});

Deno.test("test and prod bodies are IDENTICAL for every builder", () => {
  for (const tokenize of [false, true]) {
    assertEquals(
      buildCheckoutParams({ amount: 1, merchantTransactionId: "tx", tokenize }, { entityId: "e", env: "test" }),
      buildCheckoutParams({ amount: 1, merchantTransactionId: "tx", tokenize }, { entityId: "e", env: "prod" }),
    );
  }
  assertEquals(
    buildRegistrationChargeParams({ amount: 1, merchantTransactionId: "m" }, { entityId: "e", env: "test" }),
    buildRegistrationChargeParams({ amount: 1, merchantTransactionId: "m" }, { entityId: "e", env: "prod" }),
  );
  assertEquals(
    buildReverseParams({ entityId: "e", env: "test" }),
    buildReverseParams({ entityId: "e", env: "prod" }),
  );
});

Deno.test("buildCheckoutParams: tokenize adds createRegistration + CIT trio", () => {
  const p = buildCheckoutParams(
    { amount: 100, merchantTransactionId: "tx3", tokenize: true },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(p.createRegistration, "true");
  assertEquals(p["standingInstruction.mode"], "INITIAL");
  assertEquals(p["standingInstruction.source"], "CIT");
  assertEquals(p["standingInstruction.type"], "UNSCHEDULED");
});

Deno.test("buildCheckoutParams: amount stringified for float and zero", () => {
  const p = buildCheckoutParams(
    { amount: 0, merchantTransactionId: "tx4", tokenize: false },
    { entityId: "ent1", env: "prod" },
  );
  assertEquals(p.amount, "0");
  assertEquals(typeof p.amount, "string");
});

// ── buildRegistrationChargeParams ───────────────────────────────────────────
Deno.test("buildRegistrationChargeParams: MIT trio always present", () => {
  const p = buildRegistrationChargeParams(
    { amount: 5000, merchantTransactionId: "mit1" },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(p["standingInstruction.mode"], "REPEATED");
  assertEquals(p["standingInstruction.source"], "MIT");
  assertEquals(p["standingInstruction.type"], "UNSCHEDULED");
  assertEquals(p.entityId, "ent1");
  assertEquals(p.amount, "5000");
  assertEquals(p.currency, "IQD");
  assertEquals(p.paymentType, "DB");
  assertEquals(p.merchantTransactionId, "mit1");
});

Deno.test("buildRegistrationChargeParams: initialTransactionId only when provided", () => {
  const withIt = buildRegistrationChargeParams(
    { amount: 5000, merchantTransactionId: "mit4", initialTransactionId: "init-123" },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(withIt["standingInstruction.initialTransactionId"], "init-123");

  const withoutIt = buildRegistrationChargeParams(
    { amount: 5000, merchantTransactionId: "mit5" },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(withoutIt["standingInstruction.initialTransactionId"], undefined);

  const nullIt = buildRegistrationChargeParams(
    { amount: 5000, merchantTransactionId: "mit6", initialTransactionId: null },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(nullIt["standingInstruction.initialTransactionId"], undefined);
});

// ── extractPaymentDetails ───────────────────────────────────────────────────
Deno.test("extractPaymentDetails: RRN from ConnectorTxID2 pipe format (local connector)", () => {
  const d = extractPaymentDetails({
    id: "8ac7a49f9d8",
    merchantTransactionId: "booking_abc_123",
    paymentBrand: "MADA",
    resultDetails: {
      ConnectorTxID2: "947075|154307080753|619457986427||",
      clearingInstituteName: "MADA via INET PostBridge",
    },
  } as never);
  assertEquals(d.rrn, "154307080753");
  assertEquals(d.uniqueId, "8ac7a49f9d8");
  assertEquals(d.merchantTransactionId, "booking_abc_123");
  assertEquals(d.cardScope, "local");
  assertEquals(d.clearingInstituteName, "MADA via INET PostBridge");
  assertEquals(d.paymentBrand, "MADA");
});

Deno.test("extractPaymentDetails: RRN falls back to transaction.receipt (international)", () => {
  const d = extractPaymentDetails({
    id: "x1",
    resultDetails: {
      "transaction.receipt": "619457986427",
      clearingInstituteName: "SAIB MPGS",
    },
  } as never);
  assertEquals(d.rrn, "619457986427");
  assertEquals(d.cardScope, "international");
});

Deno.test("extractPaymentDetails: ConnectorTxID2 RRN position varies — skip non-numeric connector refs", () => {
  // Observed MADA via INET PostBridge shape: STAN|connectorRef|RRN|| — the
  // 12-digit RRN (matches the BIP reconciliationId) sits in the 3rd field.
  const d = extractPaymentDetails({
    resultDetails: { ConnectorTxID2: "403517|86a37f8776a8|139903327171||" },
  } as never);
  assertEquals(d.rrn, "139903327171");
  assertEquals(d.cardScope, "local");
});

Deno.test("extractPaymentDetails: ConnectorTxID2 RRN alone marks the transaction local", () => {
  // Local rails (ZainCash/PostBridge) always emit the pipe-format RRN; the
  // clearing institute name is not required — nor guaranteed to say "mada".
  const d = extractPaymentDetails({
    resultDetails: { ConnectorTxID2: "396119|142048794721|749381839811||" },
  } as never);
  assertEquals(d.rrn, "142048794721");
  assertEquals(d.cardScope, "local");
});

Deno.test("extractPaymentDetails: live names — Mada via Position local, Switch MPGS international", () => {
  const local = extractPaymentDetails({ resultDetails: { clearingInstituteName: "Mada via Position" } } as never);
  assertEquals(local.cardScope, "local");
  const intl = extractPaymentDetails({ resultDetails: { clearingInstituteName: "Switch MPGS" } } as never);
  assertEquals(intl.cardScope, "international");
});

Deno.test("extractPaymentDetails: single-field ConnectorTxID2 does not yield RRN from it", () => {
  const d = extractPaymentDetails({
    resultDetails: { ConnectorTxID2: "just-one-value", "transaction.receipt": "R123" },
  } as never);
  assertEquals(d.rrn, "R123");
});

Deno.test("extractPaymentDetails: empty pipe field falls back to receipt", () => {
  const d = extractPaymentDetails({
    resultDetails: { ConnectorTxID2: "947075||x", "transaction.receipt": "R999" },
  } as never);
  assertEquals(d.rrn, "R999");
});

Deno.test("extractPaymentDetails: missing resultDetails ⇒ all nulls except top-level ids", () => {
  const d = extractPaymentDetails({ id: "u1", merchantTransactionId: "m1" } as never);
  assertEquals(d.uniqueId, "u1");
  assertEquals(d.merchantTransactionId, "m1");
  assertEquals(d.rrn, null);
  assertEquals(d.clearingInstituteName, null);
  assertEquals(d.cardScope, null);
  assertEquals(d.paymentBrand, null);
});

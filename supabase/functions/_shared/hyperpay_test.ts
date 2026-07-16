/**
 * Unit tests for the pure helpers in _shared/hyperpay.ts.
 * Run: deno test --allow-env --allow-net=none _shared/hyperpay_test.ts
 */

import { assert, assertEquals, assertFalse } from "jsr:@std/assert";
import {
  buildCheckoutParams,
  buildRegistrationChargeParams,
  extractPaymentDetails,
  isPaymentSuccessful,
  isPending,
  isTransient,
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

Deno.test("isPaymentSuccessful: prod-env success code only in prod env", () => {
  assert(isPaymentSuccessful("000.000.000", "prod"));
  assertFalse(isPaymentSuccessful("000.000.000", "test"));
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

// ── buildCheckoutParams ─────────────────────────────────────────────────────
Deno.test("buildCheckoutParams: test env sets testMode=EXTERNAL", () => {
  const p = buildCheckoutParams(
    { amount: 25000, merchantTransactionId: "tx1", tokenize: false },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(p.testMode, "EXTERNAL");
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

Deno.test("buildCheckoutParams: prod env omits testMode", () => {
  const p = buildCheckoutParams(
    { amount: 100, merchantTransactionId: "tx2", tokenize: false },
    { entityId: "ent1", env: "prod" },
  );
  assertEquals(p.testMode, undefined);
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

Deno.test("buildRegistrationChargeParams: testMode only in test env", () => {
  const t = buildRegistrationChargeParams(
    { amount: 5000, merchantTransactionId: "mit2" },
    { entityId: "ent1", env: "test" },
  );
  assertEquals(t.testMode, "EXTERNAL");
  const pr = buildRegistrationChargeParams(
    { amount: 5000, merchantTransactionId: "mit3" },
    { entityId: "ent1", env: "prod" },
  );
  assertEquals(pr.testMode, undefined);
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

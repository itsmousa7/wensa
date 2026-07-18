/**
 * _shared/payment_flow.ts — pieces shared by verify-payment and
 * charge-saved-card (the two functions that finalise a HyperPay payment and
 * confirm the underlying booking/membership).
 *
 * Extracted verbatim from the two functions, which had drifted into
 * near-duplicate copies of all of it. The success classifier lives in
 * _shared/hyperpay.ts (`isPaid`) — do NOT re-implement it here.
 */

import type { PaymentTxRow } from "./payments.ts";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

export function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Extract the `sub` claim (user id) from a bearer JWT without verifying it.
 *  Safe here: the JWT is verified by the platform before the function runs. */
export function jwtSub(jwt: string): string | null {
  try {
    const b64 = jwt.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    return (JSON.parse(atob(b64)) as { sub?: string }).sub ?? null;
  } catch {
    return null;
  }
}

/** PostgREST headers for service-role reads/writes. */
export function serviceHeaders(serviceKey: string): Record<string, string> {
  return {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    Accept: "application/json",
    "Content-Type": "application/json",
  };
}

export interface ConfirmRpc { fn: string; idParam: string }

export const RPC_BY_KIND: Record<string, ConfirmRpc> = {
  booking:       { fn: "confirm_payment",               idParam: "p_booking_id" },
  concert_group: { fn: "confirm_concert_group_payment", idParam: "p_group_id" },
  membership:    { fn: "confirm_membership_payment",    idParam: "p_membership_id" },
};

/** Run the kind-appropriate confirm RPC AS THE CALLER (forwards their JWT so
 *  auth.uid() inside the SECURITY DEFINER function scopes the update). */
export async function confirmViaRpc(
  supabaseUrl: string,
  anonKey: string,
  authHeader: string,
  rpc: ConfirmRpc,
  id: string,
  referenceId: string,
): Promise<{ ok: boolean; status: number; errText: string }> {
  const rpcRes = await fetch(`${supabaseUrl}/rest/v1/rpc/${rpc.fn}`, {
    method: "POST",
    headers: {
      "Authorization": authHeader,
      "apikey":        anonKey,
      "Content-Type":  "application/json",
    },
    body: JSON.stringify({ [rpc.idParam]: id, p_payment_id: referenceId }),
  });
  return {
    ok: rpcRes.ok,
    status: rpcRes.status,
    errText: rpcRes.ok ? "" : await rpcRes.text().catch(() => ""),
  };
}

/** The id column a persisted payment row targets, whatever its kind. */
export function rowEntityId(row: Partial<PaymentTxRow>): string | null {
  return row.booking_id ?? row.group_id ?? row.membership_id ?? null;
}

export interface BuildTxRowArgs {
  kind: string;                 // "booking" | "concert_group" | "membership"
  id: string;                   // booking_id | group_id | membership_id
  referenceId: string;
  userId: string | null;
  amountIqd: number | null;
  paid: boolean;
  code: string;
  description: string;
  details: {
    uniqueId: string | null;
    merchantTransactionId: string | null;
    rrn: string | null;
    clearingInstituteName: string | null;
    cardScope: "local" | "international" | null;
    paymentBrand: string | null;
  };
  checkoutId: string;
  /** MIT charges carry no OPPWA merchantTransactionId echo — fall back to ours. */
  fallbackMerchantTransactionId?: string | null;
}

/** Single place that shapes a bookings.payment_transactions row. */
export function buildPaymentTxRow(a: BuildTxRowArgs): PaymentTxRow {
  return {
    intent: a.kind === "membership" ? "membership" : "booking",
    reference_id: a.referenceId,
    booking_id: a.kind === "booking" ? a.id : null,
    group_id: a.kind === "concert_group" ? a.id : null,
    membership_id: a.kind === "membership" ? a.id : null,
    user_id: a.userId,
    amount_iqd: a.amountIqd,
    status: a.paid ? "success" : "failed",
    result_code: a.code,
    result_description: a.description.slice(0, 300),
    unique_id: a.details.uniqueId,
    merchant_transaction_id:
      a.details.merchantTransactionId ?? a.fallbackMerchantTransactionId ?? null,
    rrn: a.details.rrn,
    clearing_institute_name: a.details.clearingInstituteName,
    card_scope: a.details.cardScope,
    payment_brand: a.details.paymentBrand,
    checkout_id: a.checkoutId,
  };
}

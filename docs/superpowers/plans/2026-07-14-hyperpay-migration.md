# HyperPay Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Wayl payment gateway with HyperPay (native SDK v7.11, custom card UI) for bookings and memberships, per `docs/superpowers/specs/2026-07-14-hyperpay-migration-design.md`.

**Architecture:** Server creates HyperPay checkout IDs in `create-booking` (credentials already in Supabase secrets). A Wensa-styled Flutter card form submits via `MethodChannel('app.wensa.mobile/hyperpay')` to native SDK code (Kotlin port of the demo on Android; brand-new Swift on iOS). 3DS challenges open in a native WebView that intercepts the `wensa://payment-result` shopper redirect. A new `verify-payment` edge function checks the payment server-side and confirms the booking via existing RPCs.

**Tech Stack:** Flutter/Riverpod (freezed + riverpod_annotation codegen), Supabase Edge Functions (Deno), HyperPay mSDK 7.11 (`oppwa.mobile.aar` + `ipworks3ds_sdk.aar` Android; `OPPWAMobile.xcframework` + `ipworks3ds_sdk.xcframework` iOS via a local CocoaPods podspec).

## Global Constraints

- Branch: all work on `feature/hyperpay-migration`; never commit to `main`.
- Payment brands: **VISA and MASTER only** — no Mada, STC Pay, Apple Pay, tokenization, or Ready UI.
- Channel name: `app.wensa.mobile/hyperpay`; single method `submitCardPayment`.
- Shopper result URL: `wensa://payment-result` (the `wensa` scheme is already registered on both platforms).
- Supabase secrets (already set — use these exact names): `HYPERPAY_BASE`, `HYPERPAY_ENTITY_ID`, `HYPERPAY_AUTH_TOKEN`, `HYPERPAY_ENV` (`"test"` or `"live"`).
- Currency: IQD; amounts sent to HyperPay as strings with 2 decimals (`finalIqd.toFixed(2)`).
- Android: `minSdk = maxOf(flutter.minSdkVersion, 24)`; SDK AARs in `android/app/libs/`; MainActivity becomes `FlutterFragmentActivity`.
- iOS: frameworks vendored via local pod `HyperpaySDK`; all new Swift code lives in the existing `ios/Runner/SceneDelegate.swift` (adding new .swift files requires pbxproj edits — avoid).
- HyperPay success result codes: `/^(000\.000\.|000\.100\.1)/`; manual-review codes `/^(000\.400\.0[^3]|000\.400\.100)/` also count as paid.
- Old Wayl **display** references (e.g. `wayl_code` on historical tickets in `bookings_history`) stay; only payment-initiation code is removed.
- SDK sources: `/Users/mousaalhamad/Downloads/SDK v7.11/Android_Frameworks_7.11.0/` and `/Users/mousaalhamad/Downloads/SDK v7.11/iOS_Frameworks_7.11.0/`.
- After any change to `@freezed`/`@riverpod` files run: `dart run build_runner build --delete-conflicting-outputs`.
- Verification gates: `flutter analyze` clean, `flutter test` green, `deno check` on touched edge functions.

---

### Task 1: `create-booking` — create HyperPay checkout instead of Wayl link

**Files:**
- Modify: `supabase/functions/create-booking/index.ts` (Wayl block ≈ lines 322–361, env block ≈ lines 94–101, response ≈ lines 435–444, header comment lines 1–24)

**Interfaces:**
- Produces (JSON response consumed by Task 6's submit providers):
  `{ booking_id?, group_id?, checkout_id: string, payment_mode: "TEST"|"LIVE", hold_until, reference_id, amount_iqd, original_amount_iqd, discount_amount_iqd }`
- The free-path response (`free: true`) is unchanged.

- [ ] **Step 1: Replace env vars.** In the `Deno.serve` handler, replace the four `WAYL_*` and `APP_DEEP_LINK` consts with:

```ts
  const HYPERPAY_BASE       = Deno.env.get("HYPERPAY_BASE") ?? "https://eu-test.oppwa.com";
  const HYPERPAY_ENTITY_ID  = Deno.env.get("HYPERPAY_ENTITY_ID")!;
  const HYPERPAY_AUTH_TOKEN = Deno.env.get("HYPERPAY_AUTH_TOKEN")!;
  const HYPERPAY_ENV        = Deno.env.get("HYPERPAY_ENV") ?? "test";
```

Also delete the top-level `const WAYL_BASE = "https://api.thewayl.com";` and update the file-header comment (flow step 5, env-vars list) to mention HyperPay instead of Wayl.

- [ ] **Step 2: Replace the Wayl link-creation block.** Delete everything from the comment `// ── Create Wayl payment link for the FINAL amount ──` through `const waylCode = waylJson.data.code;` (the `redirectBase`/`redirectSep`/`redirectUrl` lines included — the SDK flow has no redirect URL). Insert:

```ts
    // ── Create HyperPay checkout for the FINAL amount ───────────────────────
    // The app submits the card via the native mSDK using this checkout ID.
    // merchantTransactionId carries our referenceId for reconciliation.
    const checkoutBody = new URLSearchParams({
      entityId:              HYPERPAY_ENTITY_ID,
      amount:                finalIqd.toFixed(2),
      currency:              "IQD",
      paymentType:           "DB",
      merchantTransactionId: referenceId,
      ...(HYPERPAY_ENV !== "live" ? { testMode: "EXTERNAL" } : {}),
    });

    const hpRes = await fetch(`${HYPERPAY_BASE}/v1/checkouts`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${HYPERPAY_AUTH_TOKEN}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: checkoutBody.toString(),
    });

    const hpJson = await hpRes.json().catch(() => ({})) as
      { id?: string; result?: { code?: string; description?: string } };

    if (!hpRes.ok || !hpJson.id) {
      throw new Error(
        `HyperPay checkout error ${hpRes.status}: ${JSON.stringify(hpJson.result ?? hpJson)}`,
      );
    }

    const checkoutId  = hpJson.id;
    const paymentMode = HYPERPAY_ENV === "live" ? "LIVE" : "TEST";
```

- [ ] **Step 3: Update persistence + response.** In the two booking PATCH bodies, delete the `...(waylCode ? { wayl_code: waylCode } : {}),` lines (the column stays for historical rows; new rows just don't set it). Replace the final `return json({...})` payment fields:

```ts
    return json({
      booking_id:  !isGroup ? rpcResult.id : undefined,
      group_id:    isGroup  ? rpcResult.group_id : undefined,
      checkout_id:  checkoutId,
      payment_mode: paymentMode,
      hold_until:  rpcResult.hold_until ?? rpcResult.expires_at,
      reference_id: referenceId,
      amount_iqd:          finalIqd,
      original_amount_iqd: subtotalIqd,
      discount_amount_iqd: discountAmount,
    }, 200);
```

- [ ] **Step 4: Verify remaining Wayl references are gone and types check.**

Run: `grep -n -i "wayl" supabase/functions/create-booking/index.ts`
Expected: no matches (or only in comments you then remove).
Run: `deno check supabase/functions/create-booking/index.ts`
Expected: exits 0. (If `deno` is missing, `npx deno check …` or note it and rely on review.)

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/create-booking/index.ts
git commit -m "feat(payments): create-booking issues HyperPay checkout instead of Wayl link"
```

---

### Task 2: New `verify-payment` edge function

**Files:**
- Create: `supabase/functions/verify-payment/index.ts`

**Interfaces:**
- Consumes: HyperPay `GET /v1/checkouts/{id}/payment`; existing RPCs `public.confirm_payment(p_booking_id, p_payment_id)`, `public.confirm_concert_group_payment(p_group_id, p_payment_id)`, `public.confirm_membership_payment(p_membership_id, p_payment_id)` — all SECURITY DEFINER, scoped to `auth.uid()`, idempotent.
- Produces (consumed by Task 4's Dart verify service): POST body `{ checkout_id: string, kind: "booking"|"concert_group"|"membership", id: string, reference_id: string }` → `{ paid: boolean, code: string, description: string }`.

- [ ] **Step 1: Write the function.** Full contents of `supabase/functions/verify-payment/index.ts`:

```ts
/**
 * verify-payment — server-side HyperPay payment verification + booking confirm.
 *
 * The app calls this after the native mSDK reports success/SYNC. We check the
 * payment status with HyperPay using server-held credentials, and only if the
 * result code is a success do we flip the booking/membership to confirmed via
 * the existing SECURITY DEFINER RPCs (which are scoped to the caller's uid and
 * idempotent). Rows that never get verified stay pending and are swept by the
 * existing expiry crons.
 *
 * Request (POST, user JWT required):
 *   { checkout_id: string,
 *     kind: "booking" | "concert_group" | "membership",
 *     id: string,              // booking_id | group_id | membership_id
 *     reference_id: string }   // stored into payment_id on confirm
 *
 * Response: { paid: boolean, code: string, description: string }
 *
 * Env: SUPABASE_URL, SUPABASE_ANON_KEY,
 *      HYPERPAY_BASE, HYPERPAY_ENTITY_ID, HYPERPAY_AUTH_TOKEN
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// deno-lint-ignore no-control-regex
const SUCCESS_CODE = /^(000\.000\.|000\.100\.1)/;
const MANUAL_REVIEW_CODE = /^(000\.400\.0[^3]|000\.400\.100)/;

const RPC_BY_KIND: Record<string, { fn: string; idParam: string }> = {
  booking:       { fn: "confirm_payment",               idParam: "p_booking_id" },
  concert_group: { fn: "confirm_concert_group_payment", idParam: "p_group_id" },
  membership:    { fn: "confirm_membership_payment",    idParam: "p_membership_id" },
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const SUPABASE_URL        = Deno.env.get("SUPABASE_URL")!;
  const ANON_KEY            = Deno.env.get("SUPABASE_ANON_KEY")!;
  const HYPERPAY_BASE       = Deno.env.get("HYPERPAY_BASE") ?? "https://eu-test.oppwa.com";
  const HYPERPAY_ENTITY_ID  = Deno.env.get("HYPERPAY_ENTITY_ID")!;
  const HYPERPAY_AUTH_TOKEN = Deno.env.get("HYPERPAY_AUTH_TOKEN")!;

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return json({ error: "Missing authorization" }, 401);
    }

    const body = await req.json().catch(() => null) as {
      checkout_id?: string; kind?: string; id?: string; reference_id?: string;
    } | null;

    const rpc = body?.kind ? RPC_BY_KIND[body.kind] : undefined;
    if (!body?.checkout_id || !body?.id || !body?.reference_id || !rpc) {
      return json({ error: "checkout_id, kind, id, reference_id required" }, 400);
    }

    // ── 1. Ask HyperPay for the payment status ──────────────────────────────
    const statusRes = await fetch(
      `${HYPERPAY_BASE}/v1/checkouts/${encodeURIComponent(body.checkout_id)}` +
        `/payment?entityId=${encodeURIComponent(HYPERPAY_ENTITY_ID)}`,
      { headers: { Authorization: `Bearer ${HYPERPAY_AUTH_TOKEN}` } },
    );

    const statusJson = await statusRes.json().catch(() => ({})) as {
      result?: { code?: string; description?: string };
    };
    const code        = statusJson.result?.code ?? "unknown";
    const description = statusJson.result?.description ?? `HTTP ${statusRes.status}`;

    const paid = SUCCESS_CODE.test(code) || MANUAL_REVIEW_CODE.test(code);
    if (!paid) {
      // Not an error: the row stays pending; expiry crons clean it up.
      return json({ paid: false, code, description }, 200);
    }

    // ── 2. Confirm via the existing user-scoped RPC ─────────────────────────
    // Forward the caller's JWT so auth.uid() inside the RPC scopes the update.
    const rpcRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${rpc.fn}`, {
      method: "POST",
      headers: {
        "Authorization": authHeader,
        "apikey":        ANON_KEY,
        "Content-Type":  "application/json",
      },
      body: JSON.stringify({
        [rpc.idParam]: body.id,
        p_payment_id:  body.reference_id,
      }),
    });

    if (!rpcRes.ok) {
      const errText = await rpcRes.text().catch(() => "");
      console.error(`verify-payment: ${rpc.fn} failed ${rpcRes.status}: ${errText}`);
      return json({ error: `Payment verified but confirm failed (${rpcRes.status})` }, 500);
    }

    return json({ paid: true, code, description }, 200);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Internal server error";
    console.error("verify-payment error:", msg);
    return json({ error: msg }, 500);
  }
});
```

- [ ] **Step 2: Type-check.**

Run: `deno check supabase/functions/verify-payment/index.ts`
Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/verify-payment/index.ts
git commit -m "feat(payments): add verify-payment edge function (HyperPay status + confirm RPCs)"
```

> **Deployment note (do not run without asking the user):** functions deploy with `supabase functions deploy create-booking` / `supabase functions deploy verify-payment`. Deployment is a user-gated step in Task 9.

---

### Task 3: Card validators (pure Dart, TDD)

**Files:**
- Create: `lib/features/hyperpay_payment/domain/card_validators.dart`
- Test: `test/features/hyperpay_payment/card_validators_test.dart`

**Interfaces:**
- Produces (used by Tasks 4 & 5):
  - `String? detectBrand(String digits)` → `"VISA"` | `"MASTER"` | `null`
  - `bool luhnCheck(String digits)`
  - `bool isValidExpiry(String mm, String yy)` — MM 01–12, 2-digit year, not in the past (month granularity, local time)
  - `String normalizeYear(String yy)` → `"20$yy"` when 2 digits, else unchanged
  - `bool isValidCvv(String cvv)` — 3 digits

- [ ] **Step 1: Write the failing tests.** Full contents of `test/features/hyperpay_payment/card_validators_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/hyperpay_payment/domain/card_validators.dart';

void main() {
  group('detectBrand', () {
    test('4-prefix is VISA', () => expect(detectBrand('4111111111111111'), 'VISA'));
    test('5-prefix is MASTER', () => expect(detectBrand('5454545454545454'), 'MASTER'));
    test('2-series Mastercard is MASTER', () => expect(detectBrand('2221000000000009'), 'MASTER'));
    test('other prefixes are null', () => expect(detectBrand('371449635398431'), null));
    test('empty is null', () => expect(detectBrand(''), null));
  });

  group('luhnCheck', () {
    test('valid VISA test number passes', () => expect(luhnCheck('4111111111111111'), true));
    test('invalid number fails', () => expect(luhnCheck('4111111111111112'), false));
    test('non-digits fail', () => expect(luhnCheck('4111abc111111111'), false));
    test('too short fails', () => expect(luhnCheck('411'), false));
  });

  group('isValidExpiry', () {
    test('month 13 invalid', () => expect(isValidExpiry('13', '39'), false));
    test('month 00 invalid', () => expect(isValidExpiry('00', '39'), false));
    test('far-future year valid', () => expect(isValidExpiry('12', '39'), true));
    test('past year invalid', () => expect(isValidExpiry('12', '20'), false));
  });

  group('normalizeYear', () {
    test('2-digit gets 20 prefix', () => expect(normalizeYear('39'), '2039'));
    test('4-digit unchanged', () => expect(normalizeYear('2039'), '2039'));
  });

  group('isValidCvv', () {
    test('3 digits valid', () => expect(isValidCvv('123'), true));
    test('2 digits invalid', () => expect(isValidCvv('12'), false));
    test('letters invalid', () => expect(isValidCvv('12a'), false));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail.**

Run: `flutter test test/features/hyperpay_payment/card_validators_test.dart`
Expected: FAIL — "Error: Couldn't resolve the package ... card_validators.dart".

- [ ] **Step 3: Implement.** Full contents of `lib/features/hyperpay_payment/domain/card_validators.dart`:

```dart
/// Pure validation helpers for the HyperPay custom card form.
/// Brand support is intentionally VISA/MASTER only (Wensa scope).
library;

/// Detects the card brand from the leading digits.
/// VISA starts with 4; Mastercard with 51–55 or 2221–2720.
String? detectBrand(String digits) {
  if (digits.isEmpty) return null;
  if (digits.startsWith('4')) return 'VISA';
  final two = digits.length >= 2 ? int.tryParse(digits.substring(0, 2)) : null;
  if (two != null && two >= 51 && two <= 55) return 'MASTER';
  final four = digits.length >= 4 ? int.tryParse(digits.substring(0, 4)) : null;
  if (four != null && four >= 2221 && four <= 2720) return 'MASTER';
  return null;
}

bool luhnCheck(String digits) {
  if (digits.length < 12 || !RegExp(r'^\d+$').hasMatch(digits)) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.parse(digits[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n = (n % 10) + 1;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

bool isValidExpiry(String mm, String yy) {
  final month = int.tryParse(mm);
  final year = int.tryParse(normalizeYear(yy));
  if (month == null || year == null || month < 1 || month > 12) return false;
  final now = DateTime.now();
  if (year < now.year) return false;
  if (year == now.year && month < now.month) return false;
  return true;
}

String normalizeYear(String yy) => yy.length == 2 ? '20$yy' : yy;

bool isValidCvv(String cvv) => RegExp(r'^\d{3}$').hasMatch(cvv);
```

- [ ] **Step 4: Run tests to verify they pass.**

Run: `flutter test test/features/hyperpay_payment/card_validators_test.dart`
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/hyperpay_payment test/features/hyperpay_payment
git commit -m "feat(hyperpay): card validators (brand detection, Luhn, expiry, CVV)"
```

---

### Task 4: HyperPay channel wrapper + verify service (TDD on the channel)

**Files:**
- Create: `lib/features/hyperpay_payment/data/services/hyperpay_channel.dart`
- Create: `lib/features/hyperpay_payment/data/services/hyperpay_verify_service.dart`
- Test: `test/features/hyperpay_payment/hyperpay_channel_test.dart`

**Interfaces:**
- Consumes: `normalizeYear` from Task 3.
- Produces (used by Task 5):
  - `enum HyperpayFailureKind { cancelled, invalidCard, failed }`
  - `class HyperpayPaymentException implements Exception { final HyperpayFailureKind kind; final String message; }`
  - `class HyperpayChannel { Future<void> submitCardPayment({required String checkoutId, required String brand, required String cardNumber, required String holderName, required String expiryMonth, required String expiryYear, required String cvv, required String mode}) }` — completes normally on `"success"`/`"SYNC"`, throws `HyperpayPaymentException` otherwise.
  - `class HyperpayVerifyService { Future<bool> verify({required String checkoutId, required String kind, required String id, required String referenceId}) }` — `kind` ∈ `booking|concert_group|membership`; returns `paid`.
- Produces (contract implemented natively in Tasks 7–8): method `submitCardPayment` on channel `app.wensa.mobile/hyperpay` with arguments `{checkoutid, brand, card_number, holder_name, month, year (4-digit), cvv, mode}`; native returns the String `"SYNC"` or `"success"`, or throws PlatformException with code `cancelled` | `invalid_card` | `transaction_failed`.

- [ ] **Step 1: Write the failing tests.** Full contents of `test/features/hyperpay_payment/hyperpay_channel_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/hyperpay_payment/data/services/hyperpay_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.wensa.mobile/hyperpay');

  Map<Object?, Object?>? capturedArgs;

  void mockNative(Object? Function() handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'submitCardPayment');
      capturedArgs = call.arguments as Map<Object?, Object?>;
      return handler();
    });
  }

  Future<void> submit(HyperpayChannel c) => c.submitCardPayment(
        checkoutId: 'chk_1',
        brand: 'VISA',
        cardNumber: '4111111111111111',
        holderName: 'M ALHAMAD',
        expiryMonth: '12',
        expiryYear: '39',
        cvv: '123',
        mode: 'TEST',
      );

  test('sends normalized 4-digit year and all fields', () async {
    mockNative(() => 'SYNC');
    await submit(HyperpayChannel());
    expect(capturedArgs!['year'], '2039');
    expect(capturedArgs!['checkoutid'], 'chk_1');
    expect(capturedArgs!['brand'], 'VISA');
    expect(capturedArgs!['mode'], 'TEST');
  });

  test('completes on success result', () async {
    mockNative(() => 'success');
    await expectLater(submit(HyperpayChannel()), completes);
  });

  test('maps cancelled PlatformException', () async {
    mockNative(() => throw PlatformException(code: 'cancelled', message: 'user closed'));
    await expectLater(
      submit(HyperpayChannel()),
      throwsA(isA<HyperpayPaymentException>()
          .having((e) => e.kind, 'kind', HyperpayFailureKind.cancelled)),
    );
  });

  test('maps unknown error to failed', () async {
    mockNative(() => throw PlatformException(code: 'transaction_failed', message: 'declined'));
    await expectLater(
      submit(HyperpayChannel()),
      throwsA(isA<HyperpayPaymentException>()
          .having((e) => e.kind, 'kind', HyperpayFailureKind.failed)),
    );
  });

  test('unexpected result string throws failed', () async {
    mockNative(() => 'weird');
    await expectLater(
      submit(HyperpayChannel()),
      throwsA(isA<HyperpayPaymentException>()),
    );
  });
}
```

- [ ] **Step 2: Run to verify failure.**

Run: `flutter test test/features/hyperpay_payment/hyperpay_channel_test.dart`
Expected: FAIL — package URI unresolved.

- [ ] **Step 3: Implement the channel.** Full contents of `lib/features/hyperpay_payment/data/services/hyperpay_channel.dart`:

```dart
import 'package:flutter/services.dart';

import '../../domain/card_validators.dart';

enum HyperpayFailureKind { cancelled, invalidCard, failed }

class HyperpayPaymentException implements Exception {
  const HyperpayPaymentException(this.kind, this.message);

  final HyperpayFailureKind kind;
  final String message;

  @override
  String toString() => 'HyperpayPaymentException(${kind.name}): $message';
}

/// Bridge to the native HyperPay mSDK.
///
/// Native contract (Android MainActivity.kt / iOS SceneDelegate.swift):
/// method `submitCardPayment` returns "SYNC" (no 3DS) or "success" (3DS
/// challenge completed and redirected back), or throws PlatformException
/// with code `cancelled` | `invalid_card` | `transaction_failed`.
class HyperpayChannel {
  const HyperpayChannel();

  static const _channel = MethodChannel('app.wensa.mobile/hyperpay');

  Future<void> submitCardPayment({
    required String checkoutId,
    required String brand,
    required String cardNumber,
    required String holderName,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String mode,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('submitCardPayment', {
        'checkoutid': checkoutId,
        'brand': brand,
        'card_number': cardNumber,
        'holder_name': holderName,
        'month': expiryMonth,
        'year': normalizeYear(expiryYear),
        'cvv': cvv,
        'mode': mode,
      });
      if (result != 'success' && result != 'SYNC') {
        throw HyperpayPaymentException(
          HyperpayFailureKind.failed,
          'Unexpected payment result: $result',
        );
      }
    } on PlatformException catch (e) {
      final kind = switch (e.code) {
        'cancelled' => HyperpayFailureKind.cancelled,
        'invalid_card' => HyperpayFailureKind.invalidCard,
        _ => HyperpayFailureKind.failed,
      };
      throw HyperpayPaymentException(kind, e.message ?? 'Payment failed');
    }
  }
}
```

- [ ] **Step 4: Implement the verify service** (thin Supabase wrapper, exercised by integration testing — no unit test). Full contents of `lib/features/hyperpay_payment/data/services/hyperpay_verify_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls the verify-payment edge function, which checks the payment with
/// HyperPay server-side and flips the row to confirmed via user-scoped RPCs.
class HyperpayVerifyService {
  const HyperpayVerifyService();

  /// [kind] is one of: booking | concert_group | membership.
  /// Returns true when HyperPay reports the payment as paid.
  Future<bool> verify({
    required String checkoutId,
    required String kind,
    required String id,
    required String referenceId,
  }) async {
    final result = await Supabase.instance.client.functions.invoke(
      'verify-payment',
      body: {
        'checkout_id': checkoutId,
        'kind': kind,
        'id': id,
        'reference_id': referenceId,
      },
    );
    if (result.status != 200) {
      throw Exception('verify-payment failed: ${result.data}');
    }
    final data = result.data as Map<String, dynamic>;
    return data['paid'] == true;
  }
}
```

- [ ] **Step 5: Run tests.**

Run: `flutter test test/features/hyperpay_payment/`
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/hyperpay_payment test/features/hyperpay_payment
git commit -m "feat(hyperpay): method-channel wrapper and verify-payment service"
```

---

### Task 5: Card payment screen + push API

**Files:**
- Create: `lib/features/hyperpay_payment/presentation/screens/card_payment_screen.dart`
- Create: `lib/features/hyperpay_payment/presentation/pages/hyperpay_payment_page.dart`
- Test: `test/features/hyperpay_payment/card_payment_screen_test.dart`

**Interfaces:**
- Consumes: Task 3 validators; Task 4 `HyperpayChannel`, `HyperpayVerifyService`, `HyperpayPaymentException`, `HyperpayFailureKind`.
- Produces (used by Task 6 — deliberately mirrors the old `PaymentWebViewPage.push` callback shapes):

```dart
class HyperpayPaymentPage {
  static Future<void> push(
    BuildContext context, {
    required String checkoutId,
    required String referenceId,
    required String entityKindForVerify, // 'booking' | 'concert_group' | 'membership'
    required String entityId,            // booking_id | group_id | membership_id
    required String paymentMode,         // 'TEST' | 'LIVE'
    void Function(String referenceId, String orderId)? onPaymentSuccess,
    void Function()? onPaymentFailed,
    void Function()? onPaymentCancelled,
  });
}
```

Semantics identical to the Wayl page: exactly one callback fires; leaving the screen without a result fires `onPaymentCancelled`; `onPaymentSuccess` receives `(referenceId, checkoutId)` as `(referenceId, orderId)`.

- [ ] **Step 1: Read the design references.** Read `lib/core/widgets/glass_back_button.dart` and one existing form screen (e.g. `grep -rl "TextFormField" lib/features --include="*.dart" | head -3`, read one) plus `lib/core/theme/` (find with `ls lib/core`) to match Wensa's input decoration, colors (`AppColors`), and button styles. Use `FilledButton` and the app's existing `InputDecoration` conventions rather than the demo's raw Material defaults.

- [ ] **Step 2: Write the failing widget test.** Full contents of `test/features/hyperpay_payment/card_payment_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_riverpod/features/hyperpay_payment/presentation/screens/card_payment_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('PAY is disabled until the form is valid', (tester) async {
    await tester.pumpWidget(_wrap(const CardPaymentScreen(
      checkoutId: 'chk_1',
      referenceId: 'ref_1',
      entityKindForVerify: 'booking',
      entityId: 'b1',
      paymentMode: 'TEST',
    )));

    final payButton = find.widgetWithText(FilledButton, 'Pay');
    expect(tester.widget<FilledButton>(payButton).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('card_number')), '4111111111111111');
    await tester.enterText(find.byKey(const Key('holder_name')), 'M ALHAMAD');
    await tester.enterText(find.byKey(const Key('expiry_month')), '12');
    await tester.enterText(find.byKey(const Key('expiry_year')), '39');
    await tester.enterText(find.byKey(const Key('cvv')), '123');
    await tester.pump();

    expect(tester.widget<FilledButton>(payButton).onPressed, isNotNull);
  });

  testWidgets('invalid Luhn number keeps PAY disabled', (tester) async {
    await tester.pumpWidget(_wrap(const CardPaymentScreen(
      checkoutId: 'chk_1',
      referenceId: 'ref_1',
      entityKindForVerify: 'booking',
      entityId: 'b1',
      paymentMode: 'TEST',
    )));

    await tester.enterText(find.byKey(const Key('card_number')), '4111111111111112');
    await tester.enterText(find.byKey(const Key('holder_name')), 'M ALHAMAD');
    await tester.enterText(find.byKey(const Key('expiry_month')), '12');
    await tester.enterText(find.byKey(const Key('expiry_year')), '39');
    await tester.enterText(find.byKey(const Key('cvv')), '123');
    await tester.pump();

    final payButton = find.widgetWithText(FilledButton, 'Pay');
    expect(tester.widget<FilledButton>(payButton).onPressed, isNull);
  });
}
```

- [ ] **Step 3: Run to verify failure.**

Run: `flutter test test/features/hyperpay_payment/card_payment_screen_test.dart`
Expected: FAIL — screen file missing.

- [ ] **Step 4: Implement `CardPaymentScreen`.** A `StatefulWidget` (no Riverpod needed — services are constructor-injectable with defaults for testability). Required behavior; write it in Wensa's visual style discovered in Step 1:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_riverpod/core/widgets/glass_back_button.dart';

import '../../data/services/hyperpay_channel.dart';
import '../../data/services/hyperpay_verify_service.dart';
import '../../domain/card_validators.dart';

/// Wensa-styled HyperPay card form. Field keys (used by widget tests):
/// card_number, holder_name, expiry_month, expiry_year, cvv.
class CardPaymentScreen extends StatefulWidget {
  const CardPaymentScreen({
    super.key,
    required this.checkoutId,
    required this.referenceId,
    required this.entityKindForVerify,
    required this.entityId,
    required this.paymentMode,
    this.channel = const HyperpayChannel(),
    this.verifyService = const HyperpayVerifyService(),
    this.onPaymentSuccess,
    this.onPaymentFailed,
    this.onPaymentCancelled,
  });

  final String checkoutId;
  final String referenceId;
  final String entityKindForVerify;
  final String entityId;
  final String paymentMode;
  final HyperpayChannel channel;
  final HyperpayVerifyService verifyService;
  final void Function(String referenceId, String orderId)? onPaymentSuccess;
  final void Function()? onPaymentFailed;
  final void Function()? onPaymentCancelled;

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}
```

State requirements:
- Five `TextEditingController`s with listeners driving `setState`; digits-only `FilteringTextInputFormatter.digitsOnly` on number/month/year/cvv; card number max 16, month 2, year 2, cvv 3.
- `bool get _formValid` = `luhnCheck(number) && detectBrand(number) != null && holder.trim().isNotEmpty && isValidExpiry(month, year) && isValidCvv(cvv)`.
- Show the detected brand (small `Text` of "VISA"/"Mastercard") next to the number field when detected.
- `Pay` `FilledButton`: `onPressed = _formValid && !_processing ? _pay : null`, child `Text('Pay')` (swap to a `CircularProgressIndicator` while `_processing`).
- `_pay()`:
  1. `setState(_processing = true)`; clear `_errorText`.
  2. `await widget.channel.submitCardPayment(checkoutId: widget.checkoutId, brand: detectBrand(number)!, cardNumber: number, holderName: holder, expiryMonth: month, expiryYear: year, cvv: cvv, mode: widget.paymentMode)`.
  3. On success: `final paid = await widget.verifyService.verify(checkoutId: widget.checkoutId, kind: widget.entityKindForVerify, id: widget.entityId, referenceId: widget.referenceId);`
  4. If `paid`: set `_resultHandled = true`, call `widget.onPaymentSuccess?.call(widget.referenceId, widget.checkoutId)`, then `Navigator.of(context).pop()`.
  5. If not paid: set `_resultHandled = true`, call `widget.onPaymentFailed?.call()`, pop.
  6. On `HyperpayPaymentException`: if `kind == cancelled`, stay on screen with no error (user closed 3DS deliberately); otherwise show `e.message` inline below the button in the app's danger color and stay (retry allowed — the same checkout ID accepts multiple attempts).
  7. On verify network errors: show inline "Could not confirm payment — check your connection and tap Pay again." (verify is idempotent; retrying `_pay` is safe but re-charges? NO — on verify failure retry **only the verify step**: keep a `_verifyPending` flag; when set, `_pay` skips the channel call and goes straight to verify.)
  8. `finally`: `setState(_processing = false)` when still mounted and not popped.
- Cancel semantics exactly like `WaylWebViewScreen`: guarded `_resultHandled` flag; the AppBar `GlassBackButton.appBarLeading` fires `onPaymentCancelled` then pops; `dispose()` fires `onPaymentCancelled` if `!_resultHandled`.
- AppBar title: `'Payment'`, `GlassBackButton.appBarLeadingWidth`, centered — copy the Wayl screen's AppBar structure.

- [ ] **Step 5: Implement `HyperpayPaymentPage`.** Full contents of `lib/features/hyperpay_payment/presentation/pages/hyperpay_payment_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../screens/card_payment_screen.dart';

/// Drop-in replacement for the old PaymentWebViewPage: pushes the HyperPay
/// card form and forwards the same success/failed/cancelled callbacks.
class HyperpayPaymentPage {
  static Future<void> push(
    BuildContext context, {
    required String checkoutId,
    required String referenceId,
    required String entityKindForVerify,
    required String entityId,
    required String paymentMode,
    void Function(String referenceId, String orderId)? onPaymentSuccess,
    void Function()? onPaymentFailed,
    void Function()? onPaymentCancelled,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CardPaymentScreen(
          checkoutId: checkoutId,
          referenceId: referenceId,
          entityKindForVerify: entityKindForVerify,
          entityId: entityId,
          paymentMode: paymentMode,
          onPaymentSuccess: onPaymentSuccess,
          onPaymentFailed: onPaymentFailed,
          onPaymentCancelled: onPaymentCancelled,
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run the tests.**

Run: `flutter test test/features/hyperpay_payment/`
Expected: all PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/hyperpay_payment test/features/hyperpay_payment
git commit -m "feat(hyperpay): Wensa-styled card payment screen and push API"
```

---

### Task 6: Rewire booking + membership flows; delete Wayl

**Files:**
- Modify: `lib/features/booking/presentation/providers/booking_submit_provider.dart`
- Modify: `lib/features/booking/presentation/providers/membership_submit_provider.dart`
- Modify: `lib/features/booking/presentation/sections/padel_section.dart`
- Modify: `lib/features/booking/presentation/sections/farm_section.dart`
- Modify: `lib/features/booking/presentation/sections/restaurant_section.dart`
- Modify: `lib/features/booking/presentation/sections/concert_section.dart`
- Modify: `lib/features/booking/presentation/sections/membership_section.dart`
- Delete: `lib/features/booking/presentation/pages/payment_webview_page.dart`
- Delete: `lib/features/wayl_payment/` (entire directory)

**Interfaces:**
- Consumes: `HyperpayPaymentPage.push` from Task 5; `checkout_id`/`payment_mode` response fields from Task 1.
- Produces: `BookingSubmitState.success({required String bookingId, required String checkoutId, required String holdUntil, required String referenceId, required String paymentMode})`.

- [ ] **Step 1: Update `BookingSubmitState`.** In `booking_submit_provider.dart` replace the success factory:

```dart
  const factory BookingSubmitState.success({
    required String bookingId,
    required String checkoutId,
    required String holdUntil,
    // Our referenceId (e.g. "booking_{uuid}_{ts}") — becomes payment_id on
    // confirm; NOT bookingId which is just the raw UUID.
    required String referenceId,
    required String paymentMode, // 'TEST' | 'LIVE' from the server
  }) = _Success;
```

In every `create*` method map the new response: `checkoutId: data['checkout_id'] as String? ?? ''`, `referenceId: data['reference_id'] as String? ?? ''`, `paymentMode: data['payment_mode'] as String? ?? 'TEST'` (keep each method's existing null-tolerance style). Update `cancelPending`'s `success: (id, _, _, _) => id` to `success: (id, _, _, _, _) => id`. Apply the same mapping in `membership_submit_provider.dart` (`data['checkout_id']`, `data['payment_mode']` — the create-membership function gains these fields in the dashboard repo; tolerate absence with `?? ''`), and update its `cancelPending`'s `success: (id, _, _, _) => id` to the 5-arg form as well.

- [ ] **Step 2: Regenerate codegen.**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: exits 0, regenerates `booking_submit_provider.freezed.dart` / `.g.dart`.

- [ ] **Step 3: Rewire each section.** In each of the five section files, find the `PaymentWebViewPage.push(` call (and its enclosing helper, e.g. `openPaymentWebView(String bookingId, String paymentUrl, String waylReferenceId)`). Replace the helper signature and call with the HyperPay equivalents, keeping **every callback body byte-identical** (they handle confirm/refresh/navigation/cancel and must not change):

```dart
    void openCardPayment(String bookingId, String checkoutId,
        String referenceId, String paymentMode) {
      HyperpayPaymentPage.push(
        context,
        checkoutId: checkoutId,
        referenceId: referenceId,
        entityKindForVerify: 'booking', // concert_section: 'concert_group'; membership_section: 'membership'
        entityId: bookingId,            // concert: the group id the section already passes
        paymentMode: paymentMode,
        onPaymentSuccess: /* existing body unchanged */,
        onPaymentFailed: /* existing body unchanged */,
        onPaymentCancelled: /* existing body unchanged */,
      );
    }
```

Update the `ref.listen`/`onAction` call sites that read the success state to pass the renamed fields (`checkoutId`, `referenceId`, `paymentMode` instead of `paymentUrl`, `waylReferenceId`), and swap the import of `payment_webview_page.dart` for `package:future_riverpod/features/hyperpay_payment/presentation/pages/hyperpay_payment_page.dart`. Also drop the now-unused `redirectionUrl: 'wansa://payment'` arguments.

- [ ] **Step 4: Delete Wayl.**

```bash
git rm -r lib/features/wayl_payment lib/features/booking/presentation/pages/payment_webview_page.dart
grep -rn "wayl_payment\|WaylWebViewScreen\|PaymentWebViewPage" lib --include="*.dart"
```

Expected: grep returns nothing. Then `grep -rni "wayl" lib --include="*.dart" | grep -v ".g.dart\|.freezed.dart"` — remaining hits must be display-only/historical (e.g. `wayl_code` on old tickets in `bookings_history`, model fields) — leave those; fix any initiation-path stragglers.

- [ ] **Step 5: Analyze and test.**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test`
Expected: analyze clean; all tests pass (fix fallout — e.g. tests referencing removed fields).

- [ ] **Step 6: Commit**

```bash
git add -A lib test
git commit -m "feat(payments): route bookings and memberships through HyperPay card flow, remove Wayl"
```

---

### Task 7: Android native integration

**Files:**
- Create: `android/app/libs/oppwa.mobile.aar`, `android/app/libs/ipworks3ds_sdk.aar` (copied)
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/proguard-rules.pro`
- Modify: `android/app/src/main/kotlin/app/wensa/mobile/MainActivity.kt`

**Interfaces:**
- Consumes: channel contract from Task 4 (`submitCardPayment` args/results/error codes), shopper result URL `wensa://payment-result`.
- Produces: working Android payment path; `flutter build apk --debug` compiles.

- [ ] **Step 1: Copy AARs.**

```bash
mkdir -p android/app/libs
cp "/Users/mousaalhamad/Downloads/SDK v7.11/Android_Frameworks_7.11.0/oppwa.mobile.aar" android/app/libs/
cp "/Users/mousaalhamad/Downloads/SDK v7.11/Android_Frameworks_7.11.0/ipworks3ds_sdk.aar" android/app/libs/
```

Confirm `android/.gitignore`/`android/app/.gitignore` do not exclude `libs/` (`git check-ignore android/app/libs/oppwa.mobile.aar` → no output). If ignored, add `!android/app/libs/*.aar` to the ignoring file.

- [ ] **Step 2: Gradle changes.** In `android/app/build.gradle.kts`: set `minSdk = maxOf(flutter.minSdkVersion, 24)` with the comment `// HyperPay mSDK 7.11 (oppwa.mobile / ipworks3ds) requires minSdk 24`; extend the bottom `dependencies` block:

```kotlin
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // HyperPay mSDK 7.11 (android/app/libs) + its required dependencies
    // (from the SDK's dependencies.txt; Braintree/PayPal/Venmo omitted — cards only).
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.recyclerview:recyclerview:1.4.0")
    implementation("androidx.browser:browser:1.8.0")
    implementation("androidx.fragment:fragment-ktx:1.8.6")
    implementation("androidx.constraintlayout:constraintlayout:2.2.1")
    implementation("androidx.webkit:webkit:1.13.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("com.google.code.gson:gson:2.11.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
}
```

- [ ] **Step 3: ProGuard keeps.** Append to `android/app/proguard-rules.pro` (create if missing and referenced):

```
# HyperPay mSDK + ipworks 3DS — reflection-heavy, keep everything
-keep class com.oppwa.** { *; }
-keep interface com.oppwa.** { *; }
-keep class ipworks3ds.** { *; }
-keep class inqooltech.** { *; }
-dontwarn com.oppwa.**
```

- [ ] **Step 4: Rewrite `MainActivity.kt`.** Full contents (Kotlin port of the demo's card-only path; brand is validated Dart-side, natively re-checked by the SDK):

```kotlin
package app.wensa.mobile

import android.app.Dialog
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import com.oppwa.mobile.connect.exception.PaymentError
import com.oppwa.mobile.connect.exception.PaymentException
import com.oppwa.mobile.connect.payment.BrandsValidation
import com.oppwa.mobile.connect.payment.CheckoutInfo
import com.oppwa.mobile.connect.payment.ImagesRequest
import com.oppwa.mobile.connect.payment.card.CardPaymentParams
import com.oppwa.mobile.connect.provider.Connect
import com.oppwa.mobile.connect.provider.ITransactionListener
import com.oppwa.mobile.connect.provider.OppPaymentProvider
import com.oppwa.mobile.connect.provider.Transaction
import com.oppwa.mobile.connect.provider.TransactionType
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity(), ITransactionListener {

    companion object {
        private const val CHANNEL = "app.wensa.mobile/hyperpay"
        private const val SHOPPER_RESULT_URL = "wensa://payment-result"
        private const val RESULT_SCHEME = "wensa"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var pendingResult: MethodChannel.Result? = null
    private var challengeDialog: Dialog? = null

    private fun resolveSuccess(value: String) = handler.post {
        pendingResult?.success(value)
        pendingResult = null
    }

    private fun resolveError(code: String, message: String) = handler.post {
        pendingResult?.error(code, message, null)
        pendingResult = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "submitCardPayment") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("transaction_failed", "A payment is already in progress", null)
                    return@setMethodCallHandler
                }
                pendingResult = result
                submitCard(
                    checkoutId = call.argument<String>("checkoutid") ?: "",
                    brand = call.argument<String>("brand") ?: "",
                    number = call.argument<String>("card_number") ?: "",
                    holder = call.argument<String>("holder_name") ?: "",
                    month = call.argument<String>("month") ?: "",
                    year = call.argument<String>("year") ?: "",
                    cvv = call.argument<String>("cvv") ?: "",
                    mode = call.argument<String>("mode") ?: "TEST",
                )
            }
    }

    private fun submitCard(
        checkoutId: String, brand: String, number: String, holder: String,
        month: String, year: String, cvv: String, mode: String,
    ) {
        if (!CardPaymentParams.isNumberValid(number, true) ||
            !CardPaymentParams.isHolderValid(holder) ||
            !CardPaymentParams.isExpiryMonthValid(month) ||
            !CardPaymentParams.isExpiryYearValid(year) ||
            !CardPaymentParams.isCvvValid(cvv)
        ) {
            resolveError("invalid_card", "Card details are invalid")
            return
        }
        try {
            val provider = OppPaymentProvider(
                this,
                if (mode == "LIVE") Connect.ProviderMode.LIVE else Connect.ProviderMode.TEST,
            )
            val params = CardPaymentParams(checkoutId, brand, number, holder, month, year, cvv)
            params.shopperResultUrl = SHOPPER_RESULT_URL
            provider.setThreeDSWorkflowListener { this }
            provider.submitTransaction(Transaction(params), this)
        } catch (e: PaymentException) {
            resolveError("transaction_failed", e.error.errorMessage ?: "Transaction failed")
        }
    }

    // ── ITransactionListener ─────────────────────────────────────────────────

    override fun transactionCompleted(transaction: Transaction) {
        if (transaction.transactionType == TransactionType.SYNC) {
            resolveSuccess("SYNC")
        } else {
            val url = transaction.redirectUrl
            if (url == null) {
                resolveError("transaction_failed", "Missing 3DS redirect URL")
            } else {
                handler.post { showChallengeDialog(url) }
            }
        }
    }

    override fun transactionFailed(transaction: Transaction, error: PaymentError) {
        resolveError("transaction_failed", error.errorMessage ?: "Transaction failed")
    }

    override fun brandsValidationRequestSucceeded(validation: BrandsValidation) {}
    override fun brandsValidationRequestFailed(error: PaymentError) {}
    override fun imagesRequestSucceeded(request: ImagesRequest) {}
    override fun imagesRequestFailed() {}
    override fun paymentConfigRequestSucceeded(info: CheckoutInfo) {}
    override fun paymentConfigRequestFailed(error: PaymentError) {}

    // ── 3DS challenge WebView (full-screen dialog, Wensa dark header) ────────

    private fun dp(value: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), resources.displayMetrics,
    ).toInt()

    private fun showChallengeDialog(url: String) {
        val dialog = Dialog(this, android.R.style.Theme_DeviceDefault_NoActionBar)
        challengeDialog = dialog
        dialog.setCancelable(false)

        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }

        val headerColor = Color.parseColor("#1A1A2E")
        val toolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(headerColor)
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(56),
            )
        }
        val closeBtn = ImageButton(this).apply {
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            setColorFilter(Color.WHITE)
            background = null
            setPadding(dp(12), 0, dp(12), 0)
        }
        toolbar.addView(closeBtn, LinearLayout.LayoutParams(dp(48), dp(56)))
        val urlLabel = TextView(this).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            gravity = Gravity.CENTER
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.MIDDLE
            text = runCatching { Uri.parse(url).host }.getOrNull() ?: url
        }
        toolbar.addView(urlLabel, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        toolbar.addView(View(this), LinearLayout.LayoutParams(dp(48), dp(56)))
        root.addView(toolbar)

        val progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            isIndeterminate = true
            visibility = View.GONE
        }
        root.addView(progress, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT,
        ))

        val webView = WebView(this)
        root.addView(webView, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))
        dialog.setContentView(root)
        dialog.window?.setLayout(
            WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT,
        )

        closeBtn.setOnClickListener {
            dialog.dismiss()
            resolveError("cancelled", "3DS challenge cancelled by user")
        }

        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            loadWithOverviewMode = true
            useWideViewPort = true
        }
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                if (request.url.scheme == RESULT_SCHEME) {
                    dialog.dismiss()
                    resolveSuccess("success")
                    return true
                }
                return false
            }

            override fun onPageStarted(view: WebView, pageUrl: String, favicon: Bitmap?) {
                progress.visibility = View.VISIBLE
                runCatching { Uri.parse(pageUrl).host }.getOrNull()?.let { urlLabel.text = it }
            }

            override fun onPageFinished(view: WebView, pageUrl: String) {
                progress.visibility = View.GONE
            }
        }
        dialog.setOnDismissListener {
            challengeDialog = null
            webView.stopLoading()
            webView.destroy()
        }
        webView.loadUrl(url)
        dialog.show()
    }

    // Fallback: the 3DS flow bounced through an external browser/app and came
    // back via the wensa:// scheme instead of inside our WebView.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.scheme == RESULT_SCHEME && intent.data?.host == "payment-result" &&
            pendingResult != null
        ) {
            challengeDialog?.dismiss()
            resolveSuccess("success")
        }
    }
}
```

Note: the existing deep-link intent-filter in `android/app/src/main/AndroidManifest.xml` already covers `wensa://` (line ~41); no manifest change needed. `FlutterActivity` → `FlutterFragmentActivity` is drop-in.

- [ ] **Step 5: Build.**

Run: `flutter build apk --debug`
Expected: BUILD SUCCESSFUL. Fix any import/API mismatches against the actual AAR (e.g. `setShopperResultUrl(...)` if the property syntax doesn't map).

- [ ] **Step 6: Commit**

```bash
git add android
git commit -m "feat(hyperpay): Android mSDK integration — channel handler + 3DS challenge WebView"
```

---

### Task 8: iOS native integration

**Files:**
- Create: `ios/HyperpaySDK/HyperpaySDK.podspec` + copied `OPPWAMobile.xcframework`, `ipworks3ds_sdk.xcframework`
- Modify: `ios/Podfile`
- Modify: `ios/Runner/SceneDelegate.swift`

**Interfaces:**
- Consumes: channel contract from Task 4; `wensa` URL scheme (already in Info.plist).
- Produces: working iOS payment path; `flutter build ios --debug --no-codesign` compiles.

- [ ] **Step 1: Vendor the frameworks as a local pod** (avoids hand-editing project.pbxproj):

```bash
mkdir -p ios/HyperpaySDK
cp -R "/Users/mousaalhamad/Downloads/SDK v7.11/iOS_Frameworks_7.11.0/OPPWAMobile.xcframework" ios/HyperpaySDK/
cp -R "/Users/mousaalhamad/Downloads/SDK v7.11/iOS_Frameworks_7.11.0/ipworks3ds_sdk.xcframework" ios/HyperpaySDK/
```

Create `ios/HyperpaySDK/HyperpaySDK.podspec`:

```ruby
Pod::Spec.new do |s|
  s.name                = 'HyperpaySDK'
  s.version             = '7.11.0'
  s.summary             = 'HyperPay mSDK vendored frameworks (OPPWAMobile + ipworks 3DS).'
  s.homepage            = 'https://wordpresshyperpay.docs.oppwa.com/'
  s.license             = { :type => 'Commercial', :text => 'HyperPay merchant license' }
  s.author              = 'HyperPay'
  s.source              = { :path => '.' }
  s.platform            = :ios, '13.0'
  s.vendored_frameworks = 'OPPWAMobile.xcframework', 'ipworks3ds_sdk.xcframework'
end
```

In `ios/Podfile`, inside `target 'Runner' do`, add `pod 'HyperpaySDK', :path => 'HyperpaySDK'` and run `cd ios && pod install && cd ..` (expected: "Installing HyperpaySDK (7.11.0)").
Check `.gitignore` doesn't exclude the frameworks (`git check-ignore ios/HyperpaySDK/OPPWAMobile.xcframework/Info.plist`); if it does, un-ignore that path.

- [ ] **Step 2: Extend `SceneDelegate.swift`.** Keep the existing badge channel exactly as is; add the HyperPay handler in the same file (new code only shown — merge into the existing class/file):

```swift
import Flutter
import UIKit
import UserNotifications
import WebKit
import OPPWAMobile

// … existing doc comment …
@objc(SceneDelegate)
class SceneDelegate: FlutterSceneDelegate {

  private var hyperpayResult: FlutterResult?
  private var paymentProvider: OPPPaymentProvider?
  private var challengeController: ChallengeWebViewController?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    // … existing badgeChannel registration stays here, unchanged …

    let hyperpayChannel = FlutterMethodChannel(
      name: "app.wensa.mobile/hyperpay",
      binaryMessenger: controller.binaryMessenger
    )
    hyperpayChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      guard call.method == "submitCardPayment" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard self.hyperpayResult == nil else {
        result(FlutterError(code: "transaction_failed",
                            message: "A payment is already in progress", details: nil))
        return
      }
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "invalid_card", message: "Missing arguments", details: nil))
        return
      }
      self.hyperpayResult = result
      self.submitCard(args: args, from: controller)
    }
  }

  private func resolveSuccess(_ value: String) {
    DispatchQueue.main.async {
      self.hyperpayResult?(value)
      self.hyperpayResult = nil
    }
  }

  private func resolveError(_ code: String, _ message: String) {
    DispatchQueue.main.async {
      self.hyperpayResult?(FlutterError(code: code, message: message, details: nil))
      self.hyperpayResult = nil
    }
  }

  private func submitCard(args: [String: Any], from presenter: UIViewController) {
    let checkoutId = args["checkoutid"] as? String ?? ""
    let brand      = args["brand"] as? String ?? ""
    let number     = args["card_number"] as? String ?? ""
    let holder     = args["holder_name"] as? String ?? ""
    let month      = args["month"] as? String ?? ""
    let year       = args["year"] as? String ?? ""
    let cvv        = args["cvv"] as? String ?? ""
    let mode       = args["mode"] as? String ?? "TEST"

    guard OPPCardPaymentParams.isNumberValid(number, luhnCheck: true),
          OPPCardPaymentParams.isHolderValid(holder),
          OPPCardPaymentParams.isExpiryMonthValid(month),
          OPPCardPaymentParams.isExpiryYearValid(year),
          OPPCardPaymentParams.isCvvValid(cvv) else {
      resolveError("invalid_card", "Card details are invalid")
      return
    }

    do {
      let params = try OPPCardPaymentParams(
        checkoutID: checkoutId, paymentBrand: brand, holder: holder,
        number: number, expiryMonth: month, expiryYear: year, cvv: cvv
      )
      params.shopperResultURL = "wensa://payment-result"
      let provider = OPPPaymentProvider(mode: mode == "LIVE" ? .live : .test)
      provider.threeDSEventListener = self
      paymentProvider = provider
      let transaction = OPPTransaction(paymentParams: params)
      provider.submitTransaction(transaction) { [weak self] transaction, error in
        guard let self else { return }
        if let error {
          self.resolveError("transaction_failed", error.localizedDescription)
          return
        }
        switch transaction.type {
        case .synchronous:
          self.resolveSuccess("SYNC")
        case .asynchronous:
          guard let redirectURL = transaction.redirectURL else {
            self.resolveError("transaction_failed", "Missing 3DS redirect URL")
            return
          }
          DispatchQueue.main.async {
            self.presentChallenge(url: redirectURL, over: presenter)
          }
        default:
          self.resolveError("transaction_failed", "Invalid transaction state")
        }
      }
    } catch {
      resolveError("transaction_failed", error.localizedDescription)
    }
  }

  private func presentChallenge(url: URL, over presenter: UIViewController) {
    let vc = ChallengeWebViewController(
      url: url,
      resultScheme: "wensa",
      onCompleted: { [weak self] in
        self?.challengeController = nil
        self?.resolveSuccess("success")
      },
      onCancelled: { [weak self] in
        self?.challengeController = nil
        self?.resolveError("cancelled", "3DS challenge cancelled by user")
      }
    )
    challengeController = vc
    let nav = UINavigationController(rootViewController: vc)
    nav.modalPresentationStyle = .fullScreen
    presenter.present(nav, animated: true)
  }

  // Fallback: the shopper redirect arrived via the OS (external browser hop)
  // instead of inside our challenge WebView.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url,
       url.scheme == "wensa", url.host == "payment-result", hyperpayResult != nil {
      challengeController?.dismissHosting()
      resolveSuccess("success")
      return
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}

extension SceneDelegate: OPPThreeDSEventListener {
  func onThreeDSChallengeRequired(completion: @escaping (UIViewController) -> Void) {
    if let root = window?.rootViewController {
      completion(root.presentedViewController ?? root)
    }
  }
}

/// Full-screen WKWebView for the 3DS challenge page. Intercepts navigation to
/// the `wensa://payment-result` shopper redirect to signal completion.
final class ChallengeWebViewController: UIViewController, WKNavigationDelegate {
  private let url: URL
  private let resultScheme: String
  private let onCompleted: () -> Void
  private let onCancelled: () -> Void
  private var webView: WKWebView!
  private var finished = false

  init(url: URL, resultScheme: String,
       onCompleted: @escaping () -> Void, onCancelled: @escaping () -> Void) {
    self.url = url
    self.resultScheme = resultScheme
    self.onCompleted = onCompleted
    self.onCancelled = onCancelled
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = url.host
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .close, target: self, action: #selector(cancelTapped))
    webView = WKWebView(frame: .zero)
    webView.navigationDelegate = self
    view = webView
    webView.load(URLRequest(url: url))
  }

  @objc private func cancelTapped() {
    guard !finished else { return }
    finished = true
    dismiss(animated: true) { self.onCancelled() }
  }

  func dismissHosting() {
    finished = true
    presentingViewController?.dismiss(animated: true)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    if navigationAction.request.url?.scheme == resultScheme {
      decisionHandler(.cancel)
      guard !finished else { return }
      finished = true
      dismiss(animated: true) { self.onCompleted() }
      return
    }
    decisionHandler(.allow)
  }
}
```

Adjust to the real SDK header names if the compiler disagrees (e.g. `threeDSEventListener` / `OPPThreeDSEventListener` signatures vary by SDK minor version — check `ios/HyperpaySDK/OPPWAMobile.xcframework/ios-arm64/OPPWAMobile.framework/Headers/` for the exact API; if the listener protocol doesn't exist in 7.11, drop the extension and the `threeDSEventListener` assignment — the SDK then uses its default challenge presentation, and our WebView path still handles the classic redirect flow).

- [ ] **Step 3: Build.**

Run: `flutter build ios --debug --no-codesign`
Expected: build succeeds. Iterate on SDK API mismatches using the framework headers (they're Objective-C — check exact initializer/property names).

- [ ] **Step 4: Commit**

```bash
git add ios
git commit -m "feat(hyperpay): iOS mSDK integration — vendored pod, channel handler, 3DS WebView"
```

---

### Task 9: Final verification + handoff

**Files:**
- Modify: `docs/superpowers/plans/2026-07-14-hyperpay-migration.md` (check boxes)

- [ ] **Step 1: Full local gates.**

Run: `flutter analyze && flutter test && flutter build apk --debug && flutter build ios --debug --no-codesign`
Expected: all pass/succeed.

- [ ] **Step 2: Repo-wide Wayl sweep.**

Run: `grep -rni "wayl" lib supabase/functions --include="*.dart" --include="*.ts" | grep -v "wayl_code"`
Expected: nothing initiation-related remains.

- [ ] **Step 3: Report to the user for manual E2E.** These steps require the user (deployed functions + devices) — present this checklist, do not run deploys unprompted:
  1. `supabase functions deploy create-booking && supabase functions deploy verify-payment`
  2. On Android device + iOS device, in TEST mode: card success (`4200000000000000` — HyperPay test VISA), 3DS challenge success, 3DS challenge cancel, declined card, membership purchase.
  3. Confirm each paid booking flips to confirmed in the DB and appears in bookings history; cancelled/declined stay pending and expire via cron.
  4. Reminder: the `create-membership` function lives in the dashboard repo and still needs the same HyperPay swap (return `checkout_id` + `payment_mode`).

- [ ] **Step 4: Merge decision.** After the user confirms E2E passes, use superpowers:finishing-a-development-branch to merge `feature/hyperpay-migration` into `main`.

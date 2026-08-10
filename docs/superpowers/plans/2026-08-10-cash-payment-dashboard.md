# Cash Payment — Dashboard (Admin + Merchant Web) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a merchant turn cash payments on/off for their own account (default on, admin sees it read-only); let both the admin and merchant portals tell cash and Wayl e-payment apart in bookings, transactions, and revenue stats.

**Architecture:** `merchants.cash_enabled` (added by the backend plan) is fetched automatically wherever `merchants`/`bookings`/`memberships` rows are already fetched — this dashboard's `getApi().get/getAll` wrapper always does `select=*`, so no query needs to change to receive the new columns; only rendering changes. `get-transactions` (backend plan, Task 5) already labels cash rows `paymentMethod: "Cash"` in its output, so `TransactionsPage`'s existing `parseTx` picks it up with zero parsing changes — only a new filter chip and one refund-button guard are needed.

**Tech Stack:** React + TypeScript, hand-rolled inline-style components (no CSS framework, no chart library — `DonutChart`/`Switch`/`StatusBadge` are bespoke components in `src/shared/ui`).

**Prerequisite:** The backend plan must be deployed first (`merchants.cash_enabled`, `bookings/memberships.payment_method`, and the updated `get-transactions` must already be live), or every verification step below shows stale data.

**Repo root for this plan:** `/Users/mousaalhamad/Desktop/Wensa/wensa_app/wansa-admin-dashboard` (a separate repo from the Flutter app and Supabase functions covered by the other two plans).

## Global Constraints

- Never restrict `select=` on any `getApi().get/getAll("merchants"|"bookings"|"memberships", ...)` call — the wrapper (`src/lib/supabase.ts:416-424`) always does `select=*${query}`, so new columns arrive automatically. Do not add explicit `select=` lists as part of this feature.
- This codebase has no test runner wired for these page components — verification is `npx tsc --noEmit` (or `npm run build`) for type safety, plus manual click-through in the browser (`npm run dev`).
- Reuse the existing `StatusBadge`/`Switch`/`DonutChart` components rather than introducing new ones — the codebase's convention (seen in `MerchantsPage.tsx`'s `dashboard_payment_required` toggle and `TransactionsPage.tsx`'s payment-method-colored badges) is to compose these primitives inline per page, not to build new shared widgets for small variations.

---

### Task 1: i18n keys

**Files:**
- Modify: `src/context/translations/en.ts`
- Modify: `src/context/translations/ar.ts`

**Interfaces:**
- Produces: `l.bkgPaymentMethod`, `l.txMethod`, `l.txCash`, `l.txEpayment`, `l.mchCashTitle`, `l.mchCashOn`, `l.mchCashOff` — consumed by Tasks 2–5.

- [ ] **Step 1: `en.ts`**

At line 104 (`txCard: "Card", txCardLocal: "Local", txCardIntl: "International",`), add immediately after:

```ts
        txMethod: "Method", txCash: "Cash", txEpayment: "E-Payment",
```

At line 393 (`bkgAmount: "Amount",`), add immediately after:

```ts
        bkgPaymentMethod: "Payment Method",
```

At line 137 (`mchDashPayOff: "Bookings made from the dashboard are free, confirmed instantly, and cancellable.",`), add immediately after:

```ts
        mchCashTitle: "Accept cash payments",
        mchCashOn: "Customers can choose to pay with cash at your venue.",
        mchCashOff: "Cash is off — customers can only pay online at checkout.",
```

- [ ] **Step 2: `ar.ts`** (mirror placement, at lines 106, 454, 139 respectively)

```ts
        txMethod: "طريقة الدفع", txCash: "نقداً", txEpayment: "دفع إلكتروني",
```

```ts
        bkgPaymentMethod: "طريقة الدفع",
```

```ts
        mchCashTitle: "قبول الدفع النقدي",
        mchCashOn: "يمكن للعملاء اختيار الدفع نقداً في موقعك.",
        mchCashOff: "الدفع النقدي متوقف — يمكن للعملاء الدفع إلكترونياً فقط عند إتمام الحجز.",
```

- [ ] **Step 3: Verify and commit**

```bash
npx tsc --noEmit
git add src/context/translations/en.ts src/context/translations/ar.ts
git commit -m "feat(i18n): add cash payment strings"
```

---

### Task 2: Merchant self-service toggle + admin read-only view

**Files:**
- Modify: `src/features/merchant/ProfilePage.tsx`
- Modify: `src/features/merchants/MerchantsPage.tsx`

**Interfaces:**
- Consumes: `merchant.cash_enabled` (boolean, arrives automatically per Global Constraints), `Switch` from `src/shared/ui` (`{ checked: boolean; onChange: (v: boolean) => void; label?: string }`).

- [ ] **Step 1: `ProfilePage.tsx` — add loading state**

Near the other `useState` declarations (after line 29, `const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});`):

```tsx
    const [cashToggleLoading, setCashToggleLoading] = useState(false);
```

- [ ] **Step 2: Add the toggle handler**

Near `savePhone` (after line 59), add:

```tsx
    const cashEnabled = merchant?.cash_enabled !== false; // default true

    const toggleCashEnabled = async (next: boolean) => {
        if (!merchant) return;
        setCashToggleLoading(true);
        try {
            await getApi().update("merchants", merchant.id, { cash_enabled: next });
            await reload();
        } catch (e: any) { setToast("Error: " + e.message); setToastErr(true); }
        setCashToggleLoading(false);
    };
```

- [ ] **Step 3: Import `Switch`**

The existing import at line 7 is:

```tsx
import { Badge, Btn, Input, Card, Toast, ImageUpload, PhoneInput, ConfirmDialog, Modal, OtpVerify, Shimmer, PayoutAccountView } from "../../shared/ui";
```

Change to:

```tsx
import { Badge, Btn, Input, Card, Toast, ImageUpload, PhoneInput, ConfirmDialog, Modal, OtpVerify, Shimmer, PayoutAccountView, Switch } from "../../shared/ui";
```

- [ ] **Step 4: Render the toggle Card**

Right after the profile info `</Card>` (line 196, the closing tag of the Card that starts at line 140), insert a new Card, mirroring the exact layout `MerchantsPage.tsx:1088-1101` uses for its (admin-controlled) `dashboard_payment_required` toggle:

```tsx

            <Card style={{ marginBottom: 18 }}>
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
                    <div>
                        <div style={{ fontWeight: 700, color: C.text }}>{l.mchCashTitle}</div>
                        <div style={{ fontSize: FS.sm, color: C.text4, marginTop: 4, lineHeight: 1.5 }}>
                            {cashEnabled ? l.mchCashOn : l.mchCashOff}
                        </div>
                    </div>
                    <div style={{ opacity: cashToggleLoading ? 0.5 : 1, pointerEvents: cashToggleLoading ? "none" : "auto" }}>
                        <Switch checked={cashEnabled} onChange={toggleCashEnabled} />
                    </div>
                </div>
            </Card>
```

- [ ] **Step 5: Admin read-only indicator — `MerchantsPage.tsx`**

Right after the existing `{/* ─── Dashboard payment toggle ─── */}` Card closes (after line 1101's `</Card>`, before the `)}` at line 1102 that closes the `{canManageCommission && (...)}` block — i.e. this new Card goes **outside** that `canManageCommission` gate, since it's read-only info any admin viewing the merchant detail page should see, not a commission-management action), insert:

```tsx

            <Card>
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
                    <div style={{ fontWeight: 700, color: C.text }}>{l.mchCashTitle}</div>
                    <span style={{
                        display: "inline-flex", alignItems: "center", gap: 6,
                        fontSize: FS.sm, fontWeight: 600,
                        color: merchant.cash_enabled !== false ? C.green : C.text4,
                    }}>
                        <span style={{
                            width: 8, height: 8, borderRadius: "50%",
                            background: merchant.cash_enabled !== false ? C.green : C.text4,
                        }} />
                        {merchant.cash_enabled !== false ? l.mchCashOn : l.mchCashOff}
                    </span>
                </div>
            </Card>
```

- [ ] **Step 6: Verify**

```bash
npx tsc --noEmit
npm run dev
```

In the browser: log in as a merchant, open Profile, confirm the toggle appears (default on), flip it off, reload the page, confirm it stayed off. Log in as admin, open that merchant's detail page, confirm the read-only indicator shows "off" without a switch to flip.

- [ ] **Step 7: Commit**

```bash
git add src/features/merchant/ProfilePage.tsx src/features/merchants/MerchantsPage.tsx
git commit -m "feat(merchant): self-service cash payment toggle, admin read-only view"
```

---

### Task 3: `BookingsPage.tsx` (admin) — Payment column

**Files:**
- Modify: `src/features/bookings/BookingsPage.tsx`

- [ ] **Step 1: Add the table header**, at line 706 (right after `<th style={thStyle}>{l.bkgAmount}</th>`):

```tsx
                                    <th style={thStyle}>{l.bkgPaymentMethod}</th>
```

- [ ] **Step 2: Add the table cell**, right after the amount `</td>` (the cell ending at line 767 in the current file, i.e. immediately before the existing `<td style={{ ...tdStyle, maxWidth: 180, overflow: "hidden" }}>` that renders the Wayl code):

```tsx
                                            <td style={tdStyle}>
                                                <StatusBadge
                                                    label={bk.payment_method === "cash" ? l.txCash : l.txEpayment}
                                                    color={bk.payment_method === "cash" ? C.green : C.brand}
                                                />
                                            </td>
```

(`StatusBadge` is already imported and used elsewhere in this file — e.g. `<StatusBadge label={getStatusLabel(bk.status)} color={stColor} />` a few lines above.)

- [ ] **Step 3: Add the detail-modal row**, right after the existing `bkgPaymentStatus` `DetailRow` (line 1077):

```tsx
            <DetailRow label={l.bkgPaymentMethod} value={
                <StatusBadge label={bk.payment_method === "cash" ? l.txCash : l.txEpayment} color={bk.payment_method === "cash" ? C.green : C.brand} />
            } />
```

- [ ] **Step 4: Verify and commit**

```bash
npx tsc --noEmit
```

Manual: open Bookings as admin, confirm every row shows a Payment badge (existing rows all show "E-Payment" since they default to `wayl`), and a cash test booking (from the backend/mobile plans' verification) shows "Cash" in green.

```bash
git add src/features/bookings/BookingsPage.tsx
git commit -m "feat(bookings): show payment method column and detail row"
```

---

### Task 4: `MyBookingsPage.tsx` (merchant) — Payment column

**Files:**
- Modify: `src/features/merchant/MyBookingsPage.tsx`

Same three edits as Task 3, at this file's own line numbers:

- [ ] **Step 1: Table header** — after `<th style={thStyle}>{l.bkgAmount}</th>` at line 695:

```tsx
                                    <th style={thStyle}>{l.bkgPaymentMethod}</th>
```

- [ ] **Step 2: Table cell** — right after the amount `</td>` (line 759 in the current file):

```tsx
                                            <td style={tdStyle}>
                                                <StatusBadge
                                                    label={bk.payment_method === "cash" ? l.txCash : l.txEpayment}
                                                    color={bk.payment_method === "cash" ? C.green : C.brand}
                                                />
                                            </td>
```

- [ ] **Step 3: Detail-modal row** — right after the existing `bkgPaymentStatus` `DetailRow` (line 928):

```tsx
                        <DetailRow label={l.bkgPaymentMethod} value={
                            <StatusBadge label={selectedBooking.payment_method === "cash" ? l.txCash : l.txEpayment} color={selectedBooking.payment_method === "cash" ? C.green : C.brand} />
                        } />
```

- [ ] **Step 4: Verify and commit**

```bash
npx tsc --noEmit
```

Manual: log in as the merchant used in the mobile plan's cash test, open My Bookings, confirm the cash booking shows the Cash badge.

```bash
git add src/features/merchant/MyBookingsPage.tsx
git commit -m "feat(bookings): show payment method column and detail row on merchant view"
```

---

### Task 5: `TransactionsPage.tsx` — Cash / E-Payment filter, exclude Cash from refund

**Files:**
- Modify: `src/features/transactions/TransactionsPage.tsx`

**Interfaces:**
- Consumes: `ParsedTx.paymentMethod` already includes `"Cash"` once the backend plan's `get-transactions` change is deployed (`parseTx`, line 61, already reads `body.paymentMethod ?? "—"` — no change needed there).

- [ ] **Step 1: Add filter state**, next to `cardScopeFilter` (line 252):

```tsx
    const [methodFilter, setMethodFilter] = useState<"all" | "cash" | "epayment">("all");
```

- [ ] **Step 2: Apply it in the filter chain**

The `useMemo` filter (around line 289, where `cardScopeFilter` is checked: `if (cardScopeFilter !== "all" && tx.cardScope !== cardScopeFilter) return false;`) gets a new condition added right after it:

```tsx
            if (methodFilter === "cash" && tx.paymentMethod !== "Cash") return false;
            if (methodFilter === "epayment" && tx.paymentMethod === "Cash") return false;
```

And its dependency array (line 301, `}, [rows, search, typeFilter, cardScopeFilter, selectedMerchantName]);`) becomes:

```tsx
    }, [rows, search, typeFilter, cardScopeFilter, methodFilter, selectedMerchantName]);
```

- [ ] **Step 3: Include it in `hasFilters` and the clear-all button** (line 318 and the button around line 364):

```tsx
    const hasFilters = search || typeFilter !== "all" || cardScopeFilter !== "all" || methodFilter !== "all";
```

```tsx
                            <button onClick={() => { setSearch(""); setTypeFilter("all"); setCardScopeFilter("all"); setMethodFilter("all"); }} style={{
```

- [ ] **Step 4: Add the filter chip row**, right after the existing "Card" chips row closes (after the `</div>` that follows the `txCardIntl` `FilterChip` at line 447, still inside the same `padding: "12px 18px"` container):

```tsx
                        <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
                            <span style={{ fontSize: FS.xs, fontWeight: 700, color: C.text4, letterSpacing: 0.5, textTransform: "uppercase", whiteSpace: "nowrap", minWidth: 60 }}>
                                {l.txMethod}
                            </span>
                            <FilterChip label={l.txAll} active={methodFilter === "all"} onClick={() => setMethodFilter("all")} />
                            <FilterChip label={l.txCash} active={methodFilter === "cash"} onClick={() => setMethodFilter("cash")} />
                            <FilterChip label={l.txEpayment} active={methodFilter === "epayment"} onClick={() => setMethodFilter("epayment")} />
                        </div>
```

- [ ] **Step 5: Exclude Cash from the refund button** — line 885 currently:

```tsx
            {tx.isPaid && !tx.isRefunded && !reversed && tx.paymentMethod !== "HyperPay" && (
```

becomes:

```tsx
            {tx.isPaid && !tx.isRefunded && !reversed && tx.paymentMethod !== "HyperPay" && tx.paymentMethod !== "Cash" && (
```

(Cash has no gateway transaction to refund at Wayl; cancelling a cash booking is handled from the Bookings page's cancel action, not this Refund button — the backend plan's Task 4 already made `booking-action`'s cancel path handle cash bookings correctly.)

- [ ] **Step 6: Verify and commit**

```bash
npx tsc --noEmit
```

Manual: open Transactions as admin, confirm the new "Method" chip row appears under "Card", filtering to "Cash" shows only the cash test booking/membership with no Refund button in its detail view, filtering to "E-Payment" shows everything else unchanged.

```bash
git add src/features/transactions/TransactionsPage.tsx
git commit -m "feat(transactions): filter by Cash vs E-Payment, exclude Cash from Wayl refund"
```

---

### Task 6: Admin `DashboardPage.tsx` — Cash vs E-Payment split

**Files:**
- Modify: `src/features/dashboard/DashboardPage.tsx`

**Interfaces:**
- Consumes: `DonutChart` (already imported at line 5), the same `arr`/`txRows` already fetched by `BookingAnalyticsSection` for its existing count/revenue stats.

- [ ] **Step 1: Add split state**, next to `revenue`/`count` (after line 34, `const [loading, setLoading] = useState(false);`):

```tsx
    const [cashRevenue, setCashRevenue] = useState<number | null>(null);
    const [epayRevenue, setEpayRevenue] = useState<number | null>(null);
```

- [ ] **Step 2: Compute the split — merchant-scoped branch**

Inside `fetchStats`, the merchant-scoped branch (lines 54-63) currently:

```tsx
                if (merchantId) {
                    // Merchant scope: bookings are the merchant's only revenue
                    // (plans/banners are their costs, not income).
                    const rows = await bookingsPromise;
                    if (cancelled) return;
                    const arr = Array.isArray(rows) ? rows : [];
                    setCount(arr.length);
                    setRevenue(arr
                        .filter((r: any) => r.payment_status === "paid")
                        .reduce((sum: number, r: any) => sum + (typeof r.amount_iqd === "number" ? r.amount_iqd : 0), 0));
                    return;
                }
```

becomes:

```tsx
                if (merchantId) {
                    // Merchant scope: bookings are the merchant's only revenue
                    // (plans/banners are their costs, not income).
                    const rows = await bookingsPromise;
                    if (cancelled) return;
                    const arr = Array.isArray(rows) ? rows : [];
                    setCount(arr.length);
                    const paidRows = arr.filter((r: any) => r.payment_status === "paid");
                    setRevenue(paidRows.reduce((sum: number, r: any) => sum + (typeof r.amount_iqd === "number" ? r.amount_iqd : 0), 0));
                    setCashRevenue(paidRows
                        .filter((r: any) => r.payment_method === "cash")
                        .reduce((sum: number, r: any) => sum + (typeof r.amount_iqd === "number" ? r.amount_iqd : 0), 0));
                    setEpayRevenue(paidRows
                        .filter((r: any) => r.payment_method !== "cash")
                        .reduce((sum: number, r: any) => sum + (typeof r.amount_iqd === "number" ? r.amount_iqd : 0), 0));
                    return;
                }
```

- [ ] **Step 3: Compute the split — platform-wide branch**

The platform-wide branch (lines 68-81) currently reduces `txRows` into a single `revenue` number. Change:

```tsx
                const [rows, txRows] = await Promise.all([
                    bookingsPromise,
                    getApi().invokeFunctionGet("get-transactions"),
                ]);
                if (cancelled) return;
                const arr = Array.isArray(rows) ? rows : [];
                setCount(arr.length);
                setRevenue((Array.isArray(txRows) ? txRows : []).reduce((sum: number, t: any) => {
                    const b = t.body ?? {};
                    if (b.paymentStatus !== "Paid" || t.refunded || b.test) return sum;
                    if (start && new Date(t.created_at) < start) return sum;
                    const total = typeof b.total === "number" ? b.total : Number(b.total) || 0;
                    return sum + total;
                }, 0));
```

to:

```tsx
                const [rows, txRows] = await Promise.all([
                    bookingsPromise,
                    getApi().invokeFunctionGet("get-transactions"),
                ]);
                if (cancelled) return;
                const arr = Array.isArray(rows) ? rows : [];
                setCount(arr.length);
                const paidTx = (Array.isArray(txRows) ? txRows : []).filter((t: any) => {
                    const b = t.body ?? {};
                    if (b.paymentStatus !== "Paid" || t.refunded || b.test) return false;
                    if (start && new Date(t.created_at) < start) return false;
                    return true;
                });
                const txTotal = (t: any) => {
                    const total = t.body?.total;
                    return typeof total === "number" ? total : Number(total) || 0;
                };
                setRevenue(paidTx.reduce((sum: number, t: any) => sum + txTotal(t), 0));
                setCashRevenue(paidTx
                    .filter((t: any) => t.body?.paymentMethod === "Cash")
                    .reduce((sum: number, t: any) => sum + txTotal(t), 0));
                setEpayRevenue(paidTx
                    .filter((t: any) => t.body?.paymentMethod !== "Cash")
                    .reduce((sum: number, t: any) => sum + txTotal(t), 0));
```

- [ ] **Step 4: Reset the new state alongside the existing reset**, in `fetchStats`'s top (line 45-47, `setCount(null); setRevenue(null);`) and in the `catch`/no-data paths — change:

```tsx
            setCount(null);
            setRevenue(null);
```

to:

```tsx
            setCount(null);
            setRevenue(null);
            setCashRevenue(null);
            setEpayRevenue(null);
```

And the `catch` block (`if (!cancelled) { setCount(0); setRevenue(0); }`) to:

```tsx
            } catch {
                if (!cancelled) { setCount(0); setRevenue(0); setCashRevenue(0); setEpayRevenue(0); }
```

- [ ] **Step 5: Render the donut**, right after the two existing stat boxes close (after the `</div>` at line 144, still inside the outer `<div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>` that wraps them — i.e. this becomes a third flex item alongside "Total Bookings" and "Total Revenue"):

```tsx
                <div style={{
                    flex: "1 1 220px", background: C.surface, border: `1px solid ${C.border}`,
                    borderRadius: R.lg, padding: "18px 20px",
                    display: "flex", alignItems: "center", gap: 16,
                }}>
                    <DonutChart
                        size={72}
                        thickness={12}
                        slices={[
                            { value: cashRevenue ?? 0, color: C.green, label: l.txCash },
                            { value: epayRevenue ?? 0, color: C.accent, label: l.txEpayment },
                        ].filter(s => s.value > 0)}
                    />
                    <div>
                        <div style={{ fontSize: FS.md, fontWeight: 600, color: C.text4, marginBottom: 6, textTransform: "uppercase" as any, letterSpacing: 0.4 }}>
                            {l.txCash} / {l.txEpayment}
                        </div>
                        {loading ? <Shimmer width="70%" height={16} radius={6} /> : (
                            <>
                                <div style={{ fontSize: FS.md, color: C.green, fontWeight: 600 }}>{(cashRevenue ?? 0).toLocaleString()} IQD</div>
                                <div style={{ fontSize: FS.md, color: C.accent, fontWeight: 600 }}>{(epayRevenue ?? 0).toLocaleString()} IQD</div>
                            </>
                        )}
                    </div>
                </div>
```

- [ ] **Step 6: Verify and commit**

```bash
npx tsc --noEmit
```

Manual: open the admin Dashboard, confirm the new card renders next to Total Bookings/Total Revenue, and its two numbers sum to the Total Revenue figure for the same period.

```bash
git add src/features/dashboard/DashboardPage.tsx
git commit -m "feat(dashboard): show cash vs e-payment revenue split"
```

---

### Task 7: Merchant `DashboardPage.tsx` — Cash vs E-Payment split (mirrors Task 6)

**Files:**
- Modify: `src/features/merchant/DashboardPage.tsx`

This file's `BookingAnalyticsSection` (lines 35-128) is a separately-maintained copy scoped to one merchant — no `get-transactions` branch, revenue always comes straight from the `bookings` fetch (line 53, `const rows = await getApi().getAll("bookings", qs);`).

- [ ] **Step 1: Import `DonutChart`**

Line 6 currently:

```tsx
import { Badge, Btn, Card, StatCard, Shimmer } from "../../shared/ui";
```

becomes:

```tsx
import { Badge, Btn, Card, StatCard, Shimmer, DonutChart } from "../../shared/ui";
```

- [ ] **Step 2: Add split state**, next to `loading` (after line 40):

```tsx
    const [cashRevenue, setCashRevenue] = useState<number | null>(null);
    const [epayRevenue, setEpayRevenue] = useState<number | null>(null);
```

- [ ] **Step 3: Compute the split**

Lines 55-62 currently:

```tsx
                const rows = await getApi().getAll("bookings", qs);
                if (cancelled) return;
                const arr = Array.isArray(rows) ? rows : [];
                setCount(arr.length);
                // Revenue = money actually collected: payment_status 'paid'
                // (excludes refunded/free/pending), same rule as the admin
                // dashboard so both surfaces reconcile.
                setRevenue(arr
                    .filter((r: any) => r.payment_status === "paid")
                    .reduce((sum: number, r: any) => sum + (typeof r.amount_iqd === "number" ? r.amount_iqd : 0), 0));
```

becomes:

```tsx
                const rows = await getApi().getAll("bookings", qs);
                if (cancelled) return;
                const arr = Array.isArray(rows) ? rows : [];
                setCount(arr.length);
                // Revenue = money actually collected: payment_status 'paid'
                // (excludes refunded/free/pending), same rule as the admin
                // dashboard so both surfaces reconcile.
                const paidRows = arr.filter((r: any) => r.payment_status === "paid");
                setRevenue(paidRows.reduce((sum: number, r: any) => sum + (typeof r.amount_iqd === "number" ? r.amount_iqd : 0), 0));
                setCashRevenue(paidRows
                    .filter((r: any) => r.payment_method === "cash")
                    .reduce((sum: number, r: any) => sum + (typeof r.amount_iqd === "number" ? r.amount_iqd : 0), 0));
                setEpayRevenue(paidRows
                    .filter((r: any) => r.payment_method !== "cash")
                    .reduce((sum: number, r: any) => sum + (typeof r.amount_iqd === "number" ? r.amount_iqd : 0), 0));
```

- [ ] **Step 4: Reset alongside the existing reset**

Line 46-47 (`setCount(null); setRevenue(null);`) becomes:

```tsx
            setCount(null);
            setRevenue(null);
            setCashRevenue(null);
            setEpayRevenue(null);
```

And the `catch` (line 64, `if (!cancelled) { setCount(0); setRevenue(0); }`) becomes:

```tsx
            } catch {
                if (!cancelled) { setCount(0); setRevenue(0); setCashRevenue(0); setEpayRevenue(0); }
```

- [ ] **Step 5: Render the donut**

Right after the existing two stat boxes' wrapping `</div>` closes (after line 125), append a third box identical in shape to Task 6 Step 5's:

```tsx
                <div style={{
                    flex: "1 1 220px", background: C.surface, border: `1px solid ${C.border}`,
                    borderRadius: R.lg, padding: "18px 20px",
                    display: "flex", alignItems: "center", gap: 16,
                }}>
                    <DonutChart
                        size={72}
                        thickness={12}
                        slices={[
                            { value: cashRevenue ?? 0, color: C.green, label: l.txCash },
                            { value: epayRevenue ?? 0, color: C.accent, label: l.txEpayment },
                        ].filter(s => s.value > 0)}
                    />
                    <div>
                        <div style={{ fontSize: FS.md, fontWeight: 600, color: C.text4, marginBottom: 6, textTransform: "uppercase" as any, letterSpacing: 0.4 }}>
                            {l.txCash} / {l.txEpayment}
                        </div>
                        {loading ? <Shimmer width="70%" height={16} radius={6} /> : (
                            <>
                                <div style={{ fontSize: FS.md, color: C.green, fontWeight: 600 }}>{(cashRevenue ?? 0).toLocaleString()} IQD</div>
                                <div style={{ fontSize: FS.md, color: C.accent, fontWeight: 600 }}>{(epayRevenue ?? 0).toLocaleString()} IQD</div>
                            </>
                        )}
                    </div>
                </div>
```

- [ ] **Step 6: Verify and commit**

```bash
npx tsc --noEmit
```

Manual: log in as the merchant used in the mobile plan's cash test, open their Dashboard, confirm the split card appears and matches the totals seen in Task 6 for that merchant.

```bash
git add src/features/merchant/DashboardPage.tsx
git commit -m "feat(merchant-dashboard): show cash vs e-payment revenue split"
```

---

### Task 8: Final verification pass

- [ ] **Step 1: Full type check and build**

```bash
npx tsc --noEmit
npm run build
```

Expected: both succeed with no new errors.

- [ ] **Step 2: End-to-end manual pass**

Using the cash bookings/membership created during the backend and mobile plans' verification steps: confirm they appear correctly across — admin Bookings (Payment badge), merchant My Bookings (Payment badge), admin Transactions (Cash filter tab, no refund button), admin Dashboard (split donut), merchant Dashboard (split donut), merchant Profile (toggle), admin Merchant detail (read-only indicator). Then flip the merchant's cash toggle off from Profile and confirm a *new* mobile-app cash booking attempt against that merchant is rejected (per the backend plan's `cash_disabled` error path) rather than silently succeeding.

- [ ] **Step 3: No commit** — verification only.

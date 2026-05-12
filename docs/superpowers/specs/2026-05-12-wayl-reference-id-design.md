# Spec: Wayl Reference ID on Booking Details Page

**Date:** 2026-05-12  
**Status:** Approved

---

## Problem

After a successful Wayl payment the booking's `payment_id` field holds the Wayl transaction reference. This ID is never surfaced in the app, so users cannot share it with support or the merchant for reconciliation.

## Goal

Display the Wayl transaction reference ID on the booking detail ticket card and let users copy it to clipboard with a single tap.

---

## Scope

- **In scope:** Booking detail page only (`_BookingDetailBody`).  
- **Out of scope:** Memberships (no equivalent payment reference surfaced), admin views, push notifications.

---

## Design

### Placement

A `_ReferenceRow` widget is inserted between `_InfoGrid` and the end of the top-section `Padding` inside `_TicketBody`. It is rendered only when `paymentId` is non-null and non-empty.

### `_TicketBody` parameter change

Add an optional `String? paymentId` parameter. `_BookingDetailBody` passes `booking.paymentId`; `_MembershipDetailBody` passes `null` (omitted).

### `_ReferenceRow` widget

Full-width row inside the top section, separated from the info grid by a light divider:

```
┌──────────────────────────────────────────────────────┐
│  [divider]                                           │
│  REFERENCE                         3a4f-89bc…  [⧉] │
└──────────────────────────────────────────────────────┘
```

- **Label:** "REFERENCE" / "المرجع" — same `labelSmall` + primary color style as `_InfoCell` labels.
- **Value:** The raw `payment_id` string, right-aligned, muted color (`onSurface` at 55% opacity), ellipsized at end if too long. Uses a `Flexible` so it can shrink without overflow.
- **Copy icon:** `Icons.copy_rounded` at 16 px, same muted color, to the right of the value.
- **Tap target:** The entire row is wrapped in `InkWell`/`GestureDetector`. On tap:
  1. `Clipboard.setData(ClipboardData(text: paymentId))`.
  2. Show `SnackBar` with message "Copied!" / "تم النسخ".
- **Import:** `package:flutter/services.dart` for `Clipboard`.

### Divider

`Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08))` — same style already used between `_InfoGrid` rows — is added above the reference row with a top `SizedBox(height: 14)` spacer matching grid row padding.

---

## Files Changed

| File | Change |
|------|--------|
| `lib/features/bookings_history/presentation/pages/ticket_detail_page.dart` | Add `paymentId` param to `_TicketBody`; pass from `_BookingDetailBody`; add `_ReferenceRow` widget |

No model, repository, or database changes required.

---

## Localisation

| Key | English | Arabic |
|-----|---------|--------|
| label | Reference | المرجع |
| snackbar | Copied! | تم النسخ |

# Wayl Reference ID — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface `booking.paymentId` as a copiable "Reference" row on the booking details ticket card.

**Architecture:** Single-file change to `ticket_detail_page.dart`. Add optional `paymentId` to `_TicketBody`, pass it from `_BookingDetailBody`, and add a `_ReferenceRow` widget that copies to clipboard on tap.

**Tech Stack:** Flutter, `package:flutter/services.dart` (Clipboard)

---

## File Map

| File | Change |
|------|--------|
| `lib/features/bookings_history/presentation/pages/ticket_detail_page.dart` | Add `paymentId` param to `_TicketBody`; pass from `_BookingDetailBody`; add `_ReferenceRow` widget; import `services.dart` |

---

### Task 1: Add `paymentId` to `_TicketBody` and pass it from `_BookingDetailBody`

**Files:**
- Modify: `lib/features/bookings_history/presentation/pages/ticket_detail_page.dart`

- [ ] **Step 1: Add the `services` import at the top of the file**

In `ticket_detail_page.dart`, after the existing imports, add:

```dart
import 'package:flutter/services.dart';
```

- [ ] **Step 2: Add `paymentId` parameter to `_TicketBody`**

In the `_TicketBody` class definition, add the field and constructor parameter:

```dart
class _TicketBody extends StatefulWidget {
  const _TicketBody({
    required this.qrToken,
    required this.displayName,
    required this.isArabic,
    required this.statusBadge,
    required this.cells,
    this.paymentId,           // ← add this
  });

  final String qrToken;
  final String displayName;
  final bool isArabic;
  final Widget statusBadge;
  final List<_InfoCell> cells;
  final String? paymentId;   // ← add this
```

- [ ] **Step 3: Render `_ReferenceRow` inside `_TicketBodyState.build`**

In `_TicketBodyState.build`, inside the top-section `Padding`'s `Column`, add the row after `_InfoGrid`:

```dart
// ── Top: booking info ───────────────────────────────────────
Padding(
  key: _topKey,
  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        widget.displayName,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 10),
      widget.statusBadge,
      const SizedBox(height: 20),
      _InfoGrid(cells: widget.cells),
      if (widget.paymentId != null && widget.paymentId!.isNotEmpty) ...[
        const SizedBox(height: 14),
        Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        _ReferenceRow(paymentId: widget.paymentId!, isArabic: widget.isArabic),
      ],
    ],
  ),
),
```

- [ ] **Step 4: Pass `paymentId` from `_BookingDetailBody`**

In `_BookingDetailBody.build`, update the `_TicketBody(...)` call:

```dart
return _TicketBody(
  qrToken: booking.qrToken,
  displayName: name,
  isArabic: isArabic,
  statusBadge: TicketStatusBadge.booking(status: booking.status, isArabic: isArabic),
  cells: cells,
  paymentId: booking.paymentId,   // ← add this
);
```

---

### Task 2: Add `_ReferenceRow` widget

**Files:**
- Modify: `lib/features/bookings_history/presentation/pages/ticket_detail_page.dart`

- [ ] **Step 1: Add `_ReferenceRow` after the `_InfoGrid` class (before `_ErrorBody`)**

```dart
// ─────────────────────────────────────────────────────────────────────────────
//  Reference row — shows Wayl transaction ID with tap-to-copy
// ─────────────────────────────────────────────────────────────────────────────

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.paymentId, required this.isArabic});

  final String paymentId;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final mutedColor = cs.onSurface.withValues(alpha: 0.55);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: paymentId));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم النسخ' : 'Copied!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Text(
              isArabic ? 'المرجع' : 'Reference',
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                paymentId,
                style: tt.bodySmall?.copyWith(color: mutedColor),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.copy_rounded, size: 16, color: mutedColor),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Hot-reload the app and open a booking with a confirmed payment**

Verify:
- A "Reference" row appears below the info grid with the payment ID and copy icon.
- Tapping it shows a floating snackbar "Copied!".
- Bookings with `paymentId == null` show no reference row.

- [ ] **Step 3: Commit**

```bash
git add lib/features/bookings_history/presentation/pages/ticket_detail_page.dart
git commit -m "feat(booking-detail): show Wayl reference ID with tap-to-copy"
```

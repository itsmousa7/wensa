// lib/features/events/presentation/widgets/event_date_section.dart
//
// Displays start and optional end date/time for an event.
//
// Format:
//   English  →  DD/MM/YY  h:mm AM/PM
//   Arabic   →  YY/MM/DD  h:mm ص/م
//
// Layout rules:
//   • Single-day  (start & end on the same calendar date):
//       Shows the date once + a time range on the same row.
//       e.g.  "12/04/26   5:00 PM – 9:00 PM"
//
//   • Multi-day (different calendar dates):
//       Shows a start row and an end row — same pattern as before but
//       with the corrected format and a visible "→" separator between the dates.
//       e.g.  "يبدأ:  26/04/25   5:00 PM"
//             "ينتهي: 26/05/05   9:00 PM"
//
// RTL fix: all date/time strings are wrapped in a LTR Directionality so
// slashes and digits never get mirrored by the Arabic text direction.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventDateSection extends StatelessWidget {
  const EventDateSection({
    super.key,
    required this.startDate,
    this.endDate,
    required this.isAr,
  });

  final String startDate;
  final String? endDate;
  final bool isAr;

  // ── Public helpers (reused in hot_event_section) ──────────────────────────

  /// Returns true when [start] and [end] fall on different calendar days.
  static bool isMultiDay(String start, String? end) {
    if (end == null) return false;
    try {
      final s = DateTime.parse(start).toLocal();
      final e = DateTime.parse(end).toLocal();
      return s.year != e.year || s.month != e.month || s.day != e.day;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final multiDay = isMultiDay(startDate, endDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(CupertinoIcons.calendar, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 10),
          multiDay
              ? _MultiDayBody(
                  startDate: startDate,
                  endDate: endDate!,
                  isAr: isAr,
                  cs: cs,
                  tt: tt,
                )
              : _SingleDayBody(
                  startDate: startDate,
                  endDate: endDate,
                  isAr: isAr,
                  cs: cs,
                  tt: tt,
                ),
        ],
      ),
    );
  }
}

// ── Single-day body ───────────────────────────────────────────────────────────
// Shows: date · start time – end time (on one or two lines)

class _SingleDayBody extends StatelessWidget {
  const _SingleDayBody({
    required this.startDate,
    required this.endDate,
    required this.isAr,
    required this.cs,
    required this.tt,
  });

  final String startDate;
  final String? endDate;
  final bool isAr;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final date = _DateParts.from(startDate, isAr);
    final startTime = _DateParts.timeOnly(startDate);
    final endTime = endDate != null ? _DateParts.timeOnly(endDate!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Date row
        _LtrText(
          date.dateStr,
          style: tt.labelMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        // Time row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LtrText(
              startTime,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (endTime != null) ...[
              Text(
                '  –  ',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
              _LtrText(
                endTime,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Multi-day body ────────────────────────────────────────────────────────────
// Shows: labelled start row + labelled end row

class _MultiDayBody extends StatelessWidget {
  const _MultiDayBody({
    required this.startDate,
    required this.endDate,
    required this.isAr,
    required this.cs,
    required this.tt,
  });

  final String startDate;
  final String endDate;
  final bool isAr;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final start = _DateParts.from(startDate, isAr);
    final end = _DateParts.from(endDate, isAr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _DateRow(
          label: isAr ? 'يبدأ:' : 'Starts:',
          dateParts: start,
          isAr: isAr,
          cs: cs,
          tt: tt,
          color: cs.primary,
        ),
        const SizedBox(height: 6),
        _DateRow(
          label: isAr ? 'ينتهي:' : 'Ends:',
          dateParts: end,
          isAr: isAr,
          cs: cs,
          tt: tt,
          color: cs.outline,
        ),
      ],
    );
  }
}

// ── Single date row with label ────────────────────────────────────────────────

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.dateParts,
    required this.isAr,
    required this.cs,
    required this.tt,
    required this.color,
  });

  final String label;
  final _DateParts dateParts;
  final bool isAr;
  final ColorScheme cs;
  final TextTheme tt;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final labelStyle = tt.labelSmall?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
    );
    final dateStyle = tt.labelMedium?.copyWith(
      color: color,
      fontWeight: FontWeight.bold,
    );
    final timeStyle = tt.labelSmall?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.65),
      fontWeight: FontWeight.w600,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed width keeps both label columns the same size so the
        // date/time values always start at exactly the same X position.
        SizedBox(width: 46, child: Text(label, style: labelStyle)),
        _LtrText(dateParts.dateStr, style: dateStyle),
        const SizedBox(width: 8),
        _LtrText(dateParts.timeStr, style: timeStyle),
      ],
    );
  }
}

// ── LTR wrapper ───────────────────────────────────────────────────────────────
// Forces date/time strings to render left-to-right even inside Arabic RTL
// context, preventing slashes and digits from being mirrored.

class _LtrText extends StatelessWidget {
  const _LtrText(this.text, {required this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(text, style: style),
  );
}

// ── Date formatter ────────────────────────────────────────────────────────────

class _DateParts {
  const _DateParts({required this.dateStr, required this.timeStr});

  final String dateStr; // formatted date, e.g. "25/04/26" or "26/04/25"
  final String timeStr; // formatted time, e.g. "5:00 PM"

  /// Builds a _DateParts from an ISO-8601 string.
  /// English → DD/MM/YY   Arabic → YY/MM/DD
  factory _DateParts.from(String raw, bool isAr) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final yy = (dt.year % 100).toString().padLeft(2, '0');
      final dateStr = isAr ? '$yy/$mm/$dd' : '$dd/$mm/$yy';
      return _DateParts(dateStr: dateStr, timeStr: _formatTime(dt));
    } catch (_) {
      return _DateParts(dateStr: raw, timeStr: '');
    }
  }

  /// Extracts only the time portion from an ISO-8601 string.
  static String timeOnly(String raw) {
    try {
      return _formatTime(DateTime.parse(raw).toLocal());
    } catch (_) {
      return '';
    }
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour:${m.toString().padLeft(2, '0')} $period';
  }
}

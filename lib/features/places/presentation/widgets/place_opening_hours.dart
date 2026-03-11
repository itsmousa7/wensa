// lib/features/places/presentation/widgets/place_details/place_opening_hours.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_riverpod/features/places/presentation/widgets/place_details_helper.dart';

class PlaceOpeningHours extends StatefulWidget {
  const PlaceOpeningHours({super.key, required this.hours, required this.isAr});

  final Map<String, dynamic> hours;
  final bool isAr;

  @override
  State<PlaceOpeningHours> createState() => _PlaceOpeningHoursState();
}

class _PlaceOpeningHoursState extends State<PlaceOpeningHours> {
  bool _expanded = false;

  static const _keys = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
  static const _dart = [7, 1, 2, 3, 4, 5, 6]; // Dart weekday: sun=7
  static const _en = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  static const _ar = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = DateTime.now().weekday;
    final todayIdx = _dart.indexOf(today).clamp(0, 6);
    final show = _expanded ? List.generate(7, (i) => i) : [todayIdx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header (tap to expand) ──────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.isAr ? 'أوقات العمل' : 'Opening Hours',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.outline,
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  CupertinoIcons.chevron_up,
                  size: 20,
                  color: cs.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Rows ────────────────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: show.map((i) {
                final raw = widget.hours[_keys[i]]?.toString() ?? '';
                final isToday = _dart[i] == today;
                final day = widget.isAr ? _ar[i] : _en[i];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          day,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.bold,
                            color: isToday ? cs.primary : cs.onSurface,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildTimeWidget(raw, isToday, cs, tt),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeWidget(
    String raw,
    bool isToday,
    ColorScheme cs,
    TextTheme tt,
  ) {
    if (raw.isEmpty) {
      return Text(
        widget.isAr ? 'مغلق' : 'Closed',
        style: tt.bodyMedium?.copyWith(
          color: isToday ? cs.primary : cs.outline,
          fontWeight: isToday ? FontWeight.bold : FontWeight.bold,
        ),
      );
    }

    final parts = raw.split('-');
    final open = parts.isNotEmpty ? splitAmPm(parts[0].trim()) : null;
    final close = parts.length > 1 ? splitAmPm(parts[1].trim()) : null;

    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (open != null)
          _TimeChip(time: open.$1, period: open.$2, highlight: isToday),
        if (close != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ' – ',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
          _TimeChip(time: close.$1, period: close.$2, highlight: isToday),
        ],
      ],
    );

    if (isToday) {
      row = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: row,
      );
    }

    return row;
  }
}

// ── Time chip: "9:00 AM" on one line ─────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.time,
    required this.period,
    required this.highlight,
  });

  final String time;
  final String period;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = highlight ? cs.primary : cs.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          time,
          style: tt.bodySmall?.copyWith(
            fontWeight: highlight ? FontWeight.bold : FontWeight.bold,
            color: color,
          ),
        ),
        if (period.isNotEmpty) ...[
          const SizedBox(width: 2),
          Text(
            period,
            style: tt.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

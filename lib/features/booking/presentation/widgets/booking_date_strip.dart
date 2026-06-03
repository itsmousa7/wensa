import 'package:flutter/material.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

// ---------------------------------------------------------------------------
// Date utilities
// ---------------------------------------------------------------------------

/// Formats [dt] as "YYYY-MM-DD" for API calls.
String bookingFormatDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

/// Formats [dt] as "Mon, 12 May 2026" (or Arabic equivalent).
String bookingDisplayDate(DateTime dt, {bool isArabic = false}) {
  const daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const daysAr = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  const monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  const monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  if (isArabic) {
    return '${daysAr[dt.weekday - 1]}، ${dt.day} ${monthsAr[dt.month - 1]} ${dt.year}';
  }
  return '${daysEn[dt.weekday - 1]}, ${dt.day} ${monthsEn[dt.month - 1]} ${dt.year}';
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

/// Bold section label with a left-side primary accent bar.
class BookingSectionLabel extends StatelessWidget {
  const BookingSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: cs.onSurface,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal 90-day date strip
// ---------------------------------------------------------------------------

/// Horizontally scrollable date strip showing 90 days from today.
class BookingDateStrip extends StatefulWidget {
  const BookingDateStrip({
    super.key,
    required this.selected,
    required this.onSelect,
    this.closedDates = const {},
  });

  final DateTime selected;
  final void Function(DateTime) onSelect;
  final Set<String> closedDates;

  @override
  State<BookingDateStrip> createState() => _BookingDateStripState();
}

class _BookingDateStripState extends State<BookingDateStrip> {
  late final ScrollController _scroll;

  static const double _itemW = 76;
  static const double _spacing = 8;
  static const double _padding = 16;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final diff = widget.selected
        .difference(DateTime(today.year, today.month, today.day))
        .inDays
        .clamp(0, 89);
    final offset =
        (diff * (_itemW + _spacing)).clamp(0.0, double.infinity);
    _scroll = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final todayLabel = isAr ? 'اليوم' : 'Today';

    const monthEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const monthAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    final months = isAr ? monthAr : monthEn;

    return SizedBox(
      height: 78,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        itemCount: 90,
        itemBuilder: (context, i) {
          final today = DateTime.now();
          final date = DateTime(today.year, today.month, today.day)
              .add(Duration(days: i));
          final isSel = date.year == widget.selected.year &&
              date.month == widget.selected.month &&
              date.day == widget.selected.day;
          final isToday = i == 0;
          final dateStr = bookingFormatDate(date);
          final isClosed = widget.closedDates.contains(dateStr);
          final month = months[date.month - 1];

          final String headline;
          final String sub;
          if (isClosed) {
            headline = '${date.day}';
            sub = isAr ? 'مغلق' : 'Closed';
          } else if (isToday) {
            headline = todayLabel;
            sub = '${date.day} $month';
          } else {
            headline = '${date.day}';
            sub = month;
          }

          final Color headlineColor = isClosed
              ? cs.onSurface.withValues(alpha: 0.35)
              : cs.onSurface;
          final Color subColor = isClosed
              ? cs.error.withValues(alpha: 0.6)
              : cs.onSurface.withValues(alpha: 0.5);

          return Padding(
            padding: EdgeInsetsDirectional.only(end: _spacing),
            child: GestureDetector(
              onTap: isClosed ? null : () => widget.onSelect(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: _itemW,
                decoration: BoxDecoration(
                  color: isClosed
                      ? cs.error.withValues(alpha: isDark ? 0.10 : 0.05)
                      : cs.surface,
                  borderRadius: AppSpacing.borderRadiusLG,
                  border: Border.all(
                    color: isSel
                        ? cs.primary
                        : isClosed
                            ? cs.error.withValues(alpha: 0.25)
                            : cs.outlineVariant.withValues(alpha: 0.7),
                    width: isSel ? 2 : 1.2,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.15),
                            blurRadius: 10,
                            spreadRadius: -1,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      headline,
                      style: TextStyle(
                        fontSize: (isToday && !isClosed) ? 17 : 21,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: headlineColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

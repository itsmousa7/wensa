import 'package:flutter/material.dart';

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

  static const double _itemW = 60;
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

    // Short 2-3 char abbreviations that fit in a 60px pill
    const dayAbbrevEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // Arabic 2-letter abbreviations
    const dayAbbrevAr = ['إث', 'ث', 'أر', 'خ', 'ج', 'س', 'أح'];

    final dayAbbrev = isAr ? dayAbbrevAr : dayAbbrevEn;
    final todayLabel = isAr ? 'اليوم' : 'Today';

    return SizedBox(
      height: 96,
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

          final Color dayNumColor;
          final Color dayNameColor;

          if (isSel) {
            dayNumColor = Colors.white;
            dayNameColor = Colors.white.withValues(alpha: 0.85);
          } else if (isClosed) {
            dayNumColor = cs.onSurface.withValues(alpha: 0.35);
            dayNameColor = cs.error.withValues(alpha: 0.55);
          } else if (isToday) {
            dayNumColor = cs.primary;
            dayNameColor = cs.primary.withValues(alpha: 0.75);
          } else {
            dayNumColor = cs.onSurface.withValues(alpha: 0.80);
            dayNameColor = cs.onSurface.withValues(alpha: 0.45);
          }

          return Padding(
            padding: EdgeInsetsDirectional.only(end: _spacing),
            child: GestureDetector(
              onTap: () => widget.onSelect(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: _itemW,
                decoration: BoxDecoration(
                  gradient: isSel
                      ? LinearGradient(
                          colors: [cs.primary, cs.secondary],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isSel
                      ? null
                      : isClosed
                          ? cs.error.withValues(alpha: isDark ? 0.10 : 0.06)
                          : isToday
                              ? cs.primary.withValues(
                                  alpha: isDark ? 0.18 : 0.08)
                              : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSel
                        ? Colors.transparent
                        : isClosed
                            ? cs.error.withValues(alpha: 0.25)
                            : isToday
                                ? cs.primary.withValues(alpha: 0.35)
                                : cs.outlineVariant.withValues(alpha: 0.6),
                    width: (!isSel && (isToday || isClosed)) ? 1.5 : 1.0,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.30),
                            blurRadius: 12,
                            spreadRadius: -1,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Day name / "Today" label
                    Text(
                      isClosed
                          ? (isAr ? 'مغلق' : 'Closed')
                          : isToday
                              ? todayLabel
                              : dayAbbrev[date.weekday - 1],
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: dayNameColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Day number
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: dayNumColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Selection dot / bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: isSel ? 20 : (isToday ? 5 : 3),
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSel
                            ? Colors.white.withValues(alpha: 0.65)
                            : isToday
                                ? cs.primary.withValues(alpha: 0.55)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
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

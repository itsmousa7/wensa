class MerchantDiscount {
  const MerchantDiscount({
    required this.id,
    required this.merchantId,
    required this.percent,
    required this.appliesToAllPlaces,
    required this.placeIds,
    required this.timeMode,
    required this.hourSlots,
    required this.discountDates,
    this.name,
    this.maxDiscountAmount,
    this.hourStart,
    this.hourEnd,
    this.startsAt,
    this.expiresAt,
    this.isActive = true,
  });

  final String id;
  final String merchantId;
  final String? name;
  final double percent;
  final num? maxDiscountAmount;
  final bool appliesToAllPlaces;
  final List<String> placeIds;
  final String timeMode; // 'all_day' | 'hours'
  final List<int> hourSlots; // each int = hour-of-day [0..23] the discount covers
  // Date-only strings ('YYYY-MM-DD'). When non-empty (hours mode), discount
  // only applies on these exact calendar dates (intersected with starts_at/
  // expires_at). Empty = legacy range-only behaviour.
  final List<String> discountDates;
  final String? hourStart;
  final String? hourEnd;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final bool isActive;

  bool appliesToPlace({
    required String placeId,
    required String? merchantId,
  }) {
    if (appliesToAllPlaces) {
      return merchantId != null && merchantId == this.merchantId;
    }
    return placeIds.contains(placeId);
  }

  bool isCurrentlyActive([DateTime? now]) {
    if (!isActive) return false;
    final t = now ?? DateTime.now();
    if (startsAt != null && t.isBefore(startsAt!)) return false;
    if (expiresAt != null && t.isAfter(expiresAt!)) return false;
    return true;
  }

  /// True when [date] (local calendar date) is one of the days this discount
  /// applies to. When [discountDates] is empty (legacy/all_day mode), the
  /// answer falls back to [isCurrentlyActive] for that date.
  bool appliesOnDate(DateTime date) {
    if (!isActive) return false;
    final dayStart = DateTime(date.year, date.month, date.day);
    // Range check (inclusive).
    if (startsAt != null) {
      final s = startsAt!;
      final startDay = DateTime(s.year, s.month, s.day);
      if (dayStart.isBefore(startDay)) return false;
    }
    if (expiresAt != null) {
      final e = expiresAt!;
      final endDay = DateTime(e.year, e.month, e.day);
      if (dayStart.isAfter(endDay)) return false;
    }
    if (discountDates.isEmpty) return true;
    final key = '${dayStart.year.toString().padLeft(4, '0')}-'
        '${dayStart.month.toString().padLeft(2, '0')}-'
        '${dayStart.day.toString().padLeft(2, '0')}';
    return discountDates.contains(key);
  }

  /// Returns true if [hour] (0..23) is covered by this discount.
  /// For 'all_day', any hour matches. For 'hours', it must be in [hourSlots].
  bool appliesAtHour(int hour) {
    if (timeMode == 'all_day') return true;
    if (hourSlots.isNotEmpty) return hourSlots.contains(hour);
    // Legacy fallback: derive from hour_start/hour_end range.
    final s = _parseHour(hourStart);
    final e = _parseHour(hourEnd);
    if (s == null || e == null) return false;
    if (e > s) return hour >= s && hour < e;
    // Wrap past midnight.
    return hour >= s || hour < e;
  }

  /// Does the given day's working window (`hh:mm-hh:mm`) overlap any
  /// hour covered by this discount?
  bool appliesDuringWindow(String? openingRange) {
    if (openingRange == null || openingRange.isEmpty) return false;
    final parts = openingRange.split('-');
    if (parts.length != 2) return false;
    final open = _parseHour(parts[0].trim());
    final close = _parseHour(parts[1].trim());
    if (open == null || close == null) return false;
    final hours = <int>[];
    if (close > open) {
      for (var h = open; h < close; h++) {
        hours.add(h);
      }
    } else if (close < open) {
      for (var h = open; h < 24; h++) {
        hours.add(h);
      }
      for (var h = 0; h < close; h++) {
        hours.add(h);
      }
    } else {
      return false;
    }
    return hours.any(appliesAtHour);
  }

  static int? _parseHour(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final p = hhmm.split(':');
    return int.tryParse(p[0]);
  }

  factory MerchantDiscount.fromJson(Map<String, dynamic> json) =>
      MerchantDiscount(
        id: json['id'] as String,
        merchantId: json['merchant_id'] as String,
        name: json['name'] as String?,
        percent: (json['percent'] as num).toDouble(),
        maxDiscountAmount: json['max_discount_amount'] == null
            ? null
            : num.tryParse(json['max_discount_amount'].toString()),
        appliesToAllPlaces: json['applies_to_all_places'] as bool? ?? true,
        placeIds: ((json['place_ids'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        timeMode: json['time_mode'] as String? ?? 'all_day',
        hourSlots: ((json['hour_slots'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        discountDates: ((json['discount_dates'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        hourStart: json['hour_start'] as String?,
        hourEnd: json['hour_end'] as String?,
        startsAt: json['starts_at'] != null
            ? DateTime.parse(json['starts_at'] as String)
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
      );
}

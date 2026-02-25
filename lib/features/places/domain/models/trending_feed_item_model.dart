import 'package:freezed_annotation/freezed_annotation.dart';

part 'trending_feed_item_model.freezed.dart';
part 'trending_feed_item_model.g.dart';

/// يمثّل row واحد من الـ View trending_feed
/// type = 'place' أو 'event'
@freezed
abstract class TrendingFeedItemModel with _$TrendingFeedItemModel {
  const factory TrendingFeedItemModel({
    @Default('') String id,
    @Default('place') String type, // 'place' | 'event'
    @Default('') String titleAr,
    @Default('') String titleEn,
    String? coverImageUrl,
    String? city,
    String? subtitleAr, // منطقة للمكان / تاريخ للحدث
    String? subtitleEn,
    @Default(0.0) double hotnessScore,
    @Default(false) bool isVerified,
    @Default(false) bool isFeatured,
    String? eventStartDate, // null إذا كان place
    double? ticketPrice, // null إذا كان place
  }) = _TrendingFeedItemModel;

  factory TrendingFeedItemModel.fromJson(Map<String, dynamic> json) =>
      TrendingFeedItemModel(
        id: json['id'] ?? '',
        type: json['type'] ?? 'place',
        titleAr: json['title_ar'] ?? '',
        titleEn: json['title_en'] ?? '',
        coverImageUrl: json['cover_image_url'],
        city: json['city'],
        subtitleAr: json['subtitle_ar'],
        subtitleEn: json['subtitle_en'],
        hotnessScore: (json['hotness_score'] as num?)?.toDouble() ?? 0.0,
        isVerified: json['is_verified'] ?? false,
        isFeatured: json['is_featured'] ?? false,
        eventStartDate: json['event_start_date'],
        ticketPrice: (json['ticket_price'] as num?)?.toDouble(),
      );

  // Helper: هل هذا حدث؟
  // استخدامه: item.isEvent
}

extension TrendingFeedItemX on TrendingFeedItemModel {
  bool get isEvent => type == 'event';
  bool get isPlace => type == 'place';

  /// يرجع الاسم حسب اللغة الحالية
  String titleFor(String locale) => locale == 'ar' ? titleAr : titleEn;

  /// يرجع الـ subtitle حسب اللغة الحالية
  String? subtitleFor(String locale) =>
      locale == 'ar' ? subtitleAr : subtitleEn;
}

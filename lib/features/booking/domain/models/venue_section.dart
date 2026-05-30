import 'package:freezed_annotation/freezed_annotation.dart';

part 'venue_section.freezed.dart';
part 'venue_section.g.dart';

/// A drawn section block on a venue seat map. Geometry (`x/y/w/h`) and
/// `priceIqd` / seat counts come from the `event_venue_layout` RPC.
@freezed
abstract class VenueSection with _$VenueSection {
  const factory VenueSection({
    @Default('') String id,
    @Default('') String sectionKey,
    @Default('') String nameAr,
    @Default('') String nameEn,
    @Default('seating')
    String kind, // 'seating' | 'stage' | 'label' | 'general_admission'
    @Default(0) double x,
    @Default(0) double y,
    @Default(0) double w,
    @Default(0) double h,
    @Default('#6C63FF') String fillColor,
    @Default('') String tierKey,
    @Default(0) int sortOrder,
    @Default(0) int priceIqd,
    @Default(0) int freeCount,
    @Default(0) int totalCount,
    @Default(0) int soldCount,
    @Default(0) int capacity,
  }) = _VenueSection;

  factory VenueSection.fromJson(Map<String, dynamic> json) =>
      _venueSectionFromJson(json);
}

VenueSection _venueSectionFromJson(Map<String, dynamic> json) {
  final shape = (json['shape'] as Map?)?.cast<String, dynamic>() ?? const {};
  double asD(dynamic v) => (v as num?)?.toDouble() ?? 0;
  int asI(dynamic v) => (v as num?)?.toInt() ?? 0;
  return VenueSection(
    id: json['id'] ?? '',
    sectionKey: json['section_key'] ?? '',
    nameAr: json['name_ar'] ?? '',
    nameEn: json['name_en'] ?? '',
    kind: json['kind'] ?? 'seating',
    x: asD(shape['x']),
    y: asD(shape['y']),
    w: asD(shape['w']),
    h: asD(shape['h']),
    fillColor: json['fill_color'] ?? '#6C63FF',
    tierKey: json['tier_key'] ?? '',
    sortOrder: asI(json['sort_order']),
    priceIqd: asI(json['price_iqd']),
    freeCount: asI(json['free_count']),
    totalCount: asI(json['total_count']),
    soldCount: asI(json['sold_count']),
    capacity: asI(json['capacity']),
  );
}

extension VenueSectionX on VenueSection {
  bool get isSeating => kind == 'seating';
  bool get isStage => kind == 'stage';
  bool get isGeneralAdmission => kind == 'general_admission';
  bool get isTappable => isSeating || isGeneralAdmission;
  bool get soldOut =>
      isTappable && totalCount > 0 && freeCount <= 0;
}

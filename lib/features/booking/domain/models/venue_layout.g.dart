// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_layout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VenueLayout _$VenueLayoutFromJson(Map<String, dynamic> json) => _VenueLayout(
  seatMapId: json['seatMapId'] as String? ?? '',
  canvasWidth: (json['canvasWidth'] as num?)?.toDouble() ?? 1200,
  canvasHeight: (json['canvasHeight'] as num?)?.toDouble() ?? 800,
  backgroundImageUrl: json['backgroundImageUrl'] as String?,
  sections:
      (json['sections'] as List<dynamic>?)
          ?.map((e) => VenueSection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <VenueSection>[],
);

Map<String, dynamic> _$VenueLayoutToJson(_VenueLayout instance) =>
    <String, dynamic>{
      'seatMapId': instance.seatMapId,
      'canvasWidth': instance.canvasWidth,
      'canvasHeight': instance.canvasHeight,
      'backgroundImageUrl': instance.backgroundImageUrl,
      'sections': instance.sections,
    };

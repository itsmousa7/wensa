// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VenueSection _$VenueSectionFromJson(Map<String, dynamic> json) =>
    _VenueSection(
      id: json['id'] as String? ?? '',
      sectionKey: json['sectionKey'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      kind: json['kind'] as String? ?? 'seating',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      w: (json['w'] as num?)?.toDouble() ?? 0,
      h: (json['h'] as num?)?.toDouble() ?? 0,
      fillColor: json['fillColor'] as String? ?? '#6C63FF',
      tierKey: json['tierKey'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      priceIqd: (json['priceIqd'] as num?)?.toInt() ?? 0,
      freeCount: (json['freeCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VenueSectionToJson(_VenueSection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sectionKey': instance.sectionKey,
      'nameAr': instance.nameAr,
      'nameEn': instance.nameEn,
      'kind': instance.kind,
      'x': instance.x,
      'y': instance.y,
      'w': instance.w,
      'h': instance.h,
      'fillColor': instance.fillColor,
      'tierKey': instance.tierKey,
      'sortOrder': instance.sortOrder,
      'priceIqd': instance.priceIqd,
      'freeCount': instance.freeCount,
      'totalCount': instance.totalCount,
      'soldCount': instance.soldCount,
      'capacity': instance.capacity,
    };

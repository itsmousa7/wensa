// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_section.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VenueSection {

 String get id; String get sectionKey; String get nameAr; String get nameEn; String get kind;// 'seating' | 'stage' | 'label' | 'general_admission'
 double get x; double get y; double get w; double get h; String get fillColor; String get tierKey; int get sortOrder; int get priceIqd; int get freeCount; int get totalCount; int get soldCount; int get capacity;
/// Create a copy of VenueSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueSectionCopyWith<VenueSection> get copyWith => _$VenueSectionCopyWithImpl<VenueSection>(this as VenueSection, _$identity);

  /// Serializes this VenueSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VenueSection&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionKey, sectionKey) || other.sectionKey == sectionKey)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.w, w) || other.w == w)&&(identical(other.h, h) || other.h == h)&&(identical(other.fillColor, fillColor) || other.fillColor == fillColor)&&(identical(other.tierKey, tierKey) || other.tierKey == tierKey)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.priceIqd, priceIqd) || other.priceIqd == priceIqd)&&(identical(other.freeCount, freeCount) || other.freeCount == freeCount)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.soldCount, soldCount) || other.soldCount == soldCount)&&(identical(other.capacity, capacity) || other.capacity == capacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionKey,nameAr,nameEn,kind,x,y,w,h,fillColor,tierKey,sortOrder,priceIqd,freeCount,totalCount,soldCount,capacity);

@override
String toString() {
  return 'VenueSection(id: $id, sectionKey: $sectionKey, nameAr: $nameAr, nameEn: $nameEn, kind: $kind, x: $x, y: $y, w: $w, h: $h, fillColor: $fillColor, tierKey: $tierKey, sortOrder: $sortOrder, priceIqd: $priceIqd, freeCount: $freeCount, totalCount: $totalCount, soldCount: $soldCount, capacity: $capacity)';
}


}

/// @nodoc
abstract mixin class $VenueSectionCopyWith<$Res>  {
  factory $VenueSectionCopyWith(VenueSection value, $Res Function(VenueSection) _then) = _$VenueSectionCopyWithImpl;
@useResult
$Res call({
 String id, String sectionKey, String nameAr, String nameEn, String kind, double x, double y, double w, double h, String fillColor, String tierKey, int sortOrder, int priceIqd, int freeCount, int totalCount, int soldCount, int capacity
});




}
/// @nodoc
class _$VenueSectionCopyWithImpl<$Res>
    implements $VenueSectionCopyWith<$Res> {
  _$VenueSectionCopyWithImpl(this._self, this._then);

  final VenueSection _self;
  final $Res Function(VenueSection) _then;

/// Create a copy of VenueSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sectionKey = null,Object? nameAr = null,Object? nameEn = null,Object? kind = null,Object? x = null,Object? y = null,Object? w = null,Object? h = null,Object? fillColor = null,Object? tierKey = null,Object? sortOrder = null,Object? priceIqd = null,Object? freeCount = null,Object? totalCount = null,Object? soldCount = null,Object? capacity = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionKey: null == sectionKey ? _self.sectionKey : sectionKey // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,w: null == w ? _self.w : w // ignore: cast_nullable_to_non_nullable
as double,h: null == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as double,fillColor: null == fillColor ? _self.fillColor : fillColor // ignore: cast_nullable_to_non_nullable
as String,tierKey: null == tierKey ? _self.tierKey : tierKey // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,priceIqd: null == priceIqd ? _self.priceIqd : priceIqd // ignore: cast_nullable_to_non_nullable
as int,freeCount: null == freeCount ? _self.freeCount : freeCount // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,soldCount: null == soldCount ? _self.soldCount : soldCount // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VenueSection].
extension VenueSectionPatterns on VenueSection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VenueSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VenueSection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VenueSection value)  $default,){
final _that = this;
switch (_that) {
case _VenueSection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VenueSection value)?  $default,){
final _that = this;
switch (_that) {
case _VenueSection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sectionKey,  String nameAr,  String nameEn,  String kind,  double x,  double y,  double w,  double h,  String fillColor,  String tierKey,  int sortOrder,  int priceIqd,  int freeCount,  int totalCount,  int soldCount,  int capacity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VenueSection() when $default != null:
return $default(_that.id,_that.sectionKey,_that.nameAr,_that.nameEn,_that.kind,_that.x,_that.y,_that.w,_that.h,_that.fillColor,_that.tierKey,_that.sortOrder,_that.priceIqd,_that.freeCount,_that.totalCount,_that.soldCount,_that.capacity);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sectionKey,  String nameAr,  String nameEn,  String kind,  double x,  double y,  double w,  double h,  String fillColor,  String tierKey,  int sortOrder,  int priceIqd,  int freeCount,  int totalCount,  int soldCount,  int capacity)  $default,) {final _that = this;
switch (_that) {
case _VenueSection():
return $default(_that.id,_that.sectionKey,_that.nameAr,_that.nameEn,_that.kind,_that.x,_that.y,_that.w,_that.h,_that.fillColor,_that.tierKey,_that.sortOrder,_that.priceIqd,_that.freeCount,_that.totalCount,_that.soldCount,_that.capacity);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sectionKey,  String nameAr,  String nameEn,  String kind,  double x,  double y,  double w,  double h,  String fillColor,  String tierKey,  int sortOrder,  int priceIqd,  int freeCount,  int totalCount,  int soldCount,  int capacity)?  $default,) {final _that = this;
switch (_that) {
case _VenueSection() when $default != null:
return $default(_that.id,_that.sectionKey,_that.nameAr,_that.nameEn,_that.kind,_that.x,_that.y,_that.w,_that.h,_that.fillColor,_that.tierKey,_that.sortOrder,_that.priceIqd,_that.freeCount,_that.totalCount,_that.soldCount,_that.capacity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VenueSection implements VenueSection {
  const _VenueSection({this.id = '', this.sectionKey = '', this.nameAr = '', this.nameEn = '', this.kind = 'seating', this.x = 0, this.y = 0, this.w = 0, this.h = 0, this.fillColor = '#6C63FF', this.tierKey = '', this.sortOrder = 0, this.priceIqd = 0, this.freeCount = 0, this.totalCount = 0, this.soldCount = 0, this.capacity = 0});
  factory _VenueSection.fromJson(Map<String, dynamic> json) => _$VenueSectionFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String sectionKey;
@override@JsonKey() final  String nameAr;
@override@JsonKey() final  String nameEn;
@override@JsonKey() final  String kind;
// 'seating' | 'stage' | 'label' | 'general_admission'
@override@JsonKey() final  double x;
@override@JsonKey() final  double y;
@override@JsonKey() final  double w;
@override@JsonKey() final  double h;
@override@JsonKey() final  String fillColor;
@override@JsonKey() final  String tierKey;
@override@JsonKey() final  int sortOrder;
@override@JsonKey() final  int priceIqd;
@override@JsonKey() final  int freeCount;
@override@JsonKey() final  int totalCount;
@override@JsonKey() final  int soldCount;
@override@JsonKey() final  int capacity;

/// Create a copy of VenueSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueSectionCopyWith<_VenueSection> get copyWith => __$VenueSectionCopyWithImpl<_VenueSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VenueSectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VenueSection&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionKey, sectionKey) || other.sectionKey == sectionKey)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.w, w) || other.w == w)&&(identical(other.h, h) || other.h == h)&&(identical(other.fillColor, fillColor) || other.fillColor == fillColor)&&(identical(other.tierKey, tierKey) || other.tierKey == tierKey)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.priceIqd, priceIqd) || other.priceIqd == priceIqd)&&(identical(other.freeCount, freeCount) || other.freeCount == freeCount)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.soldCount, soldCount) || other.soldCount == soldCount)&&(identical(other.capacity, capacity) || other.capacity == capacity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionKey,nameAr,nameEn,kind,x,y,w,h,fillColor,tierKey,sortOrder,priceIqd,freeCount,totalCount,soldCount,capacity);

@override
String toString() {
  return 'VenueSection(id: $id, sectionKey: $sectionKey, nameAr: $nameAr, nameEn: $nameEn, kind: $kind, x: $x, y: $y, w: $w, h: $h, fillColor: $fillColor, tierKey: $tierKey, sortOrder: $sortOrder, priceIqd: $priceIqd, freeCount: $freeCount, totalCount: $totalCount, soldCount: $soldCount, capacity: $capacity)';
}


}

/// @nodoc
abstract mixin class _$VenueSectionCopyWith<$Res> implements $VenueSectionCopyWith<$Res> {
  factory _$VenueSectionCopyWith(_VenueSection value, $Res Function(_VenueSection) _then) = __$VenueSectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String sectionKey, String nameAr, String nameEn, String kind, double x, double y, double w, double h, String fillColor, String tierKey, int sortOrder, int priceIqd, int freeCount, int totalCount, int soldCount, int capacity
});




}
/// @nodoc
class __$VenueSectionCopyWithImpl<$Res>
    implements _$VenueSectionCopyWith<$Res> {
  __$VenueSectionCopyWithImpl(this._self, this._then);

  final _VenueSection _self;
  final $Res Function(_VenueSection) _then;

/// Create a copy of VenueSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionKey = null,Object? nameAr = null,Object? nameEn = null,Object? kind = null,Object? x = null,Object? y = null,Object? w = null,Object? h = null,Object? fillColor = null,Object? tierKey = null,Object? sortOrder = null,Object? priceIqd = null,Object? freeCount = null,Object? totalCount = null,Object? soldCount = null,Object? capacity = null,}) {
  return _then(_VenueSection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionKey: null == sectionKey ? _self.sectionKey : sectionKey // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,w: null == w ? _self.w : w // ignore: cast_nullable_to_non_nullable
as double,h: null == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as double,fillColor: null == fillColor ? _self.fillColor : fillColor // ignore: cast_nullable_to_non_nullable
as String,tierKey: null == tierKey ? _self.tierKey : tierKey // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,priceIqd: null == priceIqd ? _self.priceIqd : priceIqd // ignore: cast_nullable_to_non_nullable
as int,freeCount: null == freeCount ? _self.freeCount : freeCount // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,soldCount: null == soldCount ? _self.soldCount : soldCount // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

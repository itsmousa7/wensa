// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_tier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventTier {

 String get id; String get eventId; String get nameAr; String get nameEn; int get priceIqd; int get capacity; int get sortOrder;
/// Create a copy of EventTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventTierCopyWith<EventTier> get copyWith => _$EventTierCopyWithImpl<EventTier>(this as EventTier, _$identity);

  /// Serializes this EventTier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventTier&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.priceIqd, priceIqd) || other.priceIqd == priceIqd)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,nameAr,nameEn,priceIqd,capacity,sortOrder);

@override
String toString() {
  return 'EventTier(id: $id, eventId: $eventId, nameAr: $nameAr, nameEn: $nameEn, priceIqd: $priceIqd, capacity: $capacity, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $EventTierCopyWith<$Res>  {
  factory $EventTierCopyWith(EventTier value, $Res Function(EventTier) _then) = _$EventTierCopyWithImpl;
@useResult
$Res call({
 String id, String eventId, String nameAr, String nameEn, int priceIqd, int capacity, int sortOrder
});




}
/// @nodoc
class _$EventTierCopyWithImpl<$Res>
    implements $EventTierCopyWith<$Res> {
  _$EventTierCopyWithImpl(this._self, this._then);

  final EventTier _self;
  final $Res Function(EventTier) _then;

/// Create a copy of EventTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = null,Object? nameAr = null,Object? nameEn = null,Object? priceIqd = null,Object? capacity = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,priceIqd: null == priceIqd ? _self.priceIqd : priceIqd // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EventTier].
extension EventTierPatterns on EventTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventTier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventTier value)  $default,){
final _that = this;
switch (_that) {
case _EventTier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventTier value)?  $default,){
final _that = this;
switch (_that) {
case _EventTier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventId,  String nameAr,  String nameEn,  int priceIqd,  int capacity,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventTier() when $default != null:
return $default(_that.id,_that.eventId,_that.nameAr,_that.nameEn,_that.priceIqd,_that.capacity,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventId,  String nameAr,  String nameEn,  int priceIqd,  int capacity,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _EventTier():
return $default(_that.id,_that.eventId,_that.nameAr,_that.nameEn,_that.priceIqd,_that.capacity,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventId,  String nameAr,  String nameEn,  int priceIqd,  int capacity,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _EventTier() when $default != null:
return $default(_that.id,_that.eventId,_that.nameAr,_that.nameEn,_that.priceIqd,_that.capacity,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventTier implements EventTier {
  const _EventTier({this.id = '', this.eventId = '', this.nameAr = '', this.nameEn = '', this.priceIqd = 0, this.capacity = 0, this.sortOrder = 0});
  factory _EventTier.fromJson(Map<String, dynamic> json) => _$EventTierFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String eventId;
@override@JsonKey() final  String nameAr;
@override@JsonKey() final  String nameEn;
@override@JsonKey() final  int priceIqd;
@override@JsonKey() final  int capacity;
@override@JsonKey() final  int sortOrder;

/// Create a copy of EventTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventTierCopyWith<_EventTier> get copyWith => __$EventTierCopyWithImpl<_EventTier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventTierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventTier&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.priceIqd, priceIqd) || other.priceIqd == priceIqd)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventId,nameAr,nameEn,priceIqd,capacity,sortOrder);

@override
String toString() {
  return 'EventTier(id: $id, eventId: $eventId, nameAr: $nameAr, nameEn: $nameEn, priceIqd: $priceIqd, capacity: $capacity, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$EventTierCopyWith<$Res> implements $EventTierCopyWith<$Res> {
  factory _$EventTierCopyWith(_EventTier value, $Res Function(_EventTier) _then) = __$EventTierCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventId, String nameAr, String nameEn, int priceIqd, int capacity, int sortOrder
});




}
/// @nodoc
class __$EventTierCopyWithImpl<$Res>
    implements _$EventTierCopyWith<$Res> {
  __$EventTierCopyWithImpl(this._self, this._then);

  final _EventTier _self;
  final $Res Function(_EventTier) _then;

/// Create a copy of EventTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = null,Object? nameAr = null,Object? nameEn = null,Object? priceIqd = null,Object? capacity = null,Object? sortOrder = null,}) {
  return _then(_EventTier(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,priceIqd: null == priceIqd ? _self.priceIqd : priceIqd // ignore: cast_nullable_to_non_nullable
as int,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'farm_shift.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FarmShift {

 String get placeId; FarmShiftType get shiftType; String get startsTime; String get endsTime; int get priceIqd;
/// Create a copy of FarmShift
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FarmShiftCopyWith<FarmShift> get copyWith => _$FarmShiftCopyWithImpl<FarmShift>(this as FarmShift, _$identity);

  /// Serializes this FarmShift to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FarmShift&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.shiftType, shiftType) || other.shiftType == shiftType)&&(identical(other.startsTime, startsTime) || other.startsTime == startsTime)&&(identical(other.endsTime, endsTime) || other.endsTime == endsTime)&&(identical(other.priceIqd, priceIqd) || other.priceIqd == priceIqd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,placeId,shiftType,startsTime,endsTime,priceIqd);

@override
String toString() {
  return 'FarmShift(placeId: $placeId, shiftType: $shiftType, startsTime: $startsTime, endsTime: $endsTime, priceIqd: $priceIqd)';
}


}

/// @nodoc
abstract mixin class $FarmShiftCopyWith<$Res>  {
  factory $FarmShiftCopyWith(FarmShift value, $Res Function(FarmShift) _then) = _$FarmShiftCopyWithImpl;
@useResult
$Res call({
 String placeId, FarmShiftType shiftType, String startsTime, String endsTime, int priceIqd
});




}
/// @nodoc
class _$FarmShiftCopyWithImpl<$Res>
    implements $FarmShiftCopyWith<$Res> {
  _$FarmShiftCopyWithImpl(this._self, this._then);

  final FarmShift _self;
  final $Res Function(FarmShift) _then;

/// Create a copy of FarmShift
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? placeId = null,Object? shiftType = null,Object? startsTime = null,Object? endsTime = null,Object? priceIqd = null,}) {
  return _then(_self.copyWith(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,shiftType: null == shiftType ? _self.shiftType : shiftType // ignore: cast_nullable_to_non_nullable
as FarmShiftType,startsTime: null == startsTime ? _self.startsTime : startsTime // ignore: cast_nullable_to_non_nullable
as String,endsTime: null == endsTime ? _self.endsTime : endsTime // ignore: cast_nullable_to_non_nullable
as String,priceIqd: null == priceIqd ? _self.priceIqd : priceIqd // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FarmShift].
extension FarmShiftPatterns on FarmShift {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FarmShift value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FarmShift() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FarmShift value)  $default,){
final _that = this;
switch (_that) {
case _FarmShift():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FarmShift value)?  $default,){
final _that = this;
switch (_that) {
case _FarmShift() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String placeId,  FarmShiftType shiftType,  String startsTime,  String endsTime,  int priceIqd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FarmShift() when $default != null:
return $default(_that.placeId,_that.shiftType,_that.startsTime,_that.endsTime,_that.priceIqd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String placeId,  FarmShiftType shiftType,  String startsTime,  String endsTime,  int priceIqd)  $default,) {final _that = this;
switch (_that) {
case _FarmShift():
return $default(_that.placeId,_that.shiftType,_that.startsTime,_that.endsTime,_that.priceIqd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String placeId,  FarmShiftType shiftType,  String startsTime,  String endsTime,  int priceIqd)?  $default,) {final _that = this;
switch (_that) {
case _FarmShift() when $default != null:
return $default(_that.placeId,_that.shiftType,_that.startsTime,_that.endsTime,_that.priceIqd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FarmShift implements FarmShift {
  const _FarmShift({this.placeId = '', this.shiftType = FarmShiftType.day, this.startsTime = '', this.endsTime = '', this.priceIqd = 0});
  factory _FarmShift.fromJson(Map<String, dynamic> json) => _$FarmShiftFromJson(json);

@override@JsonKey() final  String placeId;
@override@JsonKey() final  FarmShiftType shiftType;
@override@JsonKey() final  String startsTime;
@override@JsonKey() final  String endsTime;
@override@JsonKey() final  int priceIqd;

/// Create a copy of FarmShift
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FarmShiftCopyWith<_FarmShift> get copyWith => __$FarmShiftCopyWithImpl<_FarmShift>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FarmShiftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FarmShift&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.shiftType, shiftType) || other.shiftType == shiftType)&&(identical(other.startsTime, startsTime) || other.startsTime == startsTime)&&(identical(other.endsTime, endsTime) || other.endsTime == endsTime)&&(identical(other.priceIqd, priceIqd) || other.priceIqd == priceIqd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,placeId,shiftType,startsTime,endsTime,priceIqd);

@override
String toString() {
  return 'FarmShift(placeId: $placeId, shiftType: $shiftType, startsTime: $startsTime, endsTime: $endsTime, priceIqd: $priceIqd)';
}


}

/// @nodoc
abstract mixin class _$FarmShiftCopyWith<$Res> implements $FarmShiftCopyWith<$Res> {
  factory _$FarmShiftCopyWith(_FarmShift value, $Res Function(_FarmShift) _then) = __$FarmShiftCopyWithImpl;
@override @useResult
$Res call({
 String placeId, FarmShiftType shiftType, String startsTime, String endsTime, int priceIqd
});




}
/// @nodoc
class __$FarmShiftCopyWithImpl<$Res>
    implements _$FarmShiftCopyWith<$Res> {
  __$FarmShiftCopyWithImpl(this._self, this._then);

  final _FarmShift _self;
  final $Res Function(_FarmShift) _then;

/// Create a copy of FarmShift
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? placeId = null,Object? shiftType = null,Object? startsTime = null,Object? endsTime = null,Object? priceIqd = null,}) {
  return _then(_FarmShift(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,shiftType: null == shiftType ? _self.shiftType : shiftType // ignore: cast_nullable_to_non_nullable
as FarmShiftType,startsTime: null == startsTime ? _self.startsTime : startsTime // ignore: cast_nullable_to_non_nullable
as String,endsTime: null == endsTime ? _self.endsTime : endsTime // ignore: cast_nullable_to_non_nullable
as String,priceIqd: null == priceIqd ? _self.priceIqd : priceIqd // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

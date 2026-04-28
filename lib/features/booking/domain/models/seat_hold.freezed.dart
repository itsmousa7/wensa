// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seat_hold.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SeatHold {

 String get id; String get userId; String get seatId; String get eventId; String get expiresAt;
/// Create a copy of SeatHold
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeatHoldCopyWith<SeatHold> get copyWith => _$SeatHoldCopyWithImpl<SeatHold>(this as SeatHold, _$identity);

  /// Serializes this SeatHold to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeatHold&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.seatId, seatId) || other.seatId == seatId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,seatId,eventId,expiresAt);

@override
String toString() {
  return 'SeatHold(id: $id, userId: $userId, seatId: $seatId, eventId: $eventId, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $SeatHoldCopyWith<$Res>  {
  factory $SeatHoldCopyWith(SeatHold value, $Res Function(SeatHold) _then) = _$SeatHoldCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String seatId, String eventId, String expiresAt
});




}
/// @nodoc
class _$SeatHoldCopyWithImpl<$Res>
    implements $SeatHoldCopyWith<$Res> {
  _$SeatHoldCopyWithImpl(this._self, this._then);

  final SeatHold _self;
  final $Res Function(SeatHold) _then;

/// Create a copy of SeatHold
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? seatId = null,Object? eventId = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,seatId: null == seatId ? _self.seatId : seatId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SeatHold].
extension SeatHoldPatterns on SeatHold {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeatHold value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeatHold() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeatHold value)  $default,){
final _that = this;
switch (_that) {
case _SeatHold():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeatHold value)?  $default,){
final _that = this;
switch (_that) {
case _SeatHold() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String seatId,  String eventId,  String expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeatHold() when $default != null:
return $default(_that.id,_that.userId,_that.seatId,_that.eventId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String seatId,  String eventId,  String expiresAt)  $default,) {final _that = this;
switch (_that) {
case _SeatHold():
return $default(_that.id,_that.userId,_that.seatId,_that.eventId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String seatId,  String eventId,  String expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _SeatHold() when $default != null:
return $default(_that.id,_that.userId,_that.seatId,_that.eventId,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeatHold implements SeatHold {
  const _SeatHold({this.id = '', this.userId = '', this.seatId = '', this.eventId = '', this.expiresAt = ''});
  factory _SeatHold.fromJson(Map<String, dynamic> json) => _$SeatHoldFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String userId;
@override@JsonKey() final  String seatId;
@override@JsonKey() final  String eventId;
@override@JsonKey() final  String expiresAt;

/// Create a copy of SeatHold
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeatHoldCopyWith<_SeatHold> get copyWith => __$SeatHoldCopyWithImpl<_SeatHold>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeatHoldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeatHold&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.seatId, seatId) || other.seatId == seatId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,seatId,eventId,expiresAt);

@override
String toString() {
  return 'SeatHold(id: $id, userId: $userId, seatId: $seatId, eventId: $eventId, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$SeatHoldCopyWith<$Res> implements $SeatHoldCopyWith<$Res> {
  factory _$SeatHoldCopyWith(_SeatHold value, $Res Function(_SeatHold) _then) = __$SeatHoldCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String seatId, String eventId, String expiresAt
});




}
/// @nodoc
class __$SeatHoldCopyWithImpl<$Res>
    implements _$SeatHoldCopyWith<$Res> {
  __$SeatHoldCopyWithImpl(this._self, this._then);

  final _SeatHold _self;
  final $Res Function(_SeatHold) _then;

/// Create a copy of SeatHold
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? seatId = null,Object? eventId = null,Object? expiresAt = null,}) {
  return _then(_SeatHold(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,seatId: null == seatId ? _self.seatId : seatId // ignore: cast_nullable_to_non_nullable
as String,eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

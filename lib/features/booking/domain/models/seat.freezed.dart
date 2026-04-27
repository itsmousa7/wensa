// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Seat {

 String get seatId; String get row; String get seat; String get tierKey; int get x; int get y; SeatStatus get status;
/// Create a copy of Seat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeatCopyWith<Seat> get copyWith => _$SeatCopyWithImpl<Seat>(this as Seat, _$identity);

  /// Serializes this Seat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Seat&&(identical(other.seatId, seatId) || other.seatId == seatId)&&(identical(other.row, row) || other.row == row)&&(identical(other.seat, seat) || other.seat == seat)&&(identical(other.tierKey, tierKey) || other.tierKey == tierKey)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seatId,row,seat,tierKey,x,y,status);

@override
String toString() {
  return 'Seat(seatId: $seatId, row: $row, seat: $seat, tierKey: $tierKey, x: $x, y: $y, status: $status)';
}


}

/// @nodoc
abstract mixin class $SeatCopyWith<$Res>  {
  factory $SeatCopyWith(Seat value, $Res Function(Seat) _then) = _$SeatCopyWithImpl;
@useResult
$Res call({
 String seatId, String row, String seat, String tierKey, int x, int y, SeatStatus status
});




}
/// @nodoc
class _$SeatCopyWithImpl<$Res>
    implements $SeatCopyWith<$Res> {
  _$SeatCopyWithImpl(this._self, this._then);

  final Seat _self;
  final $Res Function(Seat) _then;

/// Create a copy of Seat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seatId = null,Object? row = null,Object? seat = null,Object? tierKey = null,Object? x = null,Object? y = null,Object? status = null,}) {
  return _then(_self.copyWith(
seatId: null == seatId ? _self.seatId : seatId // ignore: cast_nullable_to_non_nullable
as String,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as String,seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as String,tierKey: null == tierKey ? _self.tierKey : tierKey // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SeatStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Seat].
extension SeatPatterns on Seat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Seat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Seat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Seat value)  $default,){
final _that = this;
switch (_that) {
case _Seat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Seat value)?  $default,){
final _that = this;
switch (_that) {
case _Seat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String seatId,  String row,  String seat,  String tierKey,  int x,  int y,  SeatStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Seat() when $default != null:
return $default(_that.seatId,_that.row,_that.seat,_that.tierKey,_that.x,_that.y,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String seatId,  String row,  String seat,  String tierKey,  int x,  int y,  SeatStatus status)  $default,) {final _that = this;
switch (_that) {
case _Seat():
return $default(_that.seatId,_that.row,_that.seat,_that.tierKey,_that.x,_that.y,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String seatId,  String row,  String seat,  String tierKey,  int x,  int y,  SeatStatus status)?  $default,) {final _that = this;
switch (_that) {
case _Seat() when $default != null:
return $default(_that.seatId,_that.row,_that.seat,_that.tierKey,_that.x,_that.y,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Seat implements Seat {
  const _Seat({this.seatId = '', this.row = '', this.seat = '', this.tierKey = '', this.x = 0, this.y = 0, this.status = SeatStatus.free});
  factory _Seat.fromJson(Map<String, dynamic> json) => _$SeatFromJson(json);

@override@JsonKey() final  String seatId;
@override@JsonKey() final  String row;
@override@JsonKey() final  String seat;
@override@JsonKey() final  String tierKey;
@override@JsonKey() final  int x;
@override@JsonKey() final  int y;
@override@JsonKey() final  SeatStatus status;

/// Create a copy of Seat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeatCopyWith<_Seat> get copyWith => __$SeatCopyWithImpl<_Seat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Seat&&(identical(other.seatId, seatId) || other.seatId == seatId)&&(identical(other.row, row) || other.row == row)&&(identical(other.seat, seat) || other.seat == seat)&&(identical(other.tierKey, tierKey) || other.tierKey == tierKey)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seatId,row,seat,tierKey,x,y,status);

@override
String toString() {
  return 'Seat(seatId: $seatId, row: $row, seat: $seat, tierKey: $tierKey, x: $x, y: $y, status: $status)';
}


}

/// @nodoc
abstract mixin class _$SeatCopyWith<$Res> implements $SeatCopyWith<$Res> {
  factory _$SeatCopyWith(_Seat value, $Res Function(_Seat) _then) = __$SeatCopyWithImpl;
@override @useResult
$Res call({
 String seatId, String row, String seat, String tierKey, int x, int y, SeatStatus status
});




}
/// @nodoc
class __$SeatCopyWithImpl<$Res>
    implements _$SeatCopyWith<$Res> {
  __$SeatCopyWithImpl(this._self, this._then);

  final _Seat _self;
  final $Res Function(_Seat) _then;

/// Create a copy of Seat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seatId = null,Object? row = null,Object? seat = null,Object? tierKey = null,Object? x = null,Object? y = null,Object? status = null,}) {
  return _then(_Seat(
seatId: null == seatId ? _self.seatId : seatId // ignore: cast_nullable_to_non_nullable
as String,row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as String,seat: null == seat ? _self.seat : seat // ignore: cast_nullable_to_non_nullable
as String,tierKey: null == tierKey ? _self.tierKey : tierKey // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SeatStatus,
  ));
}


}

// dart format on

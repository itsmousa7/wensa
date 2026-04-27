// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Booking {

 String get id; String get userId; String get merchantId; String? get placeId; String? get eventId; BookingCategory get category; BookingStatus get status; String get startsAt; String get endsAt; int get amountIqd; String? get paymentId; String? get paymentStatus; String get qrToken; String? get holdUntil; Map<String, dynamic> get categoryData; String? get groupId; String? get createdAt; String? get updatedAt;
/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingCopyWith<Booking> get copyWith => _$BookingCopyWithImpl<Booking>(this as Booking, _$identity);

  /// Serializes this Booking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Booking&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.merchantId, merchantId) || other.merchantId == merchantId)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.amountIqd, amountIqd) || other.amountIqd == amountIqd)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.holdUntil, holdUntil) || other.holdUntil == holdUntil)&&const DeepCollectionEquality().equals(other.categoryData, categoryData)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,merchantId,placeId,eventId,category,status,startsAt,endsAt,amountIqd,paymentId,paymentStatus,qrToken,holdUntil,const DeepCollectionEquality().hash(categoryData),groupId,createdAt,updatedAt);

@override
String toString() {
  return 'Booking(id: $id, userId: $userId, merchantId: $merchantId, placeId: $placeId, eventId: $eventId, category: $category, status: $status, startsAt: $startsAt, endsAt: $endsAt, amountIqd: $amountIqd, paymentId: $paymentId, paymentStatus: $paymentStatus, qrToken: $qrToken, holdUntil: $holdUntil, categoryData: $categoryData, groupId: $groupId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BookingCopyWith<$Res>  {
  factory $BookingCopyWith(Booking value, $Res Function(Booking) _then) = _$BookingCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String merchantId, String? placeId, String? eventId, BookingCategory category, BookingStatus status, String startsAt, String endsAt, int amountIqd, String? paymentId, String? paymentStatus, String qrToken, String? holdUntil, Map<String, dynamic> categoryData, String? groupId, String? createdAt, String? updatedAt
});




}
/// @nodoc
class _$BookingCopyWithImpl<$Res>
    implements $BookingCopyWith<$Res> {
  _$BookingCopyWithImpl(this._self, this._then);

  final Booking _self;
  final $Res Function(Booking) _then;

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? merchantId = null,Object? placeId = freezed,Object? eventId = freezed,Object? category = null,Object? status = null,Object? startsAt = null,Object? endsAt = null,Object? amountIqd = null,Object? paymentId = freezed,Object? paymentStatus = freezed,Object? qrToken = null,Object? holdUntil = freezed,Object? categoryData = null,Object? groupId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,merchantId: null == merchantId ? _self.merchantId : merchantId // ignore: cast_nullable_to_non_nullable
as String,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as BookingCategory,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as String,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as String,amountIqd: null == amountIqd ? _self.amountIqd : amountIqd // ignore: cast_nullable_to_non_nullable
as int,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,qrToken: null == qrToken ? _self.qrToken : qrToken // ignore: cast_nullable_to_non_nullable
as String,holdUntil: freezed == holdUntil ? _self.holdUntil : holdUntil // ignore: cast_nullable_to_non_nullable
as String?,categoryData: null == categoryData ? _self.categoryData : categoryData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Booking].
extension BookingPatterns on Booking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Booking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Booking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Booking value)  $default,){
final _that = this;
switch (_that) {
case _Booking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Booking value)?  $default,){
final _that = this;
switch (_that) {
case _Booking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String merchantId,  String? placeId,  String? eventId,  BookingCategory category,  BookingStatus status,  String startsAt,  String endsAt,  int amountIqd,  String? paymentId,  String? paymentStatus,  String qrToken,  String? holdUntil,  Map<String, dynamic> categoryData,  String? groupId,  String? createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Booking() when $default != null:
return $default(_that.id,_that.userId,_that.merchantId,_that.placeId,_that.eventId,_that.category,_that.status,_that.startsAt,_that.endsAt,_that.amountIqd,_that.paymentId,_that.paymentStatus,_that.qrToken,_that.holdUntil,_that.categoryData,_that.groupId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String merchantId,  String? placeId,  String? eventId,  BookingCategory category,  BookingStatus status,  String startsAt,  String endsAt,  int amountIqd,  String? paymentId,  String? paymentStatus,  String qrToken,  String? holdUntil,  Map<String, dynamic> categoryData,  String? groupId,  String? createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Booking():
return $default(_that.id,_that.userId,_that.merchantId,_that.placeId,_that.eventId,_that.category,_that.status,_that.startsAt,_that.endsAt,_that.amountIqd,_that.paymentId,_that.paymentStatus,_that.qrToken,_that.holdUntil,_that.categoryData,_that.groupId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String merchantId,  String? placeId,  String? eventId,  BookingCategory category,  BookingStatus status,  String startsAt,  String endsAt,  int amountIqd,  String? paymentId,  String? paymentStatus,  String qrToken,  String? holdUntil,  Map<String, dynamic> categoryData,  String? groupId,  String? createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Booking() when $default != null:
return $default(_that.id,_that.userId,_that.merchantId,_that.placeId,_that.eventId,_that.category,_that.status,_that.startsAt,_that.endsAt,_that.amountIqd,_that.paymentId,_that.paymentStatus,_that.qrToken,_that.holdUntil,_that.categoryData,_that.groupId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Booking implements Booking {
  const _Booking({this.id = '', this.userId = '', this.merchantId = '', this.placeId, this.eventId, this.category = BookingCategory.padel, this.status = BookingStatus.pending, this.startsAt = '', this.endsAt = '', this.amountIqd = 0, this.paymentId, this.paymentStatus, this.qrToken = '', this.holdUntil, final  Map<String, dynamic> categoryData = const <String, dynamic>{}, this.groupId, this.createdAt, this.updatedAt}): _categoryData = categoryData;
  factory _Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String userId;
@override@JsonKey() final  String merchantId;
@override final  String? placeId;
@override final  String? eventId;
@override@JsonKey() final  BookingCategory category;
@override@JsonKey() final  BookingStatus status;
@override@JsonKey() final  String startsAt;
@override@JsonKey() final  String endsAt;
@override@JsonKey() final  int amountIqd;
@override final  String? paymentId;
@override final  String? paymentStatus;
@override@JsonKey() final  String qrToken;
@override final  String? holdUntil;
 final  Map<String, dynamic> _categoryData;
@override@JsonKey() Map<String, dynamic> get categoryData {
  if (_categoryData is EqualUnmodifiableMapView) return _categoryData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryData);
}

@override final  String? groupId;
@override final  String? createdAt;
@override final  String? updatedAt;

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingCopyWith<_Booking> get copyWith => __$BookingCopyWithImpl<_Booking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Booking&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.merchantId, merchantId) || other.merchantId == merchantId)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.amountIqd, amountIqd) || other.amountIqd == amountIqd)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.holdUntil, holdUntil) || other.holdUntil == holdUntil)&&const DeepCollectionEquality().equals(other._categoryData, _categoryData)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,merchantId,placeId,eventId,category,status,startsAt,endsAt,amountIqd,paymentId,paymentStatus,qrToken,holdUntil,const DeepCollectionEquality().hash(_categoryData),groupId,createdAt,updatedAt);

@override
String toString() {
  return 'Booking(id: $id, userId: $userId, merchantId: $merchantId, placeId: $placeId, eventId: $eventId, category: $category, status: $status, startsAt: $startsAt, endsAt: $endsAt, amountIqd: $amountIqd, paymentId: $paymentId, paymentStatus: $paymentStatus, qrToken: $qrToken, holdUntil: $holdUntil, categoryData: $categoryData, groupId: $groupId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BookingCopyWith<$Res> implements $BookingCopyWith<$Res> {
  factory _$BookingCopyWith(_Booking value, $Res Function(_Booking) _then) = __$BookingCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String merchantId, String? placeId, String? eventId, BookingCategory category, BookingStatus status, String startsAt, String endsAt, int amountIqd, String? paymentId, String? paymentStatus, String qrToken, String? holdUntil, Map<String, dynamic> categoryData, String? groupId, String? createdAt, String? updatedAt
});




}
/// @nodoc
class __$BookingCopyWithImpl<$Res>
    implements _$BookingCopyWith<$Res> {
  __$BookingCopyWithImpl(this._self, this._then);

  final _Booking _self;
  final $Res Function(_Booking) _then;

/// Create a copy of Booking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? merchantId = null,Object? placeId = freezed,Object? eventId = freezed,Object? category = null,Object? status = null,Object? startsAt = null,Object? endsAt = null,Object? amountIqd = null,Object? paymentId = freezed,Object? paymentStatus = freezed,Object? qrToken = null,Object? holdUntil = freezed,Object? categoryData = null,Object? groupId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Booking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,merchantId: null == merchantId ? _self.merchantId : merchantId // ignore: cast_nullable_to_non_nullable
as String,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as BookingCategory,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as String,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as String,amountIqd: null == amountIqd ? _self.amountIqd : amountIqd // ignore: cast_nullable_to_non_nullable
as int,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,qrToken: null == qrToken ? _self.qrToken : qrToken // ignore: cast_nullable_to_non_nullable
as String,holdUntil: freezed == holdUntil ? _self.holdUntil : holdUntil // ignore: cast_nullable_to_non_nullable
as String?,categoryData: null == categoryData ? _self._categoryData : categoryData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

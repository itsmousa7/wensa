// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'membership.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Membership {

 String get id; String get userId; String get merchantId; String get placeId; String get planId; MembershipStatus get status; String get membershipType; String get startsAt; String get endsAt; int get amountIqd; String? get paymentId; String? get paymentStatus; String get qrToken; bool get isFrozen; String? get createdAt;
/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipCopyWith<Membership> get copyWith => _$MembershipCopyWithImpl<Membership>(this as Membership, _$identity);

  /// Serializes this Membership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Membership&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.merchantId, merchantId) || other.merchantId == merchantId)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.status, status) || other.status == status)&&(identical(other.membershipType, membershipType) || other.membershipType == membershipType)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.amountIqd, amountIqd) || other.amountIqd == amountIqd)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.isFrozen, isFrozen) || other.isFrozen == isFrozen)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,merchantId,placeId,planId,status,membershipType,startsAt,endsAt,amountIqd,paymentId,paymentStatus,qrToken,isFrozen,createdAt);

@override
String toString() {
  return 'Membership(id: $id, userId: $userId, merchantId: $merchantId, placeId: $placeId, planId: $planId, status: $status, membershipType: $membershipType, startsAt: $startsAt, endsAt: $endsAt, amountIqd: $amountIqd, paymentId: $paymentId, paymentStatus: $paymentStatus, qrToken: $qrToken, isFrozen: $isFrozen, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MembershipCopyWith<$Res>  {
  factory $MembershipCopyWith(Membership value, $Res Function(Membership) _then) = _$MembershipCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String merchantId, String placeId, String planId, MembershipStatus status, String membershipType, String startsAt, String endsAt, int amountIqd, String? paymentId, String? paymentStatus, String qrToken, bool isFrozen, String? createdAt
});




}
/// @nodoc
class _$MembershipCopyWithImpl<$Res>
    implements $MembershipCopyWith<$Res> {
  _$MembershipCopyWithImpl(this._self, this._then);

  final Membership _self;
  final $Res Function(Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? merchantId = null,Object? placeId = null,Object? planId = null,Object? status = null,Object? membershipType = null,Object? startsAt = null,Object? endsAt = null,Object? amountIqd = null,Object? paymentId = freezed,Object? paymentStatus = freezed,Object? qrToken = null,Object? isFrozen = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,merchantId: null == merchantId ? _self.merchantId : merchantId // ignore: cast_nullable_to_non_nullable
as String,placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MembershipStatus,membershipType: null == membershipType ? _self.membershipType : membershipType // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as String,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as String,amountIqd: null == amountIqd ? _self.amountIqd : amountIqd // ignore: cast_nullable_to_non_nullable
as int,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,qrToken: null == qrToken ? _self.qrToken : qrToken // ignore: cast_nullable_to_non_nullable
as String,isFrozen: null == isFrozen ? _self.isFrozen : isFrozen // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Membership].
extension MembershipPatterns on Membership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Membership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Membership value)  $default,){
final _that = this;
switch (_that) {
case _Membership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Membership value)?  $default,){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String merchantId,  String placeId,  String planId,  MembershipStatus status,  String membershipType,  String startsAt,  String endsAt,  int amountIqd,  String? paymentId,  String? paymentStatus,  String qrToken,  bool isFrozen,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.id,_that.userId,_that.merchantId,_that.placeId,_that.planId,_that.status,_that.membershipType,_that.startsAt,_that.endsAt,_that.amountIqd,_that.paymentId,_that.paymentStatus,_that.qrToken,_that.isFrozen,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String merchantId,  String placeId,  String planId,  MembershipStatus status,  String membershipType,  String startsAt,  String endsAt,  int amountIqd,  String? paymentId,  String? paymentStatus,  String qrToken,  bool isFrozen,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Membership():
return $default(_that.id,_that.userId,_that.merchantId,_that.placeId,_that.planId,_that.status,_that.membershipType,_that.startsAt,_that.endsAt,_that.amountIqd,_that.paymentId,_that.paymentStatus,_that.qrToken,_that.isFrozen,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String merchantId,  String placeId,  String planId,  MembershipStatus status,  String membershipType,  String startsAt,  String endsAt,  int amountIqd,  String? paymentId,  String? paymentStatus,  String qrToken,  bool isFrozen,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.id,_that.userId,_that.merchantId,_that.placeId,_that.planId,_that.status,_that.membershipType,_that.startsAt,_that.endsAt,_that.amountIqd,_that.paymentId,_that.paymentStatus,_that.qrToken,_that.isFrozen,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Membership implements Membership {
  const _Membership({this.id = '', this.userId = '', this.merchantId = '', this.placeId = '', this.planId = '', this.status = MembershipStatus.active, this.membershipType = '', this.startsAt = '', this.endsAt = '', this.amountIqd = 0, this.paymentId, this.paymentStatus, this.qrToken = '', this.isFrozen = false, this.createdAt});
  factory _Membership.fromJson(Map<String, dynamic> json) => _$MembershipFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String userId;
@override@JsonKey() final  String merchantId;
@override@JsonKey() final  String placeId;
@override@JsonKey() final  String planId;
@override@JsonKey() final  MembershipStatus status;
@override@JsonKey() final  String membershipType;
@override@JsonKey() final  String startsAt;
@override@JsonKey() final  String endsAt;
@override@JsonKey() final  int amountIqd;
@override final  String? paymentId;
@override final  String? paymentStatus;
@override@JsonKey() final  String qrToken;
@override@JsonKey() final  bool isFrozen;
@override final  String? createdAt;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipCopyWith<_Membership> get copyWith => __$MembershipCopyWithImpl<_Membership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Membership&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.merchantId, merchantId) || other.merchantId == merchantId)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.status, status) || other.status == status)&&(identical(other.membershipType, membershipType) || other.membershipType == membershipType)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.amountIqd, amountIqd) || other.amountIqd == amountIqd)&&(identical(other.paymentId, paymentId) || other.paymentId == paymentId)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.isFrozen, isFrozen) || other.isFrozen == isFrozen)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,merchantId,placeId,planId,status,membershipType,startsAt,endsAt,amountIqd,paymentId,paymentStatus,qrToken,isFrozen,createdAt);

@override
String toString() {
  return 'Membership(id: $id, userId: $userId, merchantId: $merchantId, placeId: $placeId, planId: $planId, status: $status, membershipType: $membershipType, startsAt: $startsAt, endsAt: $endsAt, amountIqd: $amountIqd, paymentId: $paymentId, paymentStatus: $paymentStatus, qrToken: $qrToken, isFrozen: $isFrozen, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MembershipCopyWith<$Res> implements $MembershipCopyWith<$Res> {
  factory _$MembershipCopyWith(_Membership value, $Res Function(_Membership) _then) = __$MembershipCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String merchantId, String placeId, String planId, MembershipStatus status, String membershipType, String startsAt, String endsAt, int amountIqd, String? paymentId, String? paymentStatus, String qrToken, bool isFrozen, String? createdAt
});




}
/// @nodoc
class __$MembershipCopyWithImpl<$Res>
    implements _$MembershipCopyWith<$Res> {
  __$MembershipCopyWithImpl(this._self, this._then);

  final _Membership _self;
  final $Res Function(_Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? merchantId = null,Object? placeId = null,Object? planId = null,Object? status = null,Object? membershipType = null,Object? startsAt = null,Object? endsAt = null,Object? amountIqd = null,Object? paymentId = freezed,Object? paymentStatus = freezed,Object? qrToken = null,Object? isFrozen = null,Object? createdAt = freezed,}) {
  return _then(_Membership(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,merchantId: null == merchantId ? _self.merchantId : merchantId // ignore: cast_nullable_to_non_nullable
as String,placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MembershipStatus,membershipType: null == membershipType ? _self.membershipType : membershipType // ignore: cast_nullable_to_non_nullable
as String,startsAt: null == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as String,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as String,amountIqd: null == amountIqd ? _self.amountIqd : amountIqd // ignore: cast_nullable_to_non_nullable
as int,paymentId: freezed == paymentId ? _self.paymentId : paymentId // ignore: cast_nullable_to_non_nullable
as String?,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,qrToken: null == qrToken ? _self.qrToken : qrToken // ignore: cast_nullable_to_non_nullable
as String,isFrozen: null == isFrozen ? _self.isFrozen : isFrozen // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

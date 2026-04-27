// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'membership_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MembershipPlan {

 String get id; String get placeId; String get membershipType; String get nameAr; String get nameEn; int get durationDays; int get priceIqd; bool get allowFreeze; bool get isActive;
/// Create a copy of MembershipPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipPlanCopyWith<MembershipPlan> get copyWith => _$MembershipPlanCopyWithImpl<MembershipPlan>(this as MembershipPlan, _$identity);

  /// Serializes this MembershipPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.membershipType, membershipType) || other.membershipType == membershipType)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.priceIqd, priceIqd) || other.priceIqd == priceIqd)&&(identical(other.allowFreeze, allowFreeze) || other.allowFreeze == allowFreeze)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,placeId,membershipType,nameAr,nameEn,durationDays,priceIqd,allowFreeze,isActive);

@override
String toString() {
  return 'MembershipPlan(id: $id, placeId: $placeId, membershipType: $membershipType, nameAr: $nameAr, nameEn: $nameEn, durationDays: $durationDays, priceIqd: $priceIqd, allowFreeze: $allowFreeze, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $MembershipPlanCopyWith<$Res>  {
  factory $MembershipPlanCopyWith(MembershipPlan value, $Res Function(MembershipPlan) _then) = _$MembershipPlanCopyWithImpl;
@useResult
$Res call({
 String id, String placeId, String membershipType, String nameAr, String nameEn, int durationDays, int priceIqd, bool allowFreeze, bool isActive
});




}
/// @nodoc
class _$MembershipPlanCopyWithImpl<$Res>
    implements $MembershipPlanCopyWith<$Res> {
  _$MembershipPlanCopyWithImpl(this._self, this._then);

  final MembershipPlan _self;
  final $Res Function(MembershipPlan) _then;

/// Create a copy of MembershipPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? placeId = null,Object? membershipType = null,Object? nameAr = null,Object? nameEn = null,Object? durationDays = null,Object? priceIqd = null,Object? allowFreeze = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,membershipType: null == membershipType ? _self.membershipType : membershipType // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,priceIqd: null == priceIqd ? _self.priceIqd : priceIqd // ignore: cast_nullable_to_non_nullable
as int,allowFreeze: null == allowFreeze ? _self.allowFreeze : allowFreeze // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MembershipPlan].
extension MembershipPlanPatterns on MembershipPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MembershipPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MembershipPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MembershipPlan value)  $default,){
final _that = this;
switch (_that) {
case _MembershipPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MembershipPlan value)?  $default,){
final _that = this;
switch (_that) {
case _MembershipPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String placeId,  String membershipType,  String nameAr,  String nameEn,  int durationDays,  int priceIqd,  bool allowFreeze,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MembershipPlan() when $default != null:
return $default(_that.id,_that.placeId,_that.membershipType,_that.nameAr,_that.nameEn,_that.durationDays,_that.priceIqd,_that.allowFreeze,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String placeId,  String membershipType,  String nameAr,  String nameEn,  int durationDays,  int priceIqd,  bool allowFreeze,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _MembershipPlan():
return $default(_that.id,_that.placeId,_that.membershipType,_that.nameAr,_that.nameEn,_that.durationDays,_that.priceIqd,_that.allowFreeze,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String placeId,  String membershipType,  String nameAr,  String nameEn,  int durationDays,  int priceIqd,  bool allowFreeze,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _MembershipPlan() when $default != null:
return $default(_that.id,_that.placeId,_that.membershipType,_that.nameAr,_that.nameEn,_that.durationDays,_that.priceIqd,_that.allowFreeze,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MembershipPlan implements MembershipPlan {
  const _MembershipPlan({this.id = '', this.placeId = '', this.membershipType = '', this.nameAr = '', this.nameEn = '', this.durationDays = 0, this.priceIqd = 0, this.allowFreeze = false, this.isActive = false});
  factory _MembershipPlan.fromJson(Map<String, dynamic> json) => _$MembershipPlanFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String placeId;
@override@JsonKey() final  String membershipType;
@override@JsonKey() final  String nameAr;
@override@JsonKey() final  String nameEn;
@override@JsonKey() final  int durationDays;
@override@JsonKey() final  int priceIqd;
@override@JsonKey() final  bool allowFreeze;
@override@JsonKey() final  bool isActive;

/// Create a copy of MembershipPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipPlanCopyWith<_MembershipPlan> get copyWith => __$MembershipPlanCopyWithImpl<_MembershipPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MembershipPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.membershipType, membershipType) || other.membershipType == membershipType)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.priceIqd, priceIqd) || other.priceIqd == priceIqd)&&(identical(other.allowFreeze, allowFreeze) || other.allowFreeze == allowFreeze)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,placeId,membershipType,nameAr,nameEn,durationDays,priceIqd,allowFreeze,isActive);

@override
String toString() {
  return 'MembershipPlan(id: $id, placeId: $placeId, membershipType: $membershipType, nameAr: $nameAr, nameEn: $nameEn, durationDays: $durationDays, priceIqd: $priceIqd, allowFreeze: $allowFreeze, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$MembershipPlanCopyWith<$Res> implements $MembershipPlanCopyWith<$Res> {
  factory _$MembershipPlanCopyWith(_MembershipPlan value, $Res Function(_MembershipPlan) _then) = __$MembershipPlanCopyWithImpl;
@override @useResult
$Res call({
 String id, String placeId, String membershipType, String nameAr, String nameEn, int durationDays, int priceIqd, bool allowFreeze, bool isActive
});




}
/// @nodoc
class __$MembershipPlanCopyWithImpl<$Res>
    implements _$MembershipPlanCopyWith<$Res> {
  __$MembershipPlanCopyWithImpl(this._self, this._then);

  final _MembershipPlan _self;
  final $Res Function(_MembershipPlan) _then;

/// Create a copy of MembershipPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? placeId = null,Object? membershipType = null,Object? nameAr = null,Object? nameEn = null,Object? durationDays = null,Object? priceIqd = null,Object? allowFreeze = null,Object? isActive = null,}) {
  return _then(_MembershipPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,membershipType: null == membershipType ? _self.membershipType : membershipType // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,priceIqd: null == priceIqd ? _self.priceIqd : priceIqd // ignore: cast_nullable_to_non_nullable
as int,allowFreeze: null == allowFreeze ? _self.allowFreeze : allowFreeze // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promoted_banner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PromotedBannerModel {

 String get id; String? get placeId; String get imageUrl; String? get actionUrl; String get startDate; String get endDate; bool get isActive; String? get createdAt;
/// Create a copy of PromotedBannerModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromotedBannerModelCopyWith<PromotedBannerModel> get copyWith => _$PromotedBannerModelCopyWithImpl<PromotedBannerModel>(this as PromotedBannerModel, _$identity);

  /// Serializes this PromotedBannerModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromotedBannerModel&&(identical(other.id, id) || other.id == id)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.actionUrl, actionUrl) || other.actionUrl == actionUrl)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,placeId,imageUrl,actionUrl,startDate,endDate,isActive,createdAt);

@override
String toString() {
  return 'PromotedBannerModel(id: $id, placeId: $placeId, imageUrl: $imageUrl, actionUrl: $actionUrl, startDate: $startDate, endDate: $endDate, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PromotedBannerModelCopyWith<$Res>  {
  factory $PromotedBannerModelCopyWith(PromotedBannerModel value, $Res Function(PromotedBannerModel) _then) = _$PromotedBannerModelCopyWithImpl;
@useResult
$Res call({
 String id, String? placeId, String imageUrl, String? actionUrl, String startDate, String endDate, bool isActive, String? createdAt
});




}
/// @nodoc
class _$PromotedBannerModelCopyWithImpl<$Res>
    implements $PromotedBannerModelCopyWith<$Res> {
  _$PromotedBannerModelCopyWithImpl(this._self, this._then);

  final PromotedBannerModel _self;
  final $Res Function(PromotedBannerModel) _then;

/// Create a copy of PromotedBannerModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? placeId = freezed,Object? imageUrl = null,Object? actionUrl = freezed,Object? startDate = null,Object? endDate = null,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,actionUrl: freezed == actionUrl ? _self.actionUrl : actionUrl // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PromotedBannerModel].
extension PromotedBannerModelPatterns on PromotedBannerModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromotedBannerModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromotedBannerModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromotedBannerModel value)  $default,){
final _that = this;
switch (_that) {
case _PromotedBannerModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromotedBannerModel value)?  $default,){
final _that = this;
switch (_that) {
case _PromotedBannerModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? placeId,  String imageUrl,  String? actionUrl,  String startDate,  String endDate,  bool isActive,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromotedBannerModel() when $default != null:
return $default(_that.id,_that.placeId,_that.imageUrl,_that.actionUrl,_that.startDate,_that.endDate,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? placeId,  String imageUrl,  String? actionUrl,  String startDate,  String endDate,  bool isActive,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PromotedBannerModel():
return $default(_that.id,_that.placeId,_that.imageUrl,_that.actionUrl,_that.startDate,_that.endDate,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? placeId,  String imageUrl,  String? actionUrl,  String startDate,  String endDate,  bool isActive,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PromotedBannerModel() when $default != null:
return $default(_that.id,_that.placeId,_that.imageUrl,_that.actionUrl,_that.startDate,_that.endDate,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PromotedBannerModel implements PromotedBannerModel {
  const _PromotedBannerModel({this.id = '', this.placeId, this.imageUrl = '', this.actionUrl, this.startDate = '', this.endDate = '', this.isActive = true, this.createdAt});
  factory _PromotedBannerModel.fromJson(Map<String, dynamic> json) => _$PromotedBannerModelFromJson(json);

@override@JsonKey() final  String id;
@override final  String? placeId;
@override@JsonKey() final  String imageUrl;
@override final  String? actionUrl;
@override@JsonKey() final  String startDate;
@override@JsonKey() final  String endDate;
@override@JsonKey() final  bool isActive;
@override final  String? createdAt;

/// Create a copy of PromotedBannerModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromotedBannerModelCopyWith<_PromotedBannerModel> get copyWith => __$PromotedBannerModelCopyWithImpl<_PromotedBannerModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PromotedBannerModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromotedBannerModel&&(identical(other.id, id) || other.id == id)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.actionUrl, actionUrl) || other.actionUrl == actionUrl)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,placeId,imageUrl,actionUrl,startDate,endDate,isActive,createdAt);

@override
String toString() {
  return 'PromotedBannerModel(id: $id, placeId: $placeId, imageUrl: $imageUrl, actionUrl: $actionUrl, startDate: $startDate, endDate: $endDate, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PromotedBannerModelCopyWith<$Res> implements $PromotedBannerModelCopyWith<$Res> {
  factory _$PromotedBannerModelCopyWith(_PromotedBannerModel value, $Res Function(_PromotedBannerModel) _then) = __$PromotedBannerModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? placeId, String imageUrl, String? actionUrl, String startDate, String endDate, bool isActive, String? createdAt
});




}
/// @nodoc
class __$PromotedBannerModelCopyWithImpl<$Res>
    implements _$PromotedBannerModelCopyWith<$Res> {
  __$PromotedBannerModelCopyWithImpl(this._self, this._then);

  final _PromotedBannerModel _self;
  final $Res Function(_PromotedBannerModel) _then;

/// Create a copy of PromotedBannerModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? placeId = freezed,Object? imageUrl = null,Object? actionUrl = freezed,Object? startDate = null,Object? endDate = null,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_PromotedBannerModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,actionUrl: freezed == actionUrl ? _self.actionUrl : actionUrl // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

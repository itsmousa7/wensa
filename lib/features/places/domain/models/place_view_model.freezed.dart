// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaceViewModel {

 String get id; String get placeId; String get userId; String? get viewedAt;
/// Create a copy of PlaceViewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceViewModelCopyWith<PlaceViewModel> get copyWith => _$PlaceViewModelCopyWithImpl<PlaceViewModel>(this as PlaceViewModel, _$identity);

  /// Serializes this PlaceViewModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceViewModel&&(identical(other.id, id) || other.id == id)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.viewedAt, viewedAt) || other.viewedAt == viewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,placeId,userId,viewedAt);

@override
String toString() {
  return 'PlaceViewModel(id: $id, placeId: $placeId, userId: $userId, viewedAt: $viewedAt)';
}


}

/// @nodoc
abstract mixin class $PlaceViewModelCopyWith<$Res>  {
  factory $PlaceViewModelCopyWith(PlaceViewModel value, $Res Function(PlaceViewModel) _then) = _$PlaceViewModelCopyWithImpl;
@useResult
$Res call({
 String id, String placeId, String userId, String? viewedAt
});




}
/// @nodoc
class _$PlaceViewModelCopyWithImpl<$Res>
    implements $PlaceViewModelCopyWith<$Res> {
  _$PlaceViewModelCopyWithImpl(this._self, this._then);

  final PlaceViewModel _self;
  final $Res Function(PlaceViewModel) _then;

/// Create a copy of PlaceViewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? placeId = null,Object? userId = null,Object? viewedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,viewedAt: freezed == viewedAt ? _self.viewedAt : viewedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaceViewModel].
extension PlaceViewModelPatterns on PlaceViewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceViewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceViewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceViewModel value)  $default,){
final _that = this;
switch (_that) {
case _PlaceViewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceViewModel value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceViewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String placeId,  String userId,  String? viewedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceViewModel() when $default != null:
return $default(_that.id,_that.placeId,_that.userId,_that.viewedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String placeId,  String userId,  String? viewedAt)  $default,) {final _that = this;
switch (_that) {
case _PlaceViewModel():
return $default(_that.id,_that.placeId,_that.userId,_that.viewedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String placeId,  String userId,  String? viewedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlaceViewModel() when $default != null:
return $default(_that.id,_that.placeId,_that.userId,_that.viewedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaceViewModel implements PlaceViewModel {
  const _PlaceViewModel({this.id = '', this.placeId = '', this.userId = '', this.viewedAt});
  factory _PlaceViewModel.fromJson(Map<String, dynamic> json) => _$PlaceViewModelFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String placeId;
@override@JsonKey() final  String userId;
@override final  String? viewedAt;

/// Create a copy of PlaceViewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceViewModelCopyWith<_PlaceViewModel> get copyWith => __$PlaceViewModelCopyWithImpl<_PlaceViewModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceViewModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceViewModel&&(identical(other.id, id) || other.id == id)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.viewedAt, viewedAt) || other.viewedAt == viewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,placeId,userId,viewedAt);

@override
String toString() {
  return 'PlaceViewModel(id: $id, placeId: $placeId, userId: $userId, viewedAt: $viewedAt)';
}


}

/// @nodoc
abstract mixin class _$PlaceViewModelCopyWith<$Res> implements $PlaceViewModelCopyWith<$Res> {
  factory _$PlaceViewModelCopyWith(_PlaceViewModel value, $Res Function(_PlaceViewModel) _then) = __$PlaceViewModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String placeId, String userId, String? viewedAt
});




}
/// @nodoc
class __$PlaceViewModelCopyWithImpl<$Res>
    implements _$PlaceViewModelCopyWith<$Res> {
  __$PlaceViewModelCopyWithImpl(this._self, this._then);

  final _PlaceViewModel _self;
  final $Res Function(_PlaceViewModel) _then;

/// Create a copy of PlaceViewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? placeId = null,Object? userId = null,Object? viewedAt = freezed,}) {
  return _then(_PlaceViewModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,viewedAt: freezed == viewedAt ? _self.viewedAt : viewedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

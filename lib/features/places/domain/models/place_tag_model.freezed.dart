// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_tag_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaceTagModel {

 String get placeId; String get tagId;
/// Create a copy of PlaceTagModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceTagModelCopyWith<PlaceTagModel> get copyWith => _$PlaceTagModelCopyWithImpl<PlaceTagModel>(this as PlaceTagModel, _$identity);

  /// Serializes this PlaceTagModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceTagModel&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.tagId, tagId) || other.tagId == tagId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,placeId,tagId);

@override
String toString() {
  return 'PlaceTagModel(placeId: $placeId, tagId: $tagId)';
}


}

/// @nodoc
abstract mixin class $PlaceTagModelCopyWith<$Res>  {
  factory $PlaceTagModelCopyWith(PlaceTagModel value, $Res Function(PlaceTagModel) _then) = _$PlaceTagModelCopyWithImpl;
@useResult
$Res call({
 String placeId, String tagId
});




}
/// @nodoc
class _$PlaceTagModelCopyWithImpl<$Res>
    implements $PlaceTagModelCopyWith<$Res> {
  _$PlaceTagModelCopyWithImpl(this._self, this._then);

  final PlaceTagModel _self;
  final $Res Function(PlaceTagModel) _then;

/// Create a copy of PlaceTagModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? placeId = null,Object? tagId = null,}) {
  return _then(_self.copyWith(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,tagId: null == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaceTagModel].
extension PlaceTagModelPatterns on PlaceTagModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceTagModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceTagModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceTagModel value)  $default,){
final _that = this;
switch (_that) {
case _PlaceTagModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceTagModel value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceTagModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String placeId,  String tagId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceTagModel() when $default != null:
return $default(_that.placeId,_that.tagId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String placeId,  String tagId)  $default,) {final _that = this;
switch (_that) {
case _PlaceTagModel():
return $default(_that.placeId,_that.tagId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String placeId,  String tagId)?  $default,) {final _that = this;
switch (_that) {
case _PlaceTagModel() when $default != null:
return $default(_that.placeId,_that.tagId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaceTagModel implements PlaceTagModel {
  const _PlaceTagModel({this.placeId = '', this.tagId = ''});
  factory _PlaceTagModel.fromJson(Map<String, dynamic> json) => _$PlaceTagModelFromJson(json);

@override@JsonKey() final  String placeId;
@override@JsonKey() final  String tagId;

/// Create a copy of PlaceTagModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceTagModelCopyWith<_PlaceTagModel> get copyWith => __$PlaceTagModelCopyWithImpl<_PlaceTagModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceTagModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceTagModel&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.tagId, tagId) || other.tagId == tagId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,placeId,tagId);

@override
String toString() {
  return 'PlaceTagModel(placeId: $placeId, tagId: $tagId)';
}


}

/// @nodoc
abstract mixin class _$PlaceTagModelCopyWith<$Res> implements $PlaceTagModelCopyWith<$Res> {
  factory _$PlaceTagModelCopyWith(_PlaceTagModel value, $Res Function(_PlaceTagModel) _then) = __$PlaceTagModelCopyWithImpl;
@override @useResult
$Res call({
 String placeId, String tagId
});




}
/// @nodoc
class __$PlaceTagModelCopyWithImpl<$Res>
    implements _$PlaceTagModelCopyWith<$Res> {
  __$PlaceTagModelCopyWithImpl(this._self, this._then);

  final _PlaceTagModel _self;
  final $Res Function(_PlaceTagModel) _then;

/// Create a copy of PlaceTagModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? placeId = null,Object? tagId = null,}) {
  return _then(_PlaceTagModel(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,tagId: null == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

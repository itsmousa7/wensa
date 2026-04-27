// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant_seating_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RestaurantSeatingOption {

 String get id; String get placeId; String get labelAr; String get labelEn; bool get isActive;
/// Create a copy of RestaurantSeatingOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestaurantSeatingOptionCopyWith<RestaurantSeatingOption> get copyWith => _$RestaurantSeatingOptionCopyWithImpl<RestaurantSeatingOption>(this as RestaurantSeatingOption, _$identity);

  /// Serializes this RestaurantSeatingOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestaurantSeatingOption&&(identical(other.id, id) || other.id == id)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.labelAr, labelAr) || other.labelAr == labelAr)&&(identical(other.labelEn, labelEn) || other.labelEn == labelEn)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,placeId,labelAr,labelEn,isActive);

@override
String toString() {
  return 'RestaurantSeatingOption(id: $id, placeId: $placeId, labelAr: $labelAr, labelEn: $labelEn, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $RestaurantSeatingOptionCopyWith<$Res>  {
  factory $RestaurantSeatingOptionCopyWith(RestaurantSeatingOption value, $Res Function(RestaurantSeatingOption) _then) = _$RestaurantSeatingOptionCopyWithImpl;
@useResult
$Res call({
 String id, String placeId, String labelAr, String labelEn, bool isActive
});




}
/// @nodoc
class _$RestaurantSeatingOptionCopyWithImpl<$Res>
    implements $RestaurantSeatingOptionCopyWith<$Res> {
  _$RestaurantSeatingOptionCopyWithImpl(this._self, this._then);

  final RestaurantSeatingOption _self;
  final $Res Function(RestaurantSeatingOption) _then;

/// Create a copy of RestaurantSeatingOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? placeId = null,Object? labelAr = null,Object? labelEn = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,labelAr: null == labelAr ? _self.labelAr : labelAr // ignore: cast_nullable_to_non_nullable
as String,labelEn: null == labelEn ? _self.labelEn : labelEn // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RestaurantSeatingOption].
extension RestaurantSeatingOptionPatterns on RestaurantSeatingOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestaurantSeatingOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestaurantSeatingOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestaurantSeatingOption value)  $default,){
final _that = this;
switch (_that) {
case _RestaurantSeatingOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestaurantSeatingOption value)?  $default,){
final _that = this;
switch (_that) {
case _RestaurantSeatingOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String placeId,  String labelAr,  String labelEn,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestaurantSeatingOption() when $default != null:
return $default(_that.id,_that.placeId,_that.labelAr,_that.labelEn,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String placeId,  String labelAr,  String labelEn,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _RestaurantSeatingOption():
return $default(_that.id,_that.placeId,_that.labelAr,_that.labelEn,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String placeId,  String labelAr,  String labelEn,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _RestaurantSeatingOption() when $default != null:
return $default(_that.id,_that.placeId,_that.labelAr,_that.labelEn,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RestaurantSeatingOption implements RestaurantSeatingOption {
  const _RestaurantSeatingOption({this.id = '', this.placeId = '', this.labelAr = '', this.labelEn = '', this.isActive = true});
  factory _RestaurantSeatingOption.fromJson(Map<String, dynamic> json) => _$RestaurantSeatingOptionFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String placeId;
@override@JsonKey() final  String labelAr;
@override@JsonKey() final  String labelEn;
@override@JsonKey() final  bool isActive;

/// Create a copy of RestaurantSeatingOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestaurantSeatingOptionCopyWith<_RestaurantSeatingOption> get copyWith => __$RestaurantSeatingOptionCopyWithImpl<_RestaurantSeatingOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestaurantSeatingOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestaurantSeatingOption&&(identical(other.id, id) || other.id == id)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.labelAr, labelAr) || other.labelAr == labelAr)&&(identical(other.labelEn, labelEn) || other.labelEn == labelEn)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,placeId,labelAr,labelEn,isActive);

@override
String toString() {
  return 'RestaurantSeatingOption(id: $id, placeId: $placeId, labelAr: $labelAr, labelEn: $labelEn, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$RestaurantSeatingOptionCopyWith<$Res> implements $RestaurantSeatingOptionCopyWith<$Res> {
  factory _$RestaurantSeatingOptionCopyWith(_RestaurantSeatingOption value, $Res Function(_RestaurantSeatingOption) _then) = __$RestaurantSeatingOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String placeId, String labelAr, String labelEn, bool isActive
});




}
/// @nodoc
class __$RestaurantSeatingOptionCopyWithImpl<$Res>
    implements _$RestaurantSeatingOptionCopyWith<$Res> {
  __$RestaurantSeatingOptionCopyWithImpl(this._self, this._then);

  final _RestaurantSeatingOption _self;
  final $Res Function(_RestaurantSeatingOption) _then;

/// Create a copy of RestaurantSeatingOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? placeId = null,Object? labelAr = null,Object? labelEn = null,Object? isActive = null,}) {
  return _then(_RestaurantSeatingOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,labelAr: null == labelAr ? _self.labelAr : labelAr // ignore: cast_nullable_to_non_nullable
as String,labelEn: null == labelEn ? _self.labelEn : labelEn // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

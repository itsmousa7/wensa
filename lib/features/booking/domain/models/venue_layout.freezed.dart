// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_layout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VenueLayout {

 String get seatMapId; double get canvasWidth; double get canvasHeight; String? get backgroundImageUrl; List<VenueSection> get sections;
/// Create a copy of VenueLayout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueLayoutCopyWith<VenueLayout> get copyWith => _$VenueLayoutCopyWithImpl<VenueLayout>(this as VenueLayout, _$identity);

  /// Serializes this VenueLayout to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VenueLayout&&(identical(other.seatMapId, seatMapId) || other.seatMapId == seatMapId)&&(identical(other.canvasWidth, canvasWidth) || other.canvasWidth == canvasWidth)&&(identical(other.canvasHeight, canvasHeight) || other.canvasHeight == canvasHeight)&&(identical(other.backgroundImageUrl, backgroundImageUrl) || other.backgroundImageUrl == backgroundImageUrl)&&const DeepCollectionEquality().equals(other.sections, sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seatMapId,canvasWidth,canvasHeight,backgroundImageUrl,const DeepCollectionEquality().hash(sections));

@override
String toString() {
  return 'VenueLayout(seatMapId: $seatMapId, canvasWidth: $canvasWidth, canvasHeight: $canvasHeight, backgroundImageUrl: $backgroundImageUrl, sections: $sections)';
}


}

/// @nodoc
abstract mixin class $VenueLayoutCopyWith<$Res>  {
  factory $VenueLayoutCopyWith(VenueLayout value, $Res Function(VenueLayout) _then) = _$VenueLayoutCopyWithImpl;
@useResult
$Res call({
 String seatMapId, double canvasWidth, double canvasHeight, String? backgroundImageUrl, List<VenueSection> sections
});




}
/// @nodoc
class _$VenueLayoutCopyWithImpl<$Res>
    implements $VenueLayoutCopyWith<$Res> {
  _$VenueLayoutCopyWithImpl(this._self, this._then);

  final VenueLayout _self;
  final $Res Function(VenueLayout) _then;

/// Create a copy of VenueLayout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seatMapId = null,Object? canvasWidth = null,Object? canvasHeight = null,Object? backgroundImageUrl = freezed,Object? sections = null,}) {
  return _then(_self.copyWith(
seatMapId: null == seatMapId ? _self.seatMapId : seatMapId // ignore: cast_nullable_to_non_nullable
as String,canvasWidth: null == canvasWidth ? _self.canvasWidth : canvasWidth // ignore: cast_nullable_to_non_nullable
as double,canvasHeight: null == canvasHeight ? _self.canvasHeight : canvasHeight // ignore: cast_nullable_to_non_nullable
as double,backgroundImageUrl: freezed == backgroundImageUrl ? _self.backgroundImageUrl : backgroundImageUrl // ignore: cast_nullable_to_non_nullable
as String?,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<VenueSection>,
  ));
}

}


/// Adds pattern-matching-related methods to [VenueLayout].
extension VenueLayoutPatterns on VenueLayout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VenueLayout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VenueLayout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VenueLayout value)  $default,){
final _that = this;
switch (_that) {
case _VenueLayout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VenueLayout value)?  $default,){
final _that = this;
switch (_that) {
case _VenueLayout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String seatMapId,  double canvasWidth,  double canvasHeight,  String? backgroundImageUrl,  List<VenueSection> sections)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VenueLayout() when $default != null:
return $default(_that.seatMapId,_that.canvasWidth,_that.canvasHeight,_that.backgroundImageUrl,_that.sections);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String seatMapId,  double canvasWidth,  double canvasHeight,  String? backgroundImageUrl,  List<VenueSection> sections)  $default,) {final _that = this;
switch (_that) {
case _VenueLayout():
return $default(_that.seatMapId,_that.canvasWidth,_that.canvasHeight,_that.backgroundImageUrl,_that.sections);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String seatMapId,  double canvasWidth,  double canvasHeight,  String? backgroundImageUrl,  List<VenueSection> sections)?  $default,) {final _that = this;
switch (_that) {
case _VenueLayout() when $default != null:
return $default(_that.seatMapId,_that.canvasWidth,_that.canvasHeight,_that.backgroundImageUrl,_that.sections);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VenueLayout implements VenueLayout {
  const _VenueLayout({this.seatMapId = '', this.canvasWidth = 1200, this.canvasHeight = 800, this.backgroundImageUrl, final  List<VenueSection> sections = const <VenueSection>[]}): _sections = sections;
  factory _VenueLayout.fromJson(Map<String, dynamic> json) => _$VenueLayoutFromJson(json);

@override@JsonKey() final  String seatMapId;
@override@JsonKey() final  double canvasWidth;
@override@JsonKey() final  double canvasHeight;
@override final  String? backgroundImageUrl;
 final  List<VenueSection> _sections;
@override@JsonKey() List<VenueSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}


/// Create a copy of VenueLayout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueLayoutCopyWith<_VenueLayout> get copyWith => __$VenueLayoutCopyWithImpl<_VenueLayout>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VenueLayoutToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VenueLayout&&(identical(other.seatMapId, seatMapId) || other.seatMapId == seatMapId)&&(identical(other.canvasWidth, canvasWidth) || other.canvasWidth == canvasWidth)&&(identical(other.canvasHeight, canvasHeight) || other.canvasHeight == canvasHeight)&&(identical(other.backgroundImageUrl, backgroundImageUrl) || other.backgroundImageUrl == backgroundImageUrl)&&const DeepCollectionEquality().equals(other._sections, _sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seatMapId,canvasWidth,canvasHeight,backgroundImageUrl,const DeepCollectionEquality().hash(_sections));

@override
String toString() {
  return 'VenueLayout(seatMapId: $seatMapId, canvasWidth: $canvasWidth, canvasHeight: $canvasHeight, backgroundImageUrl: $backgroundImageUrl, sections: $sections)';
}


}

/// @nodoc
abstract mixin class _$VenueLayoutCopyWith<$Res> implements $VenueLayoutCopyWith<$Res> {
  factory _$VenueLayoutCopyWith(_VenueLayout value, $Res Function(_VenueLayout) _then) = __$VenueLayoutCopyWithImpl;
@override @useResult
$Res call({
 String seatMapId, double canvasWidth, double canvasHeight, String? backgroundImageUrl, List<VenueSection> sections
});




}
/// @nodoc
class __$VenueLayoutCopyWithImpl<$Res>
    implements _$VenueLayoutCopyWith<$Res> {
  __$VenueLayoutCopyWithImpl(this._self, this._then);

  final _VenueLayout _self;
  final $Res Function(_VenueLayout) _then;

/// Create a copy of VenueLayout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seatMapId = null,Object? canvasWidth = null,Object? canvasHeight = null,Object? backgroundImageUrl = freezed,Object? sections = null,}) {
  return _then(_VenueLayout(
seatMapId: null == seatMapId ? _self.seatMapId : seatMapId // ignore: cast_nullable_to_non_nullable
as String,canvasWidth: null == canvasWidth ? _self.canvasWidth : canvasWidth // ignore: cast_nullable_to_non_nullable
as double,canvasHeight: null == canvasHeight ? _self.canvasHeight : canvasHeight // ignore: cast_nullable_to_non_nullable
as double,backgroundImageUrl: freezed == backgroundImageUrl ? _self.backgroundImageUrl : backgroundImageUrl // ignore: cast_nullable_to_non_nullable
as String?,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<VenueSection>,
  ));
}


}

// dart format on

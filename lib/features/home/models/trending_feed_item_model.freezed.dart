// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trending_feed_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrendingFeedItemModel {

 String get id; String get type;// 'place' | 'event'
 String get titleAr; String get titleEn; String? get coverImageUrl; String? get city; String? get subtitleAr;// منطقة للمكان / تاريخ للحدث
 String? get subtitleEn; double get hotnessScore; bool get isVerified; bool get isFeatured; String? get eventStartDate;// null إذا كان place
 double? get ticketPrice;
/// Create a copy of TrendingFeedItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrendingFeedItemModelCopyWith<TrendingFeedItemModel> get copyWith => _$TrendingFeedItemModelCopyWithImpl<TrendingFeedItemModel>(this as TrendingFeedItemModel, _$identity);

  /// Serializes this TrendingFeedItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrendingFeedItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.city, city) || other.city == city)&&(identical(other.subtitleAr, subtitleAr) || other.subtitleAr == subtitleAr)&&(identical(other.subtitleEn, subtitleEn) || other.subtitleEn == subtitleEn)&&(identical(other.hotnessScore, hotnessScore) || other.hotnessScore == hotnessScore)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.eventStartDate, eventStartDate) || other.eventStartDate == eventStartDate)&&(identical(other.ticketPrice, ticketPrice) || other.ticketPrice == ticketPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,titleAr,titleEn,coverImageUrl,city,subtitleAr,subtitleEn,hotnessScore,isVerified,isFeatured,eventStartDate,ticketPrice);

@override
String toString() {
  return 'TrendingFeedItemModel(id: $id, type: $type, titleAr: $titleAr, titleEn: $titleEn, coverImageUrl: $coverImageUrl, city: $city, subtitleAr: $subtitleAr, subtitleEn: $subtitleEn, hotnessScore: $hotnessScore, isVerified: $isVerified, isFeatured: $isFeatured, eventStartDate: $eventStartDate, ticketPrice: $ticketPrice)';
}


}

/// @nodoc
abstract mixin class $TrendingFeedItemModelCopyWith<$Res>  {
  factory $TrendingFeedItemModelCopyWith(TrendingFeedItemModel value, $Res Function(TrendingFeedItemModel) _then) = _$TrendingFeedItemModelCopyWithImpl;
@useResult
$Res call({
 String id, String type, String titleAr, String titleEn, String? coverImageUrl, String? city, String? subtitleAr, String? subtitleEn, double hotnessScore, bool isVerified, bool isFeatured, String? eventStartDate, double? ticketPrice
});




}
/// @nodoc
class _$TrendingFeedItemModelCopyWithImpl<$Res>
    implements $TrendingFeedItemModelCopyWith<$Res> {
  _$TrendingFeedItemModelCopyWithImpl(this._self, this._then);

  final TrendingFeedItemModel _self;
  final $Res Function(TrendingFeedItemModel) _then;

/// Create a copy of TrendingFeedItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? titleAr = null,Object? titleEn = null,Object? coverImageUrl = freezed,Object? city = freezed,Object? subtitleAr = freezed,Object? subtitleEn = freezed,Object? hotnessScore = null,Object? isVerified = null,Object? isFeatured = null,Object? eventStartDate = freezed,Object? ticketPrice = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,subtitleAr: freezed == subtitleAr ? _self.subtitleAr : subtitleAr // ignore: cast_nullable_to_non_nullable
as String?,subtitleEn: freezed == subtitleEn ? _self.subtitleEn : subtitleEn // ignore: cast_nullable_to_non_nullable
as String?,hotnessScore: null == hotnessScore ? _self.hotnessScore : hotnessScore // ignore: cast_nullable_to_non_nullable
as double,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,eventStartDate: freezed == eventStartDate ? _self.eventStartDate : eventStartDate // ignore: cast_nullable_to_non_nullable
as String?,ticketPrice: freezed == ticketPrice ? _self.ticketPrice : ticketPrice // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrendingFeedItemModel].
extension TrendingFeedItemModelPatterns on TrendingFeedItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrendingFeedItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrendingFeedItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrendingFeedItemModel value)  $default,){
final _that = this;
switch (_that) {
case _TrendingFeedItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrendingFeedItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _TrendingFeedItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String titleAr,  String titleEn,  String? coverImageUrl,  String? city,  String? subtitleAr,  String? subtitleEn,  double hotnessScore,  bool isVerified,  bool isFeatured,  String? eventStartDate,  double? ticketPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrendingFeedItemModel() when $default != null:
return $default(_that.id,_that.type,_that.titleAr,_that.titleEn,_that.coverImageUrl,_that.city,_that.subtitleAr,_that.subtitleEn,_that.hotnessScore,_that.isVerified,_that.isFeatured,_that.eventStartDate,_that.ticketPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String titleAr,  String titleEn,  String? coverImageUrl,  String? city,  String? subtitleAr,  String? subtitleEn,  double hotnessScore,  bool isVerified,  bool isFeatured,  String? eventStartDate,  double? ticketPrice)  $default,) {final _that = this;
switch (_that) {
case _TrendingFeedItemModel():
return $default(_that.id,_that.type,_that.titleAr,_that.titleEn,_that.coverImageUrl,_that.city,_that.subtitleAr,_that.subtitleEn,_that.hotnessScore,_that.isVerified,_that.isFeatured,_that.eventStartDate,_that.ticketPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String titleAr,  String titleEn,  String? coverImageUrl,  String? city,  String? subtitleAr,  String? subtitleEn,  double hotnessScore,  bool isVerified,  bool isFeatured,  String? eventStartDate,  double? ticketPrice)?  $default,) {final _that = this;
switch (_that) {
case _TrendingFeedItemModel() when $default != null:
return $default(_that.id,_that.type,_that.titleAr,_that.titleEn,_that.coverImageUrl,_that.city,_that.subtitleAr,_that.subtitleEn,_that.hotnessScore,_that.isVerified,_that.isFeatured,_that.eventStartDate,_that.ticketPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrendingFeedItemModel implements TrendingFeedItemModel {
  const _TrendingFeedItemModel({this.id = '', this.type = 'place', this.titleAr = '', this.titleEn = '', this.coverImageUrl, this.city, this.subtitleAr, this.subtitleEn, this.hotnessScore = 0.0, this.isVerified = false, this.isFeatured = false, this.eventStartDate, this.ticketPrice});
  factory _TrendingFeedItemModel.fromJson(Map<String, dynamic> json) => _$TrendingFeedItemModelFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String type;
// 'place' | 'event'
@override@JsonKey() final  String titleAr;
@override@JsonKey() final  String titleEn;
@override final  String? coverImageUrl;
@override final  String? city;
@override final  String? subtitleAr;
// منطقة للمكان / تاريخ للحدث
@override final  String? subtitleEn;
@override@JsonKey() final  double hotnessScore;
@override@JsonKey() final  bool isVerified;
@override@JsonKey() final  bool isFeatured;
@override final  String? eventStartDate;
// null إذا كان place
@override final  double? ticketPrice;

/// Create a copy of TrendingFeedItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrendingFeedItemModelCopyWith<_TrendingFeedItemModel> get copyWith => __$TrendingFeedItemModelCopyWithImpl<_TrendingFeedItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrendingFeedItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrendingFeedItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.city, city) || other.city == city)&&(identical(other.subtitleAr, subtitleAr) || other.subtitleAr == subtitleAr)&&(identical(other.subtitleEn, subtitleEn) || other.subtitleEn == subtitleEn)&&(identical(other.hotnessScore, hotnessScore) || other.hotnessScore == hotnessScore)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.eventStartDate, eventStartDate) || other.eventStartDate == eventStartDate)&&(identical(other.ticketPrice, ticketPrice) || other.ticketPrice == ticketPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,titleAr,titleEn,coverImageUrl,city,subtitleAr,subtitleEn,hotnessScore,isVerified,isFeatured,eventStartDate,ticketPrice);

@override
String toString() {
  return 'TrendingFeedItemModel(id: $id, type: $type, titleAr: $titleAr, titleEn: $titleEn, coverImageUrl: $coverImageUrl, city: $city, subtitleAr: $subtitleAr, subtitleEn: $subtitleEn, hotnessScore: $hotnessScore, isVerified: $isVerified, isFeatured: $isFeatured, eventStartDate: $eventStartDate, ticketPrice: $ticketPrice)';
}


}

/// @nodoc
abstract mixin class _$TrendingFeedItemModelCopyWith<$Res> implements $TrendingFeedItemModelCopyWith<$Res> {
  factory _$TrendingFeedItemModelCopyWith(_TrendingFeedItemModel value, $Res Function(_TrendingFeedItemModel) _then) = __$TrendingFeedItemModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String titleAr, String titleEn, String? coverImageUrl, String? city, String? subtitleAr, String? subtitleEn, double hotnessScore, bool isVerified, bool isFeatured, String? eventStartDate, double? ticketPrice
});




}
/// @nodoc
class __$TrendingFeedItemModelCopyWithImpl<$Res>
    implements _$TrendingFeedItemModelCopyWith<$Res> {
  __$TrendingFeedItemModelCopyWithImpl(this._self, this._then);

  final _TrendingFeedItemModel _self;
  final $Res Function(_TrendingFeedItemModel) _then;

/// Create a copy of TrendingFeedItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? titleAr = null,Object? titleEn = null,Object? coverImageUrl = freezed,Object? city = freezed,Object? subtitleAr = freezed,Object? subtitleEn = freezed,Object? hotnessScore = null,Object? isVerified = null,Object? isFeatured = null,Object? eventStartDate = freezed,Object? ticketPrice = freezed,}) {
  return _then(_TrendingFeedItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,subtitleAr: freezed == subtitleAr ? _self.subtitleAr : subtitleAr // ignore: cast_nullable_to_non_nullable
as String?,subtitleEn: freezed == subtitleEn ? _self.subtitleEn : subtitleEn // ignore: cast_nullable_to_non_nullable
as String?,hotnessScore: null == hotnessScore ? _self.hotnessScore : hotnessScore // ignore: cast_nullable_to_non_nullable
as double,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,eventStartDate: freezed == eventStartDate ? _self.eventStartDate : eventStartDate // ignore: cast_nullable_to_non_nullable
as String?,ticketPrice: freezed == ticketPrice ? _self.ticketPrice : ticketPrice // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on

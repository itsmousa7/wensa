// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventModel {

 String get id; String? get placeId; String get titleAr; String get titleEn; String? get descriptionAr; String? get descriptionEn; String? get coverImageUrl; String get startDate; String? get endDate; double? get ticketPrice; String? get ticketUrl; String? get city; bool get isFeatured; int get viewCount; int get savesCount; int get reviewsCount; int get sharesCount; int get checkinsCount; double get hotnessScore; String? get createdAt; String? get updatedAt;
/// Create a copy of EventModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventModelCopyWith<EventModel> get copyWith => _$EventModelCopyWithImpl<EventModel>(this as EventModel, _$identity);

  /// Serializes this EventModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventModel&&(identical(other.id, id) || other.id == id)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.descriptionEn, descriptionEn) || other.descriptionEn == descriptionEn)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.ticketPrice, ticketPrice) || other.ticketPrice == ticketPrice)&&(identical(other.ticketUrl, ticketUrl) || other.ticketUrl == ticketUrl)&&(identical(other.city, city) || other.city == city)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.savesCount, savesCount) || other.savesCount == savesCount)&&(identical(other.reviewsCount, reviewsCount) || other.reviewsCount == reviewsCount)&&(identical(other.sharesCount, sharesCount) || other.sharesCount == sharesCount)&&(identical(other.checkinsCount, checkinsCount) || other.checkinsCount == checkinsCount)&&(identical(other.hotnessScore, hotnessScore) || other.hotnessScore == hotnessScore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,placeId,titleAr,titleEn,descriptionAr,descriptionEn,coverImageUrl,startDate,endDate,ticketPrice,ticketUrl,city,isFeatured,viewCount,savesCount,reviewsCount,sharesCount,checkinsCount,hotnessScore,createdAt,updatedAt]);

@override
String toString() {
  return 'EventModel(id: $id, placeId: $placeId, titleAr: $titleAr, titleEn: $titleEn, descriptionAr: $descriptionAr, descriptionEn: $descriptionEn, coverImageUrl: $coverImageUrl, startDate: $startDate, endDate: $endDate, ticketPrice: $ticketPrice, ticketUrl: $ticketUrl, city: $city, isFeatured: $isFeatured, viewCount: $viewCount, savesCount: $savesCount, reviewsCount: $reviewsCount, sharesCount: $sharesCount, checkinsCount: $checkinsCount, hotnessScore: $hotnessScore, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $EventModelCopyWith<$Res>  {
  factory $EventModelCopyWith(EventModel value, $Res Function(EventModel) _then) = _$EventModelCopyWithImpl;
@useResult
$Res call({
 String id, String? placeId, String titleAr, String titleEn, String? descriptionAr, String? descriptionEn, String? coverImageUrl, String startDate, String? endDate, double? ticketPrice, String? ticketUrl, String? city, bool isFeatured, int viewCount, int savesCount, int reviewsCount, int sharesCount, int checkinsCount, double hotnessScore, String? createdAt, String? updatedAt
});




}
/// @nodoc
class _$EventModelCopyWithImpl<$Res>
    implements $EventModelCopyWith<$Res> {
  _$EventModelCopyWithImpl(this._self, this._then);

  final EventModel _self;
  final $Res Function(EventModel) _then;

/// Create a copy of EventModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? placeId = freezed,Object? titleAr = null,Object? titleEn = null,Object? descriptionAr = freezed,Object? descriptionEn = freezed,Object? coverImageUrl = freezed,Object? startDate = null,Object? endDate = freezed,Object? ticketPrice = freezed,Object? ticketUrl = freezed,Object? city = freezed,Object? isFeatured = null,Object? viewCount = null,Object? savesCount = null,Object? reviewsCount = null,Object? sharesCount = null,Object? checkinsCount = null,Object? hotnessScore = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,descriptionEn: freezed == descriptionEn ? _self.descriptionEn : descriptionEn // ignore: cast_nullable_to_non_nullable
as String?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,ticketPrice: freezed == ticketPrice ? _self.ticketPrice : ticketPrice // ignore: cast_nullable_to_non_nullable
as double?,ticketUrl: freezed == ticketUrl ? _self.ticketUrl : ticketUrl // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,savesCount: null == savesCount ? _self.savesCount : savesCount // ignore: cast_nullable_to_non_nullable
as int,reviewsCount: null == reviewsCount ? _self.reviewsCount : reviewsCount // ignore: cast_nullable_to_non_nullable
as int,sharesCount: null == sharesCount ? _self.sharesCount : sharesCount // ignore: cast_nullable_to_non_nullable
as int,checkinsCount: null == checkinsCount ? _self.checkinsCount : checkinsCount // ignore: cast_nullable_to_non_nullable
as int,hotnessScore: null == hotnessScore ? _self.hotnessScore : hotnessScore // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventModel].
extension EventModelPatterns on EventModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventModel value)  $default,){
final _that = this;
switch (_that) {
case _EventModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventModel value)?  $default,){
final _that = this;
switch (_that) {
case _EventModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? placeId,  String titleAr,  String titleEn,  String? descriptionAr,  String? descriptionEn,  String? coverImageUrl,  String startDate,  String? endDate,  double? ticketPrice,  String? ticketUrl,  String? city,  bool isFeatured,  int viewCount,  int savesCount,  int reviewsCount,  int sharesCount,  int checkinsCount,  double hotnessScore,  String? createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventModel() when $default != null:
return $default(_that.id,_that.placeId,_that.titleAr,_that.titleEn,_that.descriptionAr,_that.descriptionEn,_that.coverImageUrl,_that.startDate,_that.endDate,_that.ticketPrice,_that.ticketUrl,_that.city,_that.isFeatured,_that.viewCount,_that.savesCount,_that.reviewsCount,_that.sharesCount,_that.checkinsCount,_that.hotnessScore,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? placeId,  String titleAr,  String titleEn,  String? descriptionAr,  String? descriptionEn,  String? coverImageUrl,  String startDate,  String? endDate,  double? ticketPrice,  String? ticketUrl,  String? city,  bool isFeatured,  int viewCount,  int savesCount,  int reviewsCount,  int sharesCount,  int checkinsCount,  double hotnessScore,  String? createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _EventModel():
return $default(_that.id,_that.placeId,_that.titleAr,_that.titleEn,_that.descriptionAr,_that.descriptionEn,_that.coverImageUrl,_that.startDate,_that.endDate,_that.ticketPrice,_that.ticketUrl,_that.city,_that.isFeatured,_that.viewCount,_that.savesCount,_that.reviewsCount,_that.sharesCount,_that.checkinsCount,_that.hotnessScore,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? placeId,  String titleAr,  String titleEn,  String? descriptionAr,  String? descriptionEn,  String? coverImageUrl,  String startDate,  String? endDate,  double? ticketPrice,  String? ticketUrl,  String? city,  bool isFeatured,  int viewCount,  int savesCount,  int reviewsCount,  int sharesCount,  int checkinsCount,  double hotnessScore,  String? createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _EventModel() when $default != null:
return $default(_that.id,_that.placeId,_that.titleAr,_that.titleEn,_that.descriptionAr,_that.descriptionEn,_that.coverImageUrl,_that.startDate,_that.endDate,_that.ticketPrice,_that.ticketUrl,_that.city,_that.isFeatured,_that.viewCount,_that.savesCount,_that.reviewsCount,_that.sharesCount,_that.checkinsCount,_that.hotnessScore,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventModel implements EventModel {
  const _EventModel({this.id = '', this.placeId, this.titleAr = '', this.titleEn = '', this.descriptionAr, this.descriptionEn, this.coverImageUrl, this.startDate = '', this.endDate, this.ticketPrice, this.ticketUrl, this.city, this.isFeatured = false, this.viewCount = 0, this.savesCount = 0, this.reviewsCount = 0, this.sharesCount = 0, this.checkinsCount = 0, this.hotnessScore = 0.0, this.createdAt, this.updatedAt});
  factory _EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);

@override@JsonKey() final  String id;
@override final  String? placeId;
@override@JsonKey() final  String titleAr;
@override@JsonKey() final  String titleEn;
@override final  String? descriptionAr;
@override final  String? descriptionEn;
@override final  String? coverImageUrl;
@override@JsonKey() final  String startDate;
@override final  String? endDate;
@override final  double? ticketPrice;
@override final  String? ticketUrl;
@override final  String? city;
@override@JsonKey() final  bool isFeatured;
@override@JsonKey() final  int viewCount;
@override@JsonKey() final  int savesCount;
@override@JsonKey() final  int reviewsCount;
@override@JsonKey() final  int sharesCount;
@override@JsonKey() final  int checkinsCount;
@override@JsonKey() final  double hotnessScore;
@override final  String? createdAt;
@override final  String? updatedAt;

/// Create a copy of EventModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventModelCopyWith<_EventModel> get copyWith => __$EventModelCopyWithImpl<_EventModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventModel&&(identical(other.id, id) || other.id == id)&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.titleAr, titleAr) || other.titleAr == titleAr)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.descriptionEn, descriptionEn) || other.descriptionEn == descriptionEn)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.ticketPrice, ticketPrice) || other.ticketPrice == ticketPrice)&&(identical(other.ticketUrl, ticketUrl) || other.ticketUrl == ticketUrl)&&(identical(other.city, city) || other.city == city)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.savesCount, savesCount) || other.savesCount == savesCount)&&(identical(other.reviewsCount, reviewsCount) || other.reviewsCount == reviewsCount)&&(identical(other.sharesCount, sharesCount) || other.sharesCount == sharesCount)&&(identical(other.checkinsCount, checkinsCount) || other.checkinsCount == checkinsCount)&&(identical(other.hotnessScore, hotnessScore) || other.hotnessScore == hotnessScore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,placeId,titleAr,titleEn,descriptionAr,descriptionEn,coverImageUrl,startDate,endDate,ticketPrice,ticketUrl,city,isFeatured,viewCount,savesCount,reviewsCount,sharesCount,checkinsCount,hotnessScore,createdAt,updatedAt]);

@override
String toString() {
  return 'EventModel(id: $id, placeId: $placeId, titleAr: $titleAr, titleEn: $titleEn, descriptionAr: $descriptionAr, descriptionEn: $descriptionEn, coverImageUrl: $coverImageUrl, startDate: $startDate, endDate: $endDate, ticketPrice: $ticketPrice, ticketUrl: $ticketUrl, city: $city, isFeatured: $isFeatured, viewCount: $viewCount, savesCount: $savesCount, reviewsCount: $reviewsCount, sharesCount: $sharesCount, checkinsCount: $checkinsCount, hotnessScore: $hotnessScore, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$EventModelCopyWith<$Res> implements $EventModelCopyWith<$Res> {
  factory _$EventModelCopyWith(_EventModel value, $Res Function(_EventModel) _then) = __$EventModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String? placeId, String titleAr, String titleEn, String? descriptionAr, String? descriptionEn, String? coverImageUrl, String startDate, String? endDate, double? ticketPrice, String? ticketUrl, String? city, bool isFeatured, int viewCount, int savesCount, int reviewsCount, int sharesCount, int checkinsCount, double hotnessScore, String? createdAt, String? updatedAt
});




}
/// @nodoc
class __$EventModelCopyWithImpl<$Res>
    implements _$EventModelCopyWith<$Res> {
  __$EventModelCopyWithImpl(this._self, this._then);

  final _EventModel _self;
  final $Res Function(_EventModel) _then;

/// Create a copy of EventModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? placeId = freezed,Object? titleAr = null,Object? titleEn = null,Object? descriptionAr = freezed,Object? descriptionEn = freezed,Object? coverImageUrl = freezed,Object? startDate = null,Object? endDate = freezed,Object? ticketPrice = freezed,Object? ticketUrl = freezed,Object? city = freezed,Object? isFeatured = null,Object? viewCount = null,Object? savesCount = null,Object? reviewsCount = null,Object? sharesCount = null,Object? checkinsCount = null,Object? hotnessScore = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_EventModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,placeId: freezed == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String?,titleAr: null == titleAr ? _self.titleAr : titleAr // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,descriptionEn: freezed == descriptionEn ? _self.descriptionEn : descriptionEn // ignore: cast_nullable_to_non_nullable
as String?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,ticketPrice: freezed == ticketPrice ? _self.ticketPrice : ticketPrice // ignore: cast_nullable_to_non_nullable
as double?,ticketUrl: freezed == ticketUrl ? _self.ticketUrl : ticketUrl // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,savesCount: null == savesCount ? _self.savesCount : savesCount // ignore: cast_nullable_to_non_nullable
as int,reviewsCount: null == reviewsCount ? _self.reviewsCount : reviewsCount // ignore: cast_nullable_to_non_nullable
as int,sharesCount: null == sharesCount ? _self.sharesCount : sharesCount // ignore: cast_nullable_to_non_nullable
as int,checkinsCount: null == checkinsCount ? _self.checkinsCount : checkinsCount // ignore: cast_nullable_to_non_nullable
as int,hotnessScore: null == hotnessScore ? _self.hotnessScore : hotnessScore // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

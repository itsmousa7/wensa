// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaceModel {

 String get id; String get nameAr; String get nameEn; String? get descriptionAr; String? get descriptionEn; String? get categoryId; String get city; String? get area; String? get addressText; double? get latitude; double? get longitude; String? get coverImageUrl; bool get isNew; bool get isTrending; bool get isVerified; bool get isFeatured; int? get priceRange;// opening_hours stored as raw Map since it's a flexible jsonb
 Map<String, dynamic>? get openingHours; String? get phone; String? get instagramUrl; String? get websiteUrl; int get viewCount; int get savesCount; int get reviewsCount; int get sharesCount; int get checkinsCount; double get hotnessScore; String? get createdAt; String? get updatedAt;
/// Create a copy of PlaceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceModelCopyWith<PlaceModel> get copyWith => _$PlaceModelCopyWithImpl<PlaceModel>(this as PlaceModel, _$identity);

  /// Serializes this PlaceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.descriptionEn, descriptionEn) || other.descriptionEn == descriptionEn)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.city, city) || other.city == city)&&(identical(other.area, area) || other.area == area)&&(identical(other.addressText, addressText) || other.addressText == addressText)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.isNew, isNew) || other.isNew == isNew)&&(identical(other.isTrending, isTrending) || other.isTrending == isTrending)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.priceRange, priceRange) || other.priceRange == priceRange)&&const DeepCollectionEquality().equals(other.openingHours, openingHours)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.instagramUrl, instagramUrl) || other.instagramUrl == instagramUrl)&&(identical(other.websiteUrl, websiteUrl) || other.websiteUrl == websiteUrl)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.savesCount, savesCount) || other.savesCount == savesCount)&&(identical(other.reviewsCount, reviewsCount) || other.reviewsCount == reviewsCount)&&(identical(other.sharesCount, sharesCount) || other.sharesCount == sharesCount)&&(identical(other.checkinsCount, checkinsCount) || other.checkinsCount == checkinsCount)&&(identical(other.hotnessScore, hotnessScore) || other.hotnessScore == hotnessScore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,nameAr,nameEn,descriptionAr,descriptionEn,categoryId,city,area,addressText,latitude,longitude,coverImageUrl,isNew,isTrending,isVerified,isFeatured,priceRange,const DeepCollectionEquality().hash(openingHours),phone,instagramUrl,websiteUrl,viewCount,savesCount,reviewsCount,sharesCount,checkinsCount,hotnessScore,createdAt,updatedAt]);

@override
String toString() {
  return 'PlaceModel(id: $id, nameAr: $nameAr, nameEn: $nameEn, descriptionAr: $descriptionAr, descriptionEn: $descriptionEn, categoryId: $categoryId, city: $city, area: $area, addressText: $addressText, latitude: $latitude, longitude: $longitude, coverImageUrl: $coverImageUrl, isNew: $isNew, isTrending: $isTrending, isVerified: $isVerified, isFeatured: $isFeatured, priceRange: $priceRange, openingHours: $openingHours, phone: $phone, instagramUrl: $instagramUrl, websiteUrl: $websiteUrl, viewCount: $viewCount, savesCount: $savesCount, reviewsCount: $reviewsCount, sharesCount: $sharesCount, checkinsCount: $checkinsCount, hotnessScore: $hotnessScore, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PlaceModelCopyWith<$Res>  {
  factory $PlaceModelCopyWith(PlaceModel value, $Res Function(PlaceModel) _then) = _$PlaceModelCopyWithImpl;
@useResult
$Res call({
 String id, String nameAr, String nameEn, String? descriptionAr, String? descriptionEn, String? categoryId, String city, String? area, String? addressText, double? latitude, double? longitude, String? coverImageUrl, bool isNew, bool isTrending, bool isVerified, bool isFeatured, int? priceRange, Map<String, dynamic>? openingHours, String? phone, String? instagramUrl, String? websiteUrl, int viewCount, int savesCount, int reviewsCount, int sharesCount, int checkinsCount, double hotnessScore, String? createdAt, String? updatedAt
});




}
/// @nodoc
class _$PlaceModelCopyWithImpl<$Res>
    implements $PlaceModelCopyWith<$Res> {
  _$PlaceModelCopyWithImpl(this._self, this._then);

  final PlaceModel _self;
  final $Res Function(PlaceModel) _then;

/// Create a copy of PlaceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameAr = null,Object? nameEn = null,Object? descriptionAr = freezed,Object? descriptionEn = freezed,Object? categoryId = freezed,Object? city = null,Object? area = freezed,Object? addressText = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? coverImageUrl = freezed,Object? isNew = null,Object? isTrending = null,Object? isVerified = null,Object? isFeatured = null,Object? priceRange = freezed,Object? openingHours = freezed,Object? phone = freezed,Object? instagramUrl = freezed,Object? websiteUrl = freezed,Object? viewCount = null,Object? savesCount = null,Object? reviewsCount = null,Object? sharesCount = null,Object? checkinsCount = null,Object? hotnessScore = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,descriptionEn: freezed == descriptionEn ? _self.descriptionEn : descriptionEn // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,addressText: freezed == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,isTrending: null == isTrending ? _self.isTrending : isTrending // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,priceRange: freezed == priceRange ? _self.priceRange : priceRange // ignore: cast_nullable_to_non_nullable
as int?,openingHours: freezed == openingHours ? _self.openingHours : openingHours // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,instagramUrl: freezed == instagramUrl ? _self.instagramUrl : instagramUrl // ignore: cast_nullable_to_non_nullable
as String?,websiteUrl: freezed == websiteUrl ? _self.websiteUrl : websiteUrl // ignore: cast_nullable_to_non_nullable
as String?,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
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


/// Adds pattern-matching-related methods to [PlaceModel].
extension PlaceModelPatterns on PlaceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceModel value)  $default,){
final _that = this;
switch (_that) {
case _PlaceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceModel value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nameAr,  String nameEn,  String? descriptionAr,  String? descriptionEn,  String? categoryId,  String city,  String? area,  String? addressText,  double? latitude,  double? longitude,  String? coverImageUrl,  bool isNew,  bool isTrending,  bool isVerified,  bool isFeatured,  int? priceRange,  Map<String, dynamic>? openingHours,  String? phone,  String? instagramUrl,  String? websiteUrl,  int viewCount,  int savesCount,  int reviewsCount,  int sharesCount,  int checkinsCount,  double hotnessScore,  String? createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceModel() when $default != null:
return $default(_that.id,_that.nameAr,_that.nameEn,_that.descriptionAr,_that.descriptionEn,_that.categoryId,_that.city,_that.area,_that.addressText,_that.latitude,_that.longitude,_that.coverImageUrl,_that.isNew,_that.isTrending,_that.isVerified,_that.isFeatured,_that.priceRange,_that.openingHours,_that.phone,_that.instagramUrl,_that.websiteUrl,_that.viewCount,_that.savesCount,_that.reviewsCount,_that.sharesCount,_that.checkinsCount,_that.hotnessScore,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nameAr,  String nameEn,  String? descriptionAr,  String? descriptionEn,  String? categoryId,  String city,  String? area,  String? addressText,  double? latitude,  double? longitude,  String? coverImageUrl,  bool isNew,  bool isTrending,  bool isVerified,  bool isFeatured,  int? priceRange,  Map<String, dynamic>? openingHours,  String? phone,  String? instagramUrl,  String? websiteUrl,  int viewCount,  int savesCount,  int reviewsCount,  int sharesCount,  int checkinsCount,  double hotnessScore,  String? createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PlaceModel():
return $default(_that.id,_that.nameAr,_that.nameEn,_that.descriptionAr,_that.descriptionEn,_that.categoryId,_that.city,_that.area,_that.addressText,_that.latitude,_that.longitude,_that.coverImageUrl,_that.isNew,_that.isTrending,_that.isVerified,_that.isFeatured,_that.priceRange,_that.openingHours,_that.phone,_that.instagramUrl,_that.websiteUrl,_that.viewCount,_that.savesCount,_that.reviewsCount,_that.sharesCount,_that.checkinsCount,_that.hotnessScore,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nameAr,  String nameEn,  String? descriptionAr,  String? descriptionEn,  String? categoryId,  String city,  String? area,  String? addressText,  double? latitude,  double? longitude,  String? coverImageUrl,  bool isNew,  bool isTrending,  bool isVerified,  bool isFeatured,  int? priceRange,  Map<String, dynamic>? openingHours,  String? phone,  String? instagramUrl,  String? websiteUrl,  int viewCount,  int savesCount,  int reviewsCount,  int sharesCount,  int checkinsCount,  double hotnessScore,  String? createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlaceModel() when $default != null:
return $default(_that.id,_that.nameAr,_that.nameEn,_that.descriptionAr,_that.descriptionEn,_that.categoryId,_that.city,_that.area,_that.addressText,_that.latitude,_that.longitude,_that.coverImageUrl,_that.isNew,_that.isTrending,_that.isVerified,_that.isFeatured,_that.priceRange,_that.openingHours,_that.phone,_that.instagramUrl,_that.websiteUrl,_that.viewCount,_that.savesCount,_that.reviewsCount,_that.sharesCount,_that.checkinsCount,_that.hotnessScore,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaceModel implements PlaceModel {
  const _PlaceModel({this.id = '', this.nameAr = '', this.nameEn = '', this.descriptionAr, this.descriptionEn, this.categoryId, this.city = '', this.area, this.addressText, this.latitude, this.longitude, this.coverImageUrl, this.isNew = false, this.isTrending = false, this.isVerified = false, this.isFeatured = false, this.priceRange, final  Map<String, dynamic>? openingHours, this.phone, this.instagramUrl, this.websiteUrl, this.viewCount = 0, this.savesCount = 0, this.reviewsCount = 0, this.sharesCount = 0, this.checkinsCount = 0, this.hotnessScore = 0.0, this.createdAt, this.updatedAt}): _openingHours = openingHours;
  factory _PlaceModel.fromJson(Map<String, dynamic> json) => _$PlaceModelFromJson(json);

@override@JsonKey() final  String id;
@override@JsonKey() final  String nameAr;
@override@JsonKey() final  String nameEn;
@override final  String? descriptionAr;
@override final  String? descriptionEn;
@override final  String? categoryId;
@override@JsonKey() final  String city;
@override final  String? area;
@override final  String? addressText;
@override final  double? latitude;
@override final  double? longitude;
@override final  String? coverImageUrl;
@override@JsonKey() final  bool isNew;
@override@JsonKey() final  bool isTrending;
@override@JsonKey() final  bool isVerified;
@override@JsonKey() final  bool isFeatured;
@override final  int? priceRange;
// opening_hours stored as raw Map since it's a flexible jsonb
 final  Map<String, dynamic>? _openingHours;
// opening_hours stored as raw Map since it's a flexible jsonb
@override Map<String, dynamic>? get openingHours {
  final value = _openingHours;
  if (value == null) return null;
  if (_openingHours is EqualUnmodifiableMapView) return _openingHours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? phone;
@override final  String? instagramUrl;
@override final  String? websiteUrl;
@override@JsonKey() final  int viewCount;
@override@JsonKey() final  int savesCount;
@override@JsonKey() final  int reviewsCount;
@override@JsonKey() final  int sharesCount;
@override@JsonKey() final  int checkinsCount;
@override@JsonKey() final  double hotnessScore;
@override final  String? createdAt;
@override final  String? updatedAt;

/// Create a copy of PlaceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceModelCopyWith<_PlaceModel> get copyWith => __$PlaceModelCopyWithImpl<_PlaceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.descriptionAr, descriptionAr) || other.descriptionAr == descriptionAr)&&(identical(other.descriptionEn, descriptionEn) || other.descriptionEn == descriptionEn)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.city, city) || other.city == city)&&(identical(other.area, area) || other.area == area)&&(identical(other.addressText, addressText) || other.addressText == addressText)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.isNew, isNew) || other.isNew == isNew)&&(identical(other.isTrending, isTrending) || other.isTrending == isTrending)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.priceRange, priceRange) || other.priceRange == priceRange)&&const DeepCollectionEquality().equals(other._openingHours, _openingHours)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.instagramUrl, instagramUrl) || other.instagramUrl == instagramUrl)&&(identical(other.websiteUrl, websiteUrl) || other.websiteUrl == websiteUrl)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.savesCount, savesCount) || other.savesCount == savesCount)&&(identical(other.reviewsCount, reviewsCount) || other.reviewsCount == reviewsCount)&&(identical(other.sharesCount, sharesCount) || other.sharesCount == sharesCount)&&(identical(other.checkinsCount, checkinsCount) || other.checkinsCount == checkinsCount)&&(identical(other.hotnessScore, hotnessScore) || other.hotnessScore == hotnessScore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,nameAr,nameEn,descriptionAr,descriptionEn,categoryId,city,area,addressText,latitude,longitude,coverImageUrl,isNew,isTrending,isVerified,isFeatured,priceRange,const DeepCollectionEquality().hash(_openingHours),phone,instagramUrl,websiteUrl,viewCount,savesCount,reviewsCount,sharesCount,checkinsCount,hotnessScore,createdAt,updatedAt]);

@override
String toString() {
  return 'PlaceModel(id: $id, nameAr: $nameAr, nameEn: $nameEn, descriptionAr: $descriptionAr, descriptionEn: $descriptionEn, categoryId: $categoryId, city: $city, area: $area, addressText: $addressText, latitude: $latitude, longitude: $longitude, coverImageUrl: $coverImageUrl, isNew: $isNew, isTrending: $isTrending, isVerified: $isVerified, isFeatured: $isFeatured, priceRange: $priceRange, openingHours: $openingHours, phone: $phone, instagramUrl: $instagramUrl, websiteUrl: $websiteUrl, viewCount: $viewCount, savesCount: $savesCount, reviewsCount: $reviewsCount, sharesCount: $sharesCount, checkinsCount: $checkinsCount, hotnessScore: $hotnessScore, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PlaceModelCopyWith<$Res> implements $PlaceModelCopyWith<$Res> {
  factory _$PlaceModelCopyWith(_PlaceModel value, $Res Function(_PlaceModel) _then) = __$PlaceModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String nameAr, String nameEn, String? descriptionAr, String? descriptionEn, String? categoryId, String city, String? area, String? addressText, double? latitude, double? longitude, String? coverImageUrl, bool isNew, bool isTrending, bool isVerified, bool isFeatured, int? priceRange, Map<String, dynamic>? openingHours, String? phone, String? instagramUrl, String? websiteUrl, int viewCount, int savesCount, int reviewsCount, int sharesCount, int checkinsCount, double hotnessScore, String? createdAt, String? updatedAt
});




}
/// @nodoc
class __$PlaceModelCopyWithImpl<$Res>
    implements _$PlaceModelCopyWith<$Res> {
  __$PlaceModelCopyWithImpl(this._self, this._then);

  final _PlaceModel _self;
  final $Res Function(_PlaceModel) _then;

/// Create a copy of PlaceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameAr = null,Object? nameEn = null,Object? descriptionAr = freezed,Object? descriptionEn = freezed,Object? categoryId = freezed,Object? city = null,Object? area = freezed,Object? addressText = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? coverImageUrl = freezed,Object? isNew = null,Object? isTrending = null,Object? isVerified = null,Object? isFeatured = null,Object? priceRange = freezed,Object? openingHours = freezed,Object? phone = freezed,Object? instagramUrl = freezed,Object? websiteUrl = freezed,Object? viewCount = null,Object? savesCount = null,Object? reviewsCount = null,Object? sharesCount = null,Object? checkinsCount = null,Object? hotnessScore = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PlaceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,descriptionAr: freezed == descriptionAr ? _self.descriptionAr : descriptionAr // ignore: cast_nullable_to_non_nullable
as String?,descriptionEn: freezed == descriptionEn ? _self.descriptionEn : descriptionEn // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,addressText: freezed == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,isNew: null == isNew ? _self.isNew : isNew // ignore: cast_nullable_to_non_nullable
as bool,isTrending: null == isTrending ? _self.isTrending : isTrending // ignore: cast_nullable_to_non_nullable
as bool,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,priceRange: freezed == priceRange ? _self.priceRange : priceRange // ignore: cast_nullable_to_non_nullable
as int?,openingHours: freezed == openingHours ? _self._openingHours : openingHours // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,instagramUrl: freezed == instagramUrl ? _self.instagramUrl : instagramUrl // ignore: cast_nullable_to_non_nullable
as String?,websiteUrl: freezed == websiteUrl ? _self.websiteUrl : websiteUrl // ignore: cast_nullable_to_non_nullable
as String?,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
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

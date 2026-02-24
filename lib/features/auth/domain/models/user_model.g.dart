// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: json['id'] as String? ?? '',
  firstName: json['firstName'] as String? ?? '',
  secondName: json['secondName'] as String? ?? '',
  email: json['email'] as String? ?? '',
  phone: json['phone'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  city: json['city'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'secondName': instance.secondName,
      'email': instance.email,
      'phone': instance.phone,
      'avatarUrl': instance.avatarUrl,
      'city': instance.city,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

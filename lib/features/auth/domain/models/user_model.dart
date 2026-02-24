import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    @Default('') String id,
    @Default('') String firstName,
    @Default('') String secondName,
    @Default('') String email,
    String? phone,
    String? avatarUrl,
    String? city,
    String? createdAt,
    String? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    firstName: json['first_name'] ?? '',
    secondName: json['second_name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'],
    avatarUrl: json['avatar_url'],
    city: json['city'],
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );
}

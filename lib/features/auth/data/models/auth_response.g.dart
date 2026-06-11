// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  role: json['role'] as String?,
  username: json['username'] as String,
  email: json['email'] as String?,
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
  userId: (json['userId'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'role': instance.role,
      'username': instance.username,
      'email': instance.email,
      'roles': instance.roles,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
    };

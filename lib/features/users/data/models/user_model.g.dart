// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  roles: (json['roles'] as List<dynamic>)
      .map((e) => $enumDecode(_$UserRoleEnumMap, e))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'roles': instance.roles.map((e) => _$UserRoleEnumMap[e]!).toList(),
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$UserRoleEnumMap = {
  UserRole.admin: 'ADMIN',
  UserRole.stockManager: 'STOCK_MANAGER',
  UserRole.stockOperator: 'STOCK_OPERATOR',
  UserRole.salesClerk: 'SALES_CLERK',
  UserRole.productionOp: 'PRODUCTION_OP',
  UserRole.accountant: 'ACCOUNTANT',
  UserRole.customer: 'CUSTOMER',
};

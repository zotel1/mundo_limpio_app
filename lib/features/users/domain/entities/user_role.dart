import 'package:json_annotation/json_annotation.dart';

/// Roles de usuario en el sistema MundoLimpio.
///
/// Cada valor tiene su correspondiente representación en UPPER_SNAKE_CASE
/// para la comunicación con el backend.
///
/// Usar [jsonValue] para obtener la representación JSON manualmente
/// en las llamadas a la API que construyen el body sin json_serializable.
@JsonEnum()
enum UserRole {
  @JsonValue('ADMIN')
  admin,
  @JsonValue('STOCK_MANAGER')
  stockManager,
  @JsonValue('STOCK_OPERATOR')
  stockOperator,
  @JsonValue('SALES_CLERK')
  salesClerk,
  @JsonValue('PRODUCTION_OP')
  productionOp,
  @JsonValue('ACCOUNTANT')
  accountant,
  @JsonValue('CUSTOMER')
  customer;

  /// Representación UPPER_SNAKE_CASE para enviar al backend.
  String get jsonValue {
    return switch (this) {
      UserRole.admin => 'ADMIN',
      UserRole.stockManager => 'STOCK_MANAGER',
      UserRole.stockOperator => 'STOCK_OPERATOR',
      UserRole.salesClerk => 'SALES_CLERK',
      UserRole.productionOp => 'PRODUCTION_OP',
      UserRole.accountant => 'ACCOUNTANT',
      UserRole.customer => 'CUSTOMER',
    };
  }
}

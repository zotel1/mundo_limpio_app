// Modelo de request para login.
//
// Se envía como body JSON en POST /api/v1/auth/login.
// Contiene email y password del usuario.
//
// La validación de formato se hace en la capa de UI (LoginScreen),
// no en el modelo — el modelo solo transporta datos.

import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

/// Cuerpo del request para el endpoint de login.
///
/// Campos:
/// - [email]: dirección de email del usuario
/// - [password]: contraseña en texto plano (se envía por HTTPS)
@JsonSerializable()
class LoginRequest {
  /// Email del usuario.
  final String email;

  /// Contraseña del usuario (texto plano, sobre HTTPS).
  final String password;

  /// Crea un [LoginRequest] con email y password.
  const LoginRequest({
    required this.email,
    required this.password,
  });

  /// Construye desde un mapa JSON.
  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  /// Serializa a mapa JSON para el body del request HTTP.
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

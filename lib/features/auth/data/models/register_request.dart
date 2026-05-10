// Modelo de request para registro.
//
// Se envía como body JSON en POST /api/v1/auth/register.
// Contiene email y password del nuevo usuario.
//
// Actualmente es idéntico a LoginRequest, pero existe como clase
// separada porque el registro podría agregar campos adicionales
// (nombre, teléfono, etc.) en el futuro sin afectar login.

import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

/// Cuerpo del request para el endpoint de registro.
///
/// Campos:
/// - [email]: dirección de email del nuevo usuario
/// - [password]: contraseña elegida por el usuario
@JsonSerializable()
class RegisterRequest {
  /// Email del nuevo usuario.
  final String email;

  /// Contraseña del nuevo usuario (texto plano, sobre HTTPS).
  final String password;

  /// Crea un [RegisterRequest] con email y password.
  const RegisterRequest({
    required this.email,
    required this.password,
  });

  /// Construye desde un mapa JSON.
  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  /// Serializa a mapa JSON para el body del request HTTP.
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

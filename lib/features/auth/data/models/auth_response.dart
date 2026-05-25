// Modelo de respuesta de autenticación del backend.
//
// Contiene los tokens JWT (access + refresh) y metadatos
// del usuario (rol, username, fecha de creación).
// Se serializa/deserializa con json_serializable.
//
// El access token se usa para autenticar requests API.
// El refresh token se usa para obtener un nuevo access token
// cuando el actual expira (ver AuthInterceptor).

import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

/// Respuesta del backend después de login o refresh exitoso.
///
/// Mapea directamente el JSON de los endpoints:
/// - `POST /api/v1/auth/login`
/// - `POST /api/v1/auth/refresh`
@JsonSerializable()
class AuthResponse {
  /// Token JWT de corta duración para autenticar requests.
  final String accessToken;

  /// Token JWT de larga duración para renovar el access token.
  final String refreshToken;

  /// Rol del usuario (ej: 'user', 'admin', 'moderator').
  final String role;

  /// Nombre de usuario visible en la UI.
  final String username;

  /// Email del usuario (opcional, solo en login/register response).
  final String? email;

  /// Roles del usuario (opcional, solo en login/register response).
  final List<String>? roles;

  /// Fecha y hora ISO 8601 de creación de la sesión/cuenta.
  ///
  /// json_serializable parsea DateTime nativamente con DateTime.parse()
  /// y lo serializa con toIso8601String().
  final DateTime createdAt;

  /// Crea un [AuthResponse] con todos los campos requeridos.
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.username,
    this.email,
    this.roles,
    required this.createdAt,
  });

  /// Construye un [AuthResponse] desde un mapa JSON (del backend).
  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  /// Serializa a mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

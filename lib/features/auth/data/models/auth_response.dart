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

  /// Rol del usuario (deprecated, usar [roles]).
  ///
  /// El backend aún envía este campo para compatibilidad, pero
  /// la fuente de verdad es [roles].
  final String? role;

  /// Nombre de usuario visible en la UI.
  final String username;

  /// Email del usuario (opcional, solo en login/register response).
  final String? email;

  /// Roles del usuario (requerido, fuente de verdad).
  final List<String> roles;

  /// Fecha y hora ISO 8601 de creación de la sesión/cuenta.
  ///
  /// json_serializable parsea DateTime nativamente con DateTime.parse()
  /// y lo serializa con toIso8601String().
  final DateTime createdAt;

  /// Crea un [AuthResponse] con todos los campos requeridos.
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    this.role,
    required this.username,
    this.email,
    required this.roles,
    required this.createdAt,
  });

  /// Construye un [AuthResponse] desde un mapa JSON (del backend).
  ///
  /// Si `roles` no está presente en el JSON, se usa `[role]` como fallback
  /// para mantener compatibilidad con backends que aún envían `role`.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Fallback: si roles es null, usar [role] o lista vacía.
    // Crea un nuevo map para no mutar el original (que podría ser
    // Map<String, String> desde Dio y no aceptaría List como valor).
    final role = json['role'] as String?;
    if (json['roles'] == null) {
      return _$AuthResponseFromJson(<String, dynamic>{
        ...json,
        'roles': role != null ? [role] : <String>[],
      });
    }
    return _$AuthResponseFromJson(json);
  }

  /// Serializa a mapa JSON para enviar al backend.
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

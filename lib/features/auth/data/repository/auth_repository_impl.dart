// Implementación concreta de AuthRepository.
//
// Coordina AuthApi (HTTP) y TokenStorage (persistencia segura)
// para implementar el ciclo completo de autenticación:
// - login: llama API → guarda tokens localmente → retorna respuesta
// - register: llama API → retorna respuesta (sin guardar tokens)
// - logout: elimina tokens locales
// - refreshToken: renueva tokens vía API → guarda nuevos
// - isLoggedIn: verifica existencia de tokens locales

import 'package:mundo_limpio_app/core/storage/token_storage.dart';
import 'package:mundo_limpio_app/features/auth/data/api/auth_api.dart';
import 'package:mundo_limpio_app/features/auth/data/models/auth_response.dart';
import 'package:mundo_limpio_app/features/auth/domain/repository/auth_repository.dart';

/// Implementación de [AuthRepository] que usa [AuthApi] para
/// comunicación HTTP y [TokenStorage] para persistencia local.
class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  /// Crea el repositorio con las dependencias inyectadas.
  ///
  /// [authApi]: cliente HTTP para endpoints de auth.
  /// [tokenStorage]: almacenamiento seguro de tokens JWT.
  const AuthRepositoryImpl({
    required AuthApi authApi,
    required TokenStorage tokenStorage,
  })  : _authApi = authApi,
        _tokenStorage = tokenStorage;

  @override
  Future<AuthResponse> login(String email, String password) async {
    final response = await _authApi.login(email, password);

    // Persistir tokens localmente para requests futuros (R3.1)
    await _tokenStorage.saveTokens(
      response.accessToken,
      response.refreshToken,
    );

    return response;
  }

  @override
  Future<AuthResponse> register(String email, String password) async {
    final response = await _authApi.register(email, password);

    // No guardar tokens en registro — el usuario debe
    // iniciar sesión después del registro exitoso (R2.1)
    return response;
  }

  @override
  Future<void> logout() async {
    // Limpiar tokens locales (R5.1)
    await _tokenStorage.clear();
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await _authApi.refresh(refreshToken);

    // Guardar los nuevos tokens (R4.1)
    await _tokenStorage.saveTokens(
      response.accessToken,
      response.refreshToken,
    );

    return response;
  }

  @override
  Future<bool> isLoggedIn() async {
    // Verificar si existen tokens locales (R1.1, R1.2)
    return _tokenStorage.hasTokens();
  }
}

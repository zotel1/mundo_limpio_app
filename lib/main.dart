// Punto de entrada de la aplicación MundoLimpio.
//
// Configura el árbol de dependencias via MultiProvider:
// 1. TokenStorage — almacenamiento seguro de tokens JWT
// 2. AuthRepository — capa de datos de autenticación
// 3. AuthProvider — estado global de autenticación (ChangeNotifier)
//
// Luego renderiza MundoLimpioApp con MaterialApp.router.
//
// TDD: GREEN — implementación con MultiProvider + MaterialApp.router

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/network/auth_interceptor.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/api/auth_api.dart';
import 'features/auth/data/repository/auth_repository_impl.dart';
import 'features/auth/domain/repository/auth_repository.dart';
import 'features/auth/presentation/provider/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // ------------------------------------------------------------------
        // Almacenamiento seguro de tokens
        // ------------------------------------------------------------------
        Provider<TokenStorage>(
          create: (_) => TokenStorage(),
        ),

        // ------------------------------------------------------------------
        // Repositorio de autenticación
        // ------------------------------------------------------------------
        Provider<AuthRepository>(
          create: (ctx) {
            final tokenStorage = ctx.read<TokenStorage>();

            // Dio para refresh — SIN AuthInterceptor (evita loops infinitos)
            final tokenDio = ApiClient.create();

            // Interceptor de autenticación JWT
            final authInterceptor = AuthInterceptor(
              dio: ApiClient.create(),
              tokenDio: tokenDio,
              tokenStorage: tokenStorage,
            );

            // Dio principal — CON AuthInterceptor para requests autenticados
            final dio = ApiClient.create(
              extraInterceptors: [authInterceptor],
            );

            return AuthRepositoryImpl(
              authApi: AuthApi(dio: dio),
              tokenStorage: tokenStorage,
            );
          },
        ),

        // ------------------------------------------------------------------
        // Provider de autenticación (ChangeNotifier para UI reactiva)
        // ------------------------------------------------------------------
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) {
            final authProvider = AuthProvider(
              ctx.read<AuthRepository>(),
            );

            // Iniciar verificación de autenticación al arrancar
            authProvider.checkAuth();

            return authProvider;
          },
        ),
      ],
      child: const MundoLimpioApp(),
    ),
  );
}

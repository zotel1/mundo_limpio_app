// Punto de entrada de la aplicación MundoLimpio.
//
// Configura el árbol de dependencias via MultiProvider:
// 1. TokenStorage — almacenamiento seguro de tokens JWT
// 2. Dio compartido — instancia única con AuthInterceptor para toda la app
// 3. AuthRepository — capa de datos de autenticación
// 4. AuthProvider — estado global de autenticación (ChangeNotifier)
// 5. SalesApi — cliente HTTP para el módulo de ventas
// 6. SalesRepository — capa de datos de ventas
// 7. SalesProvider — estado del flujo de venta (ChangeNotifier)
//
// Luego renderiza MundoLimpioApp con MaterialApp.router.
//
// TDD: GREEN — implementación con MultiProvider + MaterialApp.router

import 'package:dio/dio.dart';
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
import 'features/inventory/data/api/inventory_api.dart';
import 'features/inventory/data/repository/inventory_repository_impl.dart';
import 'features/inventory/domain/repository/inventory_repository.dart';
import 'features/inventory/presentation/provider/inventory_provider.dart';
import 'features/sales/data/api/sales_api.dart';
import 'features/sales/data/repository/sales_repository_impl.dart';
import 'features/sales/domain/repository/sales_repository.dart';
import 'features/sales/presentation/provider/sales_provider.dart';

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
        // Dio compartido con AuthInterceptor (T-5.2)
        //
        // Crea una única instancia de Dio con el interceptor de auth
        // para que AuthApi y SalesApi compartan la misma conexión,
        // cookies y lógica de refresh automático.
        // ------------------------------------------------------------------
        Provider<Dio>(
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
            return ApiClient.create(
              extraInterceptors: [authInterceptor],
            );
          },
        ),

        // ------------------------------------------------------------------
        // Repositorio de autenticación (usa el Dio compartido)
        // ------------------------------------------------------------------
        Provider<AuthRepository>(
          create: (ctx) {
            final dio = ctx.read<Dio>();
            final tokenStorage = ctx.read<TokenStorage>();

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

        // ------------------------------------------------------------------
        // Sales API (usa el Dio compartido)
        // ------------------------------------------------------------------
        Provider<SalesApi>(
          create: (ctx) => SalesApi(dio: ctx.read<Dio>()),
        ),

        // ------------------------------------------------------------------
        // Sales Repository
        // ------------------------------------------------------------------
        Provider<SalesRepository>(
          create: (ctx) => SalesRepositoryImpl(
            salesApi: ctx.read<SalesApi>(),
          ),
        ),

        // ------------------------------------------------------------------
        // Sales Provider (ChangeNotifier para UI reactiva)
        // ------------------------------------------------------------------
        ChangeNotifierProvider<SalesProvider>(
          create: (ctx) => SalesProvider(
            ctx.read<SalesRepository>(),
          ),
        ),

        // ------------------------------------------------------------------
        // Inventory API (usa el Dio compartido)
        // ------------------------------------------------------------------
        Provider<InventoryApi>(
          create: (ctx) => InventoryApi(dio: ctx.read<Dio>()),
        ),

        // ------------------------------------------------------------------
        // Inventory Repository
        // ------------------------------------------------------------------
        Provider<InventoryRepository>(
          create: (ctx) => InventoryRepositoryImpl(
            inventoryApi: ctx.read<InventoryApi>(),
          ),
        ),

        // ------------------------------------------------------------------
        // Inventory Provider (ChangeNotifier para UI reactiva)
        // ------------------------------------------------------------------
        ChangeNotifierProvider<InventoryProvider>(
          create: (ctx) => InventoryProvider(
            repository: ctx.read<InventoryRepository>(),
          ),
        ),
      ],
      child: const MundoLimpioApp(),
    ),
  );
}

// Punto de entrada de la aplicación MundoLimpio.
//
// Configura el árbol de dependencias via MultiProvider:
// 1. TokenStorage — almacenamiento seguro de tokens JWT
// 2. Dio compartido — instancia única con AuthInterceptor para toda la app
// 3. ConnectivityService — monitoreo online/offline con ChangeNotifier
// 4. CrashlyticsService — reporte de crashes a Firebase (PR#4)
// 5. AppDatabase — SQLite local (Drift) para persistencia offline
// 6. DAOs — acceso tipado a cada tabla del esquema offline
// 7. SalesApi + InventoryApi — clientes HTTP
// 8. SyncService — sincronización al reconectar
// 9. Repositories + Providers — auth, ventas, inventario
//
// Luego renderiza MundoLimpioApp con MaterialApp.router.
//
// TDD: GREEN — PR3: agregar SplashRepository + SplashProvider al composition root

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/crashlytics/crashlytics_service.dart';
import 'core/drift/app_database.dart';
import 'core/drift/daos/batch_cache_dao.dart';
import 'core/drift/daos/draft_sale_dao.dart';
import 'core/drift/daos/inventory_cache_dao.dart';
import 'core/drift/daos/inventory_pending_dao.dart';
import 'core/drift/daos/product_cache_dao.dart';
import 'core/network/api_client.dart';
import 'core/network/auth_interceptor.dart';
import 'core/storage/token_storage.dart';
import 'core/sync/sync_service.dart';
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
import 'features/splash/data/splash_repository_impl.dart';
import 'features/splash/domain/splash_repository.dart';
import 'features/splash/presentation/splash_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Infraestructura inicializada antes de runApp ───────────
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  // Inicializar Crashlytics para capturar errores fatales (PR#4)
  await CrashlyticsService.initialize();

  final db = AppDatabase();

  runApp(
    MultiProvider(
      providers: [
        // ── Core: almacenamiento seguro ──────────────────────
        Provider<TokenStorage>(create: (_) => TokenStorage()),

        // ── Core: Dio compartido con AuthInterceptor ─────────
        Provider<Dio>(
          create: (ctx) {
            final tokenStorage = ctx.read<TokenStorage>();
            final tokenDio = ApiClient.create();
            final authInterceptor = AuthInterceptor(
              dio: ApiClient.create(),
              tokenDio: tokenDio,
              tokenStorage: tokenStorage,
            );
            return ApiClient.create(extraInterceptors: [authInterceptor]);
          },
        ),

        // ── Core: conectividad (PR#1) ────────────────────────
        ChangeNotifierProvider<ConnectivityService>.value(
          value: connectivityService,
        ),

        // ── Core: base de datos offline (PR#1) ───────────────
        Provider<AppDatabase>.value(value: db),

        // ── DAOs (PR#1) ──────────────────────────────────────
        Provider<ProductCacheDao>(create: (_) => ProductCacheDao(db)),
        Provider<BatchCacheDao>(create: (_) => BatchCacheDao(db)),
        Provider<InventoryCacheDao>(create: (_) => InventoryCacheDao(db)),
        Provider<DraftSaleDao>(create: (_) => DraftSaleDao(db)),
        Provider<InventoryPendingDao>(create: (_) => InventoryPendingDao(db)),

        // ── APIs (sin cambios) ───────────────────────────────
        Provider<SalesApi>(create: (ctx) => SalesApi(dio: ctx.read<Dio>())),
        Provider<InventoryApi>(
          create: (ctx) => InventoryApi(dio: ctx.read<Dio>()),
        ),

        // ── SyncService (PR#1) ───────────────────────────────
        Provider<SyncService>(
          create: (ctx) {
            final service = SyncService(
              connectivity: ctx.read<ConnectivityService>(),
              inventoryPendingDao: ctx.read<InventoryPendingDao>(),
              inventoryApi: ctx.read<InventoryApi>(),
              productCacheDao: ctx.read<ProductCacheDao>(),
              inventoryCacheDao: ctx.read<InventoryCacheDao>(),
              draftSaleDao: ctx.read<DraftSaleDao>(),
              salesApi: ctx.read<SalesApi>(),
            );
            service.initialize();
            return service;
          },
        ),

        // ── Repositorios (sin cambios en PR#1) ───────────────
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

        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) {
            final authProvider = AuthProvider(ctx.read<AuthRepository>());
            authProvider.checkAuth();
            return authProvider;
          },
        ),

        Provider<SalesRepository>(
          create: (ctx) => SalesRepositoryImpl(
            salesApi: ctx.read<SalesApi>(),
            connectivity: ctx.read<ConnectivityService>(),
            productCacheDao: ctx.read<ProductCacheDao>(),
            batchCacheDao: ctx.read<BatchCacheDao>(),
            draftSaleDao: ctx.read<DraftSaleDao>(),
          ),
        ),

        ChangeNotifierProvider<SalesProvider>(
          create: (ctx) => SalesProvider(ctx.read<SalesRepository>()),
        ),

        Provider<InventoryRepository>(
          create: (ctx) => InventoryRepositoryImpl(
            inventoryApi: ctx.read<InventoryApi>(),
            connectivity: ctx.read<ConnectivityService>(),
            inventoryCacheDao: ctx.read<InventoryCacheDao>(),
            inventoryPendingDao: ctx.read<InventoryPendingDao>(),
          ),
        ),

        ChangeNotifierProvider<InventoryProvider>(
          create: (ctx) =>
              InventoryProvider(repository: ctx.read<InventoryRepository>()),
        ),

        // ── Splash: salud del backend y estado del splash screen ──
        Provider<SplashRepository>(
          create: (_) {
            final healthDio = Dio(
              BaseOptions(
                baseUrl: AppConfig.healthBaseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );
            return SplashRepositoryImpl(dio: healthDio);
          },
        ),

        ChangeNotifierProvider<SplashProvider>(
          create: (ctx) => SplashProvider(ctx.read<SplashRepository>()),
        ),
      ],
      child: const MundoLimpioApp(),
    ),
  );
}

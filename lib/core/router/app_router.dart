// Configuración del router de la aplicación.
//
// Define las rutas de la app y la lógica de redirect
// basada en el estado de autenticación (AuthStatus) y el splash.
//
// Usa GoRouter con refreshListenable = Listenable.merge([authProvider, splashProvider])
// para que los redirects se reevalúen automáticamente cuando cualquiera
// de los dos providers notifica cambios.
//
// TDD: GREEN — splash-auth-flow: splash guard + splash-first initialLocation

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/home_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/register_screen.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/screens/inventory_detail_screen.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/create_sale_screen.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/sale_result_screen.dart';
import 'package:mundo_limpio_app/features/products/presentation/screens/products_detail_screen.dart';
import 'package:mundo_limpio_app/features/products/presentation/screens/products_form_screen.dart';
import 'package:mundo_limpio_app/features/products/presentation/screens/products_list_screen.dart';
import 'package:mundo_limpio_app/features/users/presentation/screens/users_list_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/bulk/bulk_product_list_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_batch_list_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_create_screen.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_process_response.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_response.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/screens/receipt_capture_screen.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/screens/receipt_review_screen.dart';
import 'package:mundo_limpio_app/features/receipts/presentation/screens/receipt_confirmed_screen.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_provider.dart';
import 'package:mundo_limpio_app/features/splash/presentation/splash_screen.dart';

// ---------------------------------------------------------------------------
// Fábrica del router
// ---------------------------------------------------------------------------

/// Crea un [GoRouter] que protege rutas según [authProvider] y [splashProvider].
///
/// [authProvider] se usa para:
/// 1. Leer el estado actual via [AuthProvider.status]
/// 2. Notificar cambios via [ChangeNotifier] (refreshListenable)
///
/// [splashProvider] se usa para:
/// 1. Renderizar el splash screen interactivo
/// 2. Notificar cambios via [ChangeNotifier] (refreshListenable)
///
/// [initialLocation] permite arrancar desde una ruta específica
/// (por defecto: '/splash').
///
/// Lógica de redirect:
/// - /splash SIEMPRE retorna null (nunca redirige desde splash)
/// - loading → null (safety fallthrough — splash ya es la primera ruta)
/// - unauthenticated → /login y /register libres; el resto redirige a /login
/// - authenticated → /login y /register redirigen a /; /splash no entra aquí
GoRouter createRouter(
  AuthProvider authProvider,
  SplashProvider splashProvider, {
  String initialLocation = '/splash',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: Listenable.merge([authProvider, splashProvider]),
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Splash guard: NUNCA redirigir desde /splash
      if (location == '/splash') return null;

      final status = authProvider.status;

      // Roles de stock que pueden acceder a producción y recibos
      const stockRoles = ['ADMIN', 'STOCK_MANAGER'];

      // Proteger rutas de administración: ADMIN y STOCK_MANAGER pueden acceder
      if (status == AuthStatus.authenticated &&
          (location.startsWith('/production/') ||
              location.startsWith('/receipts/'))) {
        final roles = authProvider.roles;
        if (roles == null || !roles.any((r) => stockRoles.contains(r))) {
          return '/';
        }
      }

      // /users es solo ADMIN
      if (status == AuthStatus.authenticated && location.startsWith('/users')) {
        final roles = authProvider.roles;
        if (roles == null || !roles.contains('ADMIN')) {
          return '/';
        }
      }

      switch (status) {
        case AuthStatus.loading:
          // Safety fallthrough: splash ya se muestra via initialLocation
          return null;

        case AuthStatus.unauthenticated:
          // Solo login y register son accesibles (R6.1)
          if (location == '/login' || location == '/register') return null;
          return '/login';

        case AuthStatus.authenticated:
          // Redirigir al home si está en pantallas de auth (R6.2)
          if (location == '/login' || location == '/register') {
            return '/';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/sales/new', builder: (_, _) => const CreateSaleScreen()),
      GoRoute(
        path: '/inventory',
        builder: (_, _) => const InventoryListScreen(),
      ),
      GoRoute(
        path: '/inventory/:productId',
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['productId']!);
          return InventoryDetailScreen(productId: productId);
        },
      ),
      GoRoute(path: '/products', builder: (_, _) => const ProductsListScreen()),
      GoRoute(
        path: '/products/new',
        builder: (_, _) => const ProductsFormScreen(),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductsDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (context, state) {
          // En edit mode via GoRouter, el form recibe null
          // (se muestra en create mode hasta que se implemente carga por id)
          return const ProductsFormScreen();
        },
      ),
      GoRoute(path: '/users', builder: (_, _) => const UsersListScreen()),
      GoRoute(
        path: '/production/bulk-products',
        builder: (_, _) => const BulkProductListScreen(),
      ),
      GoRoute(
        path: '/production/batches',
        builder: (_, _) => const ProductionBatchListScreen(),
      ),
      GoRoute(
        path: '/production/batches/new',
        builder: (_, _) => const ProductionCreateScreen(),
      ),
      GoRoute(
        path: '/sales/result',
        builder: (context, state) {
          // SaleResultScreen requiere un SaleResponse recibido vía
          // state.extra desde GoRouter. En el flujo actual,
          // CreateSaleScreen navega via Navigator.pushReplacement
          // pasando el objeto directamente, pero la ruta existe
          // para futura navegación con GoRouter (state.extra).
          final sale = state.extra as SaleResponse?;
          if (sale == null) {
            return const Scaffold(
              body: Center(child: Text('Error: datos de venta no disponibles')),
            );
          }
          return SaleResultScreen(sale: sale);
        },
      ),

      // --- Recibos (OCR) ---
      GoRoute(
        path: '/receipts/new',
        builder: (_, _) => const ReceiptCaptureScreen(),
      ),
      GoRoute(
        path: '/receipts/review',
        builder: (context, state) {
          final response = state.extra as ReceiptProcessResponse?;
          if (response == null) {
            return const Scaffold(
              body: Center(
                child: Text('Error: datos de recibo no disponibles'),
              ),
            );
          }
          return ReceiptReviewScreen(processResponse: response);
        },
      ),
      GoRoute(
        path: '/receipts/confirmed',
        builder: (context, state) {
          final purchase = state.extra as PurchaseResponse?;
          if (purchase == null) {
            return const Scaffold(
              body: Center(
                child: Text('Error: datos de compra no disponibles'),
              ),
            );
          }
          return ReceiptConfirmedScreen(purchase: purchase);
        },
      ),
    ],
  );
}

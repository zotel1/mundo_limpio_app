// Configuración del router de la aplicación.
//
// Define las rutas de la app y la lógica de redirect
// basada en el estado de autenticación (AuthStatus).
//
// Usa GoRouter con refreshListenable para que los redirects
// se reevalúen automáticamente cuando AuthProvider notifica
// cambios en el estado de autenticación.
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mundo_limpio_app/core/theme/app_colors.dart';
import 'package:mundo_limpio_app/core/widgets/logo_widget.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/register_screen.dart';
import 'package:mundo_limpio_app/features/auth/presentation/screens/home_screen.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/screens/inventory_detail_screen.dart';
import 'package:mundo_limpio_app/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/create_sale_screen.dart';
import 'package:mundo_limpio_app/features/sales/presentation/screens/sale_result_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/bulk/bulk_product_list_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_batch_list_screen.dart';
import 'package:mundo_limpio_app/features/production/presentation/screens/production/production_create_screen.dart';

// ---------------------------------------------------------------------------
// Pantalla de splash / carga
// ---------------------------------------------------------------------------

/// Pantalla que se muestra mientras se resuelve el estado de auth.
///
/// Aparece durante el startup cuando AuthStatus es loading.
/// Muestra el logo de la marca centrado sobre fondo navy con un
/// indicador de carga sutil debajo.
/// Tan pronto como el estado cambia a authenticated o unauthenticated,
/// el redirect de GoRouter redirige a la ruta correspondiente.
///
/// TDD: GREEN — reemplazar bare CircularProgressIndicator por splash con branding
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoWidget(size: 100),
            SizedBox(height: 32),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fábrica del router
// ---------------------------------------------------------------------------

/// Crea un [GoRouter] que protege rutas según [authProvider].
///
/// [authProvider] se usa para:
/// 1. Leer el estado actual via [AuthProvider.status]
/// 2. Notificar cambios via [ChangeNotifier] (refreshListenable)
///
/// [initialLocation] permite arrancar desde una ruta específica
/// (por defecto: '/').
///
/// Lógica de redirect:
/// - loading → redirige a /splash si no está ahí
/// - unauthenticated → /login y /register libres; el resto redirige a /login
/// - authenticated → /login, /register y /splash redirigen a /
GoRouter createRouter(
  AuthProvider authProvider, {
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final location = state.matchedLocation;

      // Proteger rutas de producción: solo ADMIN puede acceder
      if (status == AuthStatus.authenticated &&
          location.startsWith('/production/') &&
          authProvider.role != 'ADMIN') {
        return '/';
      }

      switch (status) {
        case AuthStatus.loading:
          // Mostrar splash mientras se resuelve el estado
          if (location != '/splash') return '/splash';
          return null;

        case AuthStatus.unauthenticated:
          // Solo login y register son accesibles (R6.1)
          if (location == '/login' || location == '/register') return null;
          return '/login';

        case AuthStatus.authenticated:
          // Redirigir al home si está en pantallas de auth (R6.2)
          if (location == '/login' ||
              location == '/register' ||
              location == '/splash') {
            return '/';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _SplashScreen()),
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
    ],
  );
}

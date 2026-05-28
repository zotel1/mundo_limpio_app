// Pantalla principal post-login.
//
// Muestra un mensaje de bienvenida y un botón de cerrar sesión
// con confirmación. Después del logout navega a LoginScreen.
//
// Estados:
// - AUTHENTICATED: muestra bienvenida + botón logout
// - LOGOUT CONFIRMATION: diálogo de confirmación
// - POST-LOGOUT: navegación a LoginScreen
//
// TDD: GREEN — creado después de que AuthProvider pasa los tests

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';

import '../provider/auth_provider.dart';

/// Verifica si el usuario tiene al menos uno de los [allowedRoles].
bool _hasRole(AuthProvider auth, List<String> allowedRoles) {
  final roles = auth.roles;
  if (roles == null) return false;
  return roles.any((r) => allowedRoles.contains(r));
}

/// Verifica si el usuario autenticado tiene acceso a rutas de stock.
bool _canAccess(AuthProvider auth) {
  return _hasRole(auth, [
    UserRole.admin.jsonValue,
    UserRole.stockManager.jsonValue,
  ]);
}

/// Pantalla de inicio después de autenticación exitosa con bottom nav.
///
/// Usa [IndexedStack] para mantener el estado de cada tab al alternar.
/// Tab 0: pantalla de bienvenida + botones de gestión (para roles habilitados).
/// Tab 1: lista de productos para clientes; mismos botones de gestión para admins.
/// Tab 2: perfil del usuario con datos y cierre de sesión.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasAccess = _canAccess(auth);
    final isAdmin = auth.roles?.contains(UserRole.admin.jsonValue) == true;

    return Scaffold(
      appBar: _buildAppBar(auth),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(auth, hasAccess, isAdmin),
          hasAccess
              ? _buildHomeTab(auth, hasAccess, isAdmin)
              : _buildProductsTab(),
          _buildProfileTab(auth),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(hasAccess),
    );
  }

  PreferredSizeWidget? _buildAppBar(AuthProvider auth) {
    switch (_currentIndex) {
      case 0:
        return BrandedAppBar(
          title: 'MundoLimpio',
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        );
      case 2:
        return AppBar(title: const Text('Perfil'));
      default:
        return null;
    }
  }

  Widget _buildHomeTab(AuthProvider auth, bool hasAccess, bool isAdmin) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Bienvenido! Sesión iniciada correctamente.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            // Botones solo para administradores y gestores de stock
            if (hasAccess) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/sales/new'),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Nueva Venta'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/inventory'),
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Inventario'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/production/bulk-products'),
                  icon: const Icon(Icons.category),
                  label: const Text('Materias Primas'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/production/batches/new'),
                  icon: const Icon(Icons.precision_manufacturing),
                  label: const Text('Nueva Producción'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/production/batches'),
                  icon: const Icon(Icons.history),
                  label: const Text('Historial Producción'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/products'),
                  icon: const Icon(Icons.inventory),
                  label: const Text('Productos'),
                ),
              ),
              // Botón "Usuarios" solo para ADMIN
              if (isAdmin) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/users'),
                    icon: const Icon(Icons.people),
                    label: const Text('Usuarios'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/receipts/new'),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Escanear Recibo'),
                ),
              ),
              // Historial de Ventas: ADMIN, SALES_CLERK, ACCOUNTANT
              if (_hasRole(auth, [
                UserRole.admin.jsonValue,
                UserRole.salesClerk.jsonValue,
                UserRole.accountant.jsonValue,
              ])) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/sales/history'),
                    icon: const Icon(Icons.receipt),
                    label: const Text('Historial Ventas'),
                  ),
                ),
              ],
              // Historial de Recibos: ADMIN, STOCK_MANAGER, ACCOUNTANT
              if (_hasRole(auth, [
                UserRole.admin.jsonValue,
                UserRole.stockManager.jsonValue,
                UserRole.accountant.jsonValue,
              ])) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/receipts/history'),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Historial Recibos'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_outlined,
              size: 80,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Explorá nuestro catálogo de productos',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/products'),
              icon: const Icon(Icons.search),
              label: const Text('Ver Productos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(AuthProvider auth) {
    final email = auth.email;
    final roles = auth.roles;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text(email ?? 'Sin email', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (roles != null)
              Text(
                'Roles: ${roles.join(', ')}',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool hasAccess) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(
            hasAccess
                ? Icons.admin_panel_settings_outlined
                : Icons.inventory_outlined,
          ),
          selectedIcon: Icon(
            hasAccess ? Icons.admin_panel_settings : Icons.inventory,
          ),
          label: hasAccess ? 'Gestión' : 'Productos',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }

  /// Muestra diálogo de confirmación antes de cerrar sesión.
  void _showLogoutDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que querés cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        // Limpiar sesión y redirigir al login
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          context.go('/login');
        }
      }
    });
  }
}

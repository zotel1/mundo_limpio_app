// Pantalla principal post-login con navegación adaptada por rol.
//
// Muestra landing con ActionCards según el rol del usuario:
// - ADMIN: acciones completas del sistema
// - STOCK_MANAGER / STOCK_OPERATOR: gestión de stock y recibos
// - SALES_CLERK: productos y nueva venta
// - PRODUCTION_OP: productos y producción
// - ACCOUNTANT: productos + placeholder de costos
// - CUSTOMER: solo catálogo de productos
//
// El BottomNavigationBar adapta sus destinos según el rol.
// Usa IndexedStack para mantener el estado de cada tab.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';

import '../provider/auth_provider.dart';

/// Pantalla de inicio después de autenticación exitosa con bottom nav.
///
/// Usa [IndexedStack] para mantener el estado de cada tab al alternar.
/// Tab 0: landing page por rol con ActionCards.
/// Tab 1: gestión (ADMIN) o catálogo de productos (otros roles).
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
    final roles = auth.roles ?? ['CUSTOMER'];

    return Scaffold(
      appBar: _buildAppBar(auth),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildLandingForRole(roles),
          roles.contains('ADMIN')
              ? _buildLandingForRole(roles)
              : _buildProductsTab(),
          _buildProfileTab(auth),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(roles),
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

  /// Tarjeta de acción reutilizable: ElevatedButton.icon con ruta.
  Widget _actionCard({
    required IconData icon,
    required String label,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: 220,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => context.push(route),
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  /// Landing page según el primer rol del usuario.
  Widget _buildLandingForRole(List<String> roles) {
    final role = roles.isNotEmpty ? roles.first : 'CUSTOMER';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Bienvenido',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '¿Qué querés hacer hoy?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            switch (role) {
              'ADMIN' => _buildAdminActions(),
              'ACCOUNTANT' => _buildAccountantActions(),
              'STOCK_OPERATOR' => _buildStockOperatorActions(),
              'SALES_CLERK' => _buildSalesClerkActions(),
              'PRODUCTION_OP' => _buildProductionOpActions(),
              'STOCK_MANAGER' => _buildStockManagerActions(),
              'CUSTOMER' => _buildCustomerActions(),
              _ => _buildCustomerActions(),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActions() {
    return Column(
      children: [
        _actionCard(
          icon: Icons.inventory,
          label: 'Ver Productos',
          route: '/products',
        ),
        _actionCard(
          icon: Icons.inventory_2,
          label: 'Ver Inventario',
          route: '/inventory',
        ),
        _actionCard(
          icon: Icons.precision_manufacturing,
          label: 'Producción',
          route: '/production/batches',
        ),
        _actionCard(
          icon: Icons.add_shopping_cart,
          label: 'Ventas',
          route: '/sales/new',
        ),
        _actionCard(icon: Icons.people, label: 'Usuarios', route: '/users'),
        _actionCard(
          icon: Icons.receipt_long,
          label: 'Recibos',
          route: '/receipts/new',
        ),
        _actionCard(
          icon: Icons.receipt,
          label: 'Historial Ventas',
          route: '/sales/history',
        ),
        _actionCard(
          icon: Icons.receipt_long,
          label: 'Historial Recibos',
          route: '/receipts/history',
        ),
        _actionCard(
          icon: Icons.backup,
          label: 'Backups',
          route: '/admin/backups',
        ),
      ],
    );
  }

  Widget _buildAccountantActions() {
    return Column(
      children: [
        _actionCard(
          icon: Icons.inventory,
          label: 'Ver Productos',
          route: '/products',
        ),
        _actionCard(
          icon: Icons.receipt,
          label: 'Historial Ventas',
          route: '/sales/history',
        ),
        _actionCard(
          icon: Icons.receipt_long,
          label: 'Historial Recibos',
          route: '/receipts/history',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.bar_chart, size: 48, color: Colors.blueGrey),
                const SizedBox(height: 12),
                Text(
                  'Módulo de Costos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Próximamente vas a poder gestionar costos, '
                  'márgenes y reportes financieros desde esta sección.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockOperatorActions() {
    return Column(
      children: [
        _actionCard(
          icon: Icons.inventory,
          label: 'Ver Productos',
          route: '/products',
        ),
        _actionCard(
          icon: Icons.inventory_2,
          label: 'Ver Inventario',
          route: '/inventory',
        ),
        _actionCard(
          icon: Icons.receipt_long,
          label: 'Recibos',
          route: '/receipts/new',
        ),
      ],
    );
  }

  Widget _buildSalesClerkActions() {
    return Column(
      children: [
        _actionCard(
          icon: Icons.inventory,
          label: 'Ver Productos',
          route: '/products',
        ),
        _actionCard(
          icon: Icons.add_shopping_cart,
          label: 'Nueva Venta',
          route: '/sales/new',
        ),
        _actionCard(
          icon: Icons.receipt,
          label: 'Historial Ventas',
          route: '/sales/history',
        ),
      ],
    );
  }

  Widget _buildProductionOpActions() {
    return Column(
      children: [
        _actionCard(
          icon: Icons.inventory,
          label: 'Ver Productos',
          route: '/products',
        ),
        _actionCard(
          icon: Icons.precision_manufacturing,
          label: 'Producción',
          route: '/production/batches/new',
        ),
      ],
    );
  }

  Widget _buildStockManagerActions() {
    return Column(
      children: [
        _actionCard(
          icon: Icons.inventory,
          label: 'Ver Productos',
          route: '/products',
        ),
        _actionCard(
          icon: Icons.inventory_2,
          label: 'Ver Inventario',
          route: '/inventory',
        ),
        _actionCard(
          icon: Icons.receipt_long,
          label: 'Recibos',
          route: '/receipts/new',
        ),
        _actionCard(
          icon: Icons.receipt_long,
          label: 'Historial Recibos',
          route: '/receipts/history',
        ),
      ],
    );
  }

  Widget _buildCustomerActions() {
    return Column(
      children: [
        _actionCard(
          icon: Icons.inventory,
          label: 'Ver Productos',
          route: '/products',
        ),
      ],
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

  NavigationBar _buildBottomNav(List<String> roles) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
      },
      destinations: _destinationsForRole(roles),
    );
  }

  /// Destinos del BottomNavigationBar filtrados por rol.
  List<NavigationDestination> _destinationsForRole(List<String> roles) {
    if (roles.contains('ADMIN')) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Gestión',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }
    return const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_outlined),
        selectedIcon: Icon(Icons.inventory),
        label: 'Productos',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outlined),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];
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
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          context.go('/login');
        }
      }
    });
  }
}

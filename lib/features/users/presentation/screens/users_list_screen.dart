// Pantalla de lista de Usuarios (admin).
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Muestra lista con estados: loading, loaded (con datos o vacío), error.
// Incluye pull-to-refresh y navegación al detalle del usuario.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';
import 'package:mundo_limpio_app/features/users/presentation/providers/users_provider.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<UsersProvider>();
      if (provider.status != UsersStatus.loaded) {
        provider.loadUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();
    return Scaffold(
      appBar: const BrandedAppBar(title: 'Usuarios'),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(UsersProvider provider) {
    return _buildListContent(provider);
  }

  Widget _buildListContent(UsersProvider provider) {
    switch (provider.status) {
      case UsersStatus.initial:
      case UsersStatus.loading:
        if (provider.users.isNotEmpty) {
          return _buildUserList(provider);
        }
        return const Center(child: CatLoadingIndicator.general());

      case UsersStatus.loaded:
        if (provider.users.isEmpty) {
          return const Center(child: Text('No hay usuarios'));
        }
        return _buildUserList(provider);

      case UsersStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.error ?? 'Error desconocido'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => provider.loadUsers(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );

      case UsersStatus.updatingRole:
      case UsersStatus.resettingPassword:
        return _buildUserList(provider);
    }
  }

  Widget _buildUserList(UsersProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.loadUsers(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.users.length,
        itemBuilder: (context, index) {
          final user = provider.users[index];
          return Card(
            child: ListTile(
              title: Text(user.username),
              subtitle: Text(user.email),
              trailing: Wrap(
                spacing: 4,
                children: user.roles.map((role) {
                  return Chip(
                    label: Text(
                      _roleLabel(role),
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              onTap: () => _navigateToDetail(user.id),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(int userId) {
    context.push('/users/$userId');
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.admin => 'ADMIN',
      UserRole.stockManager => 'Stock Manager',
      UserRole.stockOperator => 'Stock Operator',
      UserRole.salesClerk => 'Sales Clerk',
      UserRole.productionOp => 'Producción',
      UserRole.accountant => 'Contador',
      UserRole.customer => 'Cliente',
    };
  }
}

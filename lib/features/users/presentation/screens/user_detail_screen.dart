// Pantalla de detalle de Usuario (admin).
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Muestra información completa del usuario y acciones:
// - Datos del perfil (username, email, createdAt)
// - Multi-role selector con checkboxes (ADMIN exclusivo)
// - Botón Save Roles con confirmación
// - Botón Reset Password con diálogo de nueva contraseña

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/features/auth/presentation/provider/auth_provider.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';
import 'package:mundo_limpio_app/features/users/presentation/providers/users_provider.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Set<UserRole> _selectedRoles = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UsersProvider>().loadUser(widget.userId);
    });
  }

  void _initRoles(User user) {
    if (!_initialized) {
      _selectedRoles = Set.from(user.roles);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = provider.selectedUser;
    final currentUsername = authProvider.username;

    // Inicializar roles locales al cargar el usuario
    if (user != null && provider.status == UsersStatus.loaded) {
      _initRoles(user);
    }

    return Scaffold(
      appBar: AppBar(title: Text(user?.username ?? 'Detalle del Usuario')),
      body: SafeArea(child: _buildBody(provider, user, currentUsername)),
    );
  }

  Widget _buildBody(
    UsersProvider provider,
    User? user,
    String? currentUsername,
  ) {
    switch (provider.status) {
      case UsersStatus.initial:
      case UsersStatus.loading:
        return const Center(child: CatLoadingIndicator.general());

      case UsersStatus.loaded:
      case UsersStatus.updatingRole:
      case UsersStatus.resettingPassword:
        if (user == null) {
          return const Center(child: Text('Usuario no encontrado'));
        }
        return _buildDetailContent(provider, user, currentUsername);

      case UsersStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.error ?? 'Error desconocido'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => provider.loadUser(widget.userId),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDetailContent(
    UsersProvider provider,
    User user,
    String? currentUsername,
  ) {
    final isUpdating = provider.status == UsersStatus.updatingRole;
    final isResetting = provider.status == UsersStatus.resettingPassword;
    final isOwnProfile = currentUsername == user.username;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del perfil
              _buildSectionTitle('Información del Perfil'),
              const SizedBox(height: 8),
              _buildInfoField('Usuario', user.username),
              _buildInfoField('Email', user.email),
              _buildInfoField('Creado', _formatDate(user.createdAt)),
              const Divider(height: 32),

              // Selector de roles
              _buildSectionTitle('Roles'),
              const SizedBox(height: 8),
              _buildAdminCheckbox(user, isOwnProfile),
              _buildAdminWarning(),
              const SizedBox(height: 8),
              if (_selectedRoles.contains(UserRole.admin))
                _buildOtherRolesDisabled()
              else
                _buildOtherRoleCheckboxes(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : () => _onSaveRoles(user),
                  child: Text(isUpdating ? 'Guardando...' : 'Guardar Roles'),
                ),
              ),
              const Divider(height: 32),

              // Reset de contraseña
              _buildSectionTitle('Contraseña'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isResetting ? null : () => _onResetPassword(),
                  child: Text(
                    isResetting ? 'Reseteando...' : 'Resetear Contraseña',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isUpdating || isResetting)
          const ModalBarrier(dismissible: false, color: Colors.black26),
        if (isUpdating || isResetting)
          const Center(child: CatLoadingIndicator.small()),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildAdminCheckbox(User user, bool isOwnProfile) {
    final hasAdmin = _selectedRoles.contains(UserRole.admin);
    final canToggle = !isOwnProfile;

    return Tooltip(
      message: isOwnProfile ? 'No podés quitarte tu propio rol ADMIN' : '',
      child: CheckboxListTile(
        title: const Text(
          'ADMIN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Acceso completo al sistema'),
        value: hasAdmin,
        onChanged: canToggle
            ? (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedRoles.add(UserRole.admin);
                  } else {
                    _selectedRoles.remove(UserRole.admin);
                  }
                });
              }
            : null,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _buildAdminWarning() {
    if (!_selectedRoles.contains(UserRole.admin)) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Text(
        'ADMIN es exclusivo — no se puede combinar con otros roles',
        style: TextStyle(color: Colors.orange, fontSize: 12),
      ),
    );
  }

  Widget _buildOtherRolesDisabled() {
    final roles = UserRole.values.where((r) => r != UserRole.admin).toList();
    return Column(
      children: roles.map((role) {
        return CheckboxListTile(
          title: Text(_roleLabel(role)),
          value: _selectedRoles.contains(role),
          onChanged: null, // disabled
          controlAffinity: ListTileControlAffinity.trailing,
          subtitle: const Text('Desmarcá ADMIN primero'),
        );
      }).toList(),
    );
  }

  Widget _buildOtherRoleCheckboxes() {
    final roles = UserRole.values.where((r) => r != UserRole.admin).toList();
    return Column(
      children: roles.map((role) {
        final isChecked = _selectedRoles.contains(role);
        return CheckboxListTile(
          title: Text(_roleLabel(role)),
          value: isChecked,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedRoles.add(role);
              } else {
                _selectedRoles.remove(role);
              }
            });
          },
          controlAffinity: ListTileControlAffinity.trailing,
        );
      }).toList(),
    );
  }

  Future<void> _onSaveRoles(User user) async {
    // Capturar provider y messenger antes de cualquier async gap
    final usersProvider = context.read<UsersProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Validar ADMIN exclusivity
    if (_selectedRoles.contains(UserRole.admin) && _selectedRoles.length > 1) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('ADMIN no se puede combinar con otros roles'),
        ),
      );
      return;
    }

    // Mostrar confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar Roles'),
        content: Text(
          '¿Estás seguro que querés actualizar los roles de ${user.username}?\n\n'
          'Nuevos roles: ${_selectedRoles.map(_roleLabel).join(", ")}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await usersProvider.updateRoles(widget.userId, _selectedRoles);

    if (!mounted) return;

    if (usersProvider.status == UsersStatus.error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(usersProvider.error ?? 'Error al guardar roles'),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Roles actualizados correctamente')),
      );
    }
  }

  Future<void> _onResetPassword() async {
    // Capturar messenger y provider antes de cualquier async gap
    final passwordMessenger = ScaffoldMessenger.of(context);
    final passwordProvider = context.read<UsersProvider>();

    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newPassword = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetear Contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nueva Contraseña',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La contraseña es requerida';
                  }
                  if (value.trim().length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                ),
                obscureText: true,
                validator: (value) {
                  if (value != passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(passwordController.text.trim());
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (newPassword == null || !mounted) {
      passwordController.dispose();
      confirmController.dispose();
      return;
    }

    // Mostrar confirmación de acción
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Reseteo'),
        content: const Text(
          '¿Estás seguro que querés resetear la contraseña de este usuario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Resetear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      passwordController.dispose();
      confirmController.dispose();
      return;
    }

    await passwordProvider.resetPassword(widget.userId, newPassword);

    if (!mounted) return;

    if (passwordProvider.status == UsersStatus.error) {
      passwordMessenger.showSnackBar(
        SnackBar(
          content: Text(
            passwordProvider.error ?? 'Error al resetear contraseña',
          ),
        ),
      );
    } else {
      passwordMessenger.showSnackBar(
        const SnackBar(content: Text('Contraseña reseteada correctamente')),
      );
    }

    passwordController.dispose();
    confirmController.dispose();
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

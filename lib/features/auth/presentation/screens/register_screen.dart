// Pantalla de registro de usuario.
//
// Muestra formulario con email, contraseña y confirmación.
// Incluye validación CLIENTE antes de llamar a la API (R2.3):
// - Formato de email
// - Longitud mínima de contraseña (6 caracteres)
// - Coincidencia de contraseñas
//
// Estados:
// - IDLE: formulario vacío listo para ingresar datos
// - LOADING: spinner + botón deshabilitado mientras se procesa
// - ERROR: mensaje de error devuelto por AuthProvider
// - SUCCESS: navegación a LoginScreen con mensaje de confirmación
//
// TDD: GREEN — creado después de que AuthProvider pasa los tests

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mundo_limpio_app/core/widgets/branded_app_bar.dart';
import 'package:mundo_limpio_app/core/widgets/branded_error_banner.dart';
import 'package:mundo_limpio_app/core/widgets/cat_loading_indicator.dart';
import 'package:mundo_limpio_app/core/widgets/logo_widget.dart';

import '../helpers/validators.dart';
import '../provider/auth_provider.dart';

/// Pantalla de registro con formulario email+contraseña+confirmación.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Procesa el envío del formulario de registro.
  ///
  /// 1. Valida campos del formulario (validación cliente, R2.3)
  /// 2. Llama a AuthProvider.register()
  /// 3. Si éxito → navega a LoginScreen con mensaje
  Future<void> _handleRegister() async {
    // Validación cliente ANTES de llamar a la API (R2.3)
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    await auth.register(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    // Si no hay error, el registro fue exitoso → redirigir a login (R2.1)
    if (auth.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Iniciá sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Crear Cuenta'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de la marca arriba del formulario
                const LogoWidget(),
                const SizedBox(height: 16),

                // Mensaje de error (inline, usa BrandedErrorBanner)
                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: BrandedErrorBanner(
                      message: auth.error!,
                      onDismiss: () => auth.clearError(),
                    ),
                  ),

                // Campo de email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.validateEmail,
                ),
                const SizedBox(height: 16),

                // Campo de contraseña
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.validatePasswordMinLength,
                ),
                const SizedBox(height: 16),

                // Campo de confirmación de contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: auth.isLoading
                      ? null
                      : (_) => _handleRegister(),
                  validator: (value) => AuthValidators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: 24),

                // Botón de envío
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleRegister,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CatLoadingIndicator.small(),
                          )
                        : const Text(
                            'Crear Cuenta',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Link a login
                TextButton(
                  onPressed: auth.isLoading
                      ? null
                      : () => context.go('/login'),
                  child: const Text('¿Ya tenés cuenta? Iniciá Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

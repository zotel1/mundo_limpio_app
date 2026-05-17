// Pantalla de inicio de sesión.
//
// Muestra formulario con email y contraseña, validación cliente,
// indicador de carga, y navegación al home en caso de éxito.
//
// Estados:
// - IDLE: formulario vacío listo para ingresar datos
// - LOADING: spinner + botón deshabilitado mientras se procesa
// - ERROR: mensaje de error devuelto por AuthProvider
// - SUCCESS: navigación a HomeScreen
//
// TDD: GREEN — creado después de que AuthProvider pasa los tests
//
// NOTA: GoRouter se integra en Phase 5. Por ahora se usa
// Navigator.pushReplacement para navegación simple.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/validators.dart';
import '../provider/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// Pantalla de login con formulario email+contraseña.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Procesa el envío del formulario de login.
  ///
  /// 1. Valida campos del formulario (validación cliente)
  /// 2. Llama a AuthProvider.login()
  /// 3. Si éxito → navega a HomeScreen
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    await auth.login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    if (auth.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mensaje de error (inline, visible mientras exista)
                if (auth.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      auth.error!,
                      style: TextStyle(color: Colors.red.shade800),
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
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: auth.isLoading
                      ? null
                      : (_) => _handleLogin(),
                  validator: AuthValidators.validatePassword,
                ),
                const SizedBox(height: 24),

                // Botón de envío (deshabilitado mientras carga)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Link a registro
                TextButton(
                  onPressed: auth.isLoading
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                  child: const Text("¿No tenés cuenta? Registrate"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

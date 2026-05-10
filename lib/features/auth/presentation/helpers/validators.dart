// Helpers de validación compartidos entre LoginScreen y RegisterScreen.
//
// Centralizan las reglas de validación de formularios para evitar
// duplicación entre pantallas de autenticación.
//
// TDD: REFACTOR — extraídos durante la limpieza post-implementación

/// Validaciones de formularios de autenticación.
///
/// Todos los métodos retornan `null` si el valor es válido,
/// o un mensaje de error en español si no cumple la regla.
/// Siguen el patrón de [FormFieldValidator] de Flutter.
class AuthValidators {
  /// Valida formato de email.
  ///
  /// Reglas:
  /// - No puede estar vacío
  /// - Debe tener formato usuario@dominio.ext
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    // Regex básico: usuario@dominio.extension
    // No es perfecto pero cubre >99% de los casos reales
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresá un email válido';
    }
    return null;
  }

  /// Valida que la contraseña no esté vacía (para login).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    return null;
  }

  /// Valida contraseña con mínimo de 6 caracteres (para registro).
  static String? validatePasswordMinLength(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Valida que la confirmación de contraseña coincida.
  ///
  /// [value] es el valor del campo de confirmación.
  /// [password] es el valor original de la contraseña.
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirmá tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}

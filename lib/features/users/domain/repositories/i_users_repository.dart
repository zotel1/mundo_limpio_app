import 'package:mundo_limpio_app/features/users/domain/entities/user.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';

/// Interfaz del repositorio de usuarios del dominio.
///
/// Define las operaciones disponibles para la gestión de usuarios:
/// listar, obtener por ID, actualizar roles y resetear contraseña.
abstract class IUsersRepository {
  /// Obtiene la lista completa de usuarios del sistema.
  Future<List<User>> getUsers();

  /// Obtiene un usuario por su [id].
  Future<User> getUser(int id);

  /// Actualiza los roles de un usuario. Envía el set completo como reemplazo.
  Future<User> updateRoles(int userId, Set<UserRole> roles);

  /// Resetea la contraseña de un usuario.
  Future<void> resetPassword(int userId, String newPassword);
}

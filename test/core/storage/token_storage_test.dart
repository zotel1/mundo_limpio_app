// Pruebas unitarias para TokenStorage.
// Verifica que los tokens se persistan correctamente (R1.1),
// que storage vacío retorne null (R1.2), y que los métodos
// clear/hasTokens funcionen.
//
// TDD: RED — test escrito antes que la implementación
//
// NOTA: Este test requiere flutter_secure_storage como dependency
// (añadida en pubspec.yaml tarea 1.5) y mocktail como dev_dependency
// para crear el mock de FlutterSecureStorage.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mundo_limpio_app/core/storage/token_storage.dart';

// Mock de FlutterSecureStorage usando mocktail.
// Se usa en lugar de una instancia real para evitar
// depender del Keychain/Keystore del dispositivo.
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenStorage tokenStorage;

  // Configuración común: se ejecuta antes de cada test
  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorage(storage: mockStorage);

    // Stubs por defecto para métodos que mocktail no puede
    // devolver null (Future<void> no acepta null, Future<bool> no acepta null).
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => mockStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.containsKey(key: any(named: 'key')),
    ).thenAnswer((_) async => false);
  });

  group('saveTokens', () {
    // R1.1: Los tokens deben persistir en flutter_secure_storage
    // cuando se guardan con saveTokens.
    test(
      'should delegate write to FlutterSecureStorage for both tokens',
      () async {
        await tokenStorage.saveTokens('access-123', 'refresh-456');

        // Verifica que se haya llamado a write para access_token
        verify(
          () => mockStorage.write(key: 'access_token', value: 'access-123'),
        ).called(1);

        // Verifica que se haya llamado a write para refresh_token
        verify(
          () => mockStorage.write(key: 'refresh_token', value: 'refresh-456'),
        ).called(1);
      },
    );

    // Triangulación: save + read integrados para verificar
    // que el wrapper persiste y recupera correctamente (R1.1).
    test(
      'should persist tokens that can be read back (save+read round-trip)',
      () async {
        // Configura el mock para que write almacene en un mapa interno
        // y read recupere desde ese mismo mapa.
        final store = <String, String>{};
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((invocation) async {
          store[invocation.namedArguments[#key] as String] =
              invocation.namedArguments[#value] as String;
        });
        when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer(
          (invocation) async =>
              store[invocation.namedArguments[#key] as String],
        );

        await tokenStorage.saveTokens(
          'round-trip-access',
          'round-trip-refresh',
        );
        final result = await tokenStorage.readTokens();

        expect(result, isNotNull);
        expect(result!.access, 'round-trip-access');
        expect(result.refresh, 'round-trip-refresh');
      },
    );
  });

  group('readTokens', () {
    // R1.1: Cuando existen tokens guardados, readTokens debe
    // retornarlos como un record (access, refresh).
    test('should return both tokens when stored (R1.1)', () async {
      // Configura el mock para que devuelva tokens existentes
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'access-123');
      when(
        () => mockStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => 'refresh-456');

      final result = await tokenStorage.readTokens();

      // Verifica que el record contenga ambos valores
      expect(result, isNotNull);
      expect(result!.access, 'access-123');
      expect(result.refresh, 'refresh-456');
    });

    // R1.2: Cuando no hay tokens guardados, readTokens debe
    // retornar null para indicar que no hay sesión activa.
    test('should return null when no tokens stored (R1.2)', () async {
      // Configura el mock para que devuelva null (sin datos)
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => null);

      final result = await tokenStorage.readTokens();

      expect(result, isNull);
    });

    // Edge case: si solo existe access_token pero no refresh_token,
    // debe retornar null porque los datos están incompletos.
    test('should return null when only access token exists', () async {
      when(
        () => mockStorage.read(key: 'access_token'),
      ).thenAnswer((_) async => 'access-123');
      when(
        () => mockStorage.read(key: 'refresh_token'),
      ).thenAnswer((_) async => null);

      final result = await tokenStorage.readTokens();

      expect(result, isNull);
    });
  });

  group('saveRoles / readRoles', () {
    test('should persist and read back a list of roles', () async {
      // Configurar mock con mapa interno
      final store = <String, String>{};
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        store[invocation.namedArguments[#key] as String] =
            invocation.namedArguments[#value] as String;
      });
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer(
        (invocation) async =>
            store[invocation.namedArguments[#key] as String],
      );

      await tokenStorage.saveRoles(['ADMIN', 'STOCK_MANAGER']);
      final result = await tokenStorage.readRoles();

      expect(result, ['ADMIN', 'STOCK_MANAGER']);
    });

    test('should return null when no roles stored', () async {
      final result = await tokenStorage.readRoles();
      expect(result, isNull);
    });

    test('should delegate write to FlutterSecureStorage', () async {
      await tokenStorage.saveRoles(['ADMIN']);

      verify(
        () => mockStorage.write(key: 'roles_list', value: 'ADMIN'),
      ).called(1);
    });
  });

  group('saveUsername / readUsername', () {
    test('should persist and read back username', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      await tokenStorage.saveUsername('testuser');

      verify(
        () => mockStorage.write(key: 'username', value: 'testuser'),
      ).called(1);
      // readUsername retorna lo que mockStorage.read devuelva
      when(() => mockStorage.read(key: 'username'))
          .thenAnswer((_) async => 'testuser');
      final readResult = await tokenStorage.readUsername();
      expect(readResult, 'testuser');
    });
  });

  group('saveEmail / readEmail', () {
    test('should persist and read back email', () async {
      when(() => mockStorage.read(key: 'email'))
          .thenAnswer((_) async => 'user@test.com');

      await tokenStorage.saveEmail('user@test.com');
      final result = await tokenStorage.readEmail();

      verify(
        () => mockStorage.write(key: 'email', value: 'user@test.com'),
      ).called(1);
      expect(result, 'user@test.com');
    });
  });

  group('clear', () {
    // clear debe eliminar ambas claves del storage
    // para garantizar que no queden tokens residuales.
    test('should delete both token keys from storage', () async {
      await tokenStorage.clear();

      verify(() => mockStorage.delete(key: 'access_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
    });
  });

  group('clearAll', () {
    test('should delete all keys including roles, username, email', () async {
      await tokenStorage.clearAll();

      verify(() => mockStorage.delete(key: 'access_token')).called(1);
      verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
      verify(() => mockStorage.delete(key: 'roles_list')).called(1);
      verify(() => mockStorage.delete(key: 'username')).called(1);
      verify(() => mockStorage.delete(key: 'email')).called(1);
    });
  });

  group('hasTokens', () {
    // hasTokens debe retornar true solo cuando AMBOS tokens existen.
    test('should return true when both tokens exist', () async {
      when(
        () => mockStorage.containsKey(key: 'access_token'),
      ).thenAnswer((_) async => true);
      when(
        () => mockStorage.containsKey(key: 'refresh_token'),
      ).thenAnswer((_) async => true);

      final result = await tokenStorage.hasTokens();

      expect(result, isTrue);
    });

    test('should return false when no tokens exist', () async {
      when(
        () => mockStorage.containsKey(key: 'access_token'),
      ).thenAnswer((_) async => false);

      final result = await tokenStorage.hasTokens();

      expect(result, isFalse);
    });

    // Edge case: si solo existe access_token pero no refresh_token,
    // hasTokens debe retornar false (estado inconsistente).
    test('should return false when only access token exists', () async {
      when(
        () => mockStorage.containsKey(key: 'access_token'),
      ).thenAnswer((_) async => true);
      when(
        () => mockStorage.containsKey(key: 'refresh_token'),
      ).thenAnswer((_) async => false);

      final result = await tokenStorage.hasTokens();

      expect(result, isFalse);
    });
  });
}

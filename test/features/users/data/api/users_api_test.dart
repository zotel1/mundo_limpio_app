import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/users/data/api/users_api.dart';
import 'package:mundo_limpio_app/features/users/data/models/user_model.dart';
import 'package:mundo_limpio_app/features/users/domain/entities/user_role.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late UsersApi api;

  setUp(() {
    mockDio = MockDio();
    api = UsersApi(dio: mockDio);
  });

  group('UsersApi', () {
    group('getUsers', () {
      test(
        'debe retornar lista de UserModel en GET /api/v1/users',
        () async {
          // Arrange
          final json = [
            {
              'id': 1,
              'username': 'Usuario123',
              'email': 'user@email.com',
              'roles': ['STOCK_MANAGER'],
              'createdAt': '2026-05-25T12:00:00.000Z',
            },
          ];
          when(() => mockDio.get('/api/v1/users')).thenAnswer(
            (_) async => Response(
              data: json,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/users'),
            ),
          );

          // Act
          final result = await api.getUsers();

          // Assert
          expect(result, isA<List<UserModel>>());
          expect(result, hasLength(1));
          expect(result.first.username, 'Usuario123');
          verify(() => mockDio.get('/api/v1/users')).called(1);
        },
      );

      test('debe lanzar ApiException cuando Dio falla', () async {
        // Arrange
        when(() => mockDio.get('/api/v1/users')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/users'),
            response: Response(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(path: '/api/v1/users'),
            ),
          ),
        );

        // Act & Assert
        expect(
          () async => await api.getUsers(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getUser', () {
      test(
        'debe retornar UserModel en GET /api/v1/users/{id}',
        () async {
          // Arrange
          final json = {
            'id': 1,
            'username': 'Usuario123',
            'email': 'user@email.com',
            'roles': ['ADMIN'],
            'createdAt': '2026-05-25T12:00:00.000Z',
          };
          when(() => mockDio.get('/api/v1/users/1')).thenAnswer(
            (_) async => Response(
              data: json,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/users/1'),
            ),
          );

          // Act
          final result = await api.getUser(1);

          // Assert
          expect(result, isA<UserModel>());
          expect(result.id, 1);
          expect(result.roles, [UserRole.admin]);
          verify(() => mockDio.get('/api/v1/users/1')).called(1);
        },
      );

      test('debe lanzar ApiException cuando Dio falla', () async {
        when(() => mockDio.get('/api/v1/users/999')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/users/999'),
            response: Response(
              data: null,
              statusCode: 404,
              requestOptions: RequestOptions(path: '/api/v1/users/999'),
            ),
          ),
        );

        expect(
          () async => await api.getUser(999),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('updateRoles', () {
      test(
        'debe retornar UserModel en PATCH /api/v1/users/{id}/roles',
        () async {
          // Arrange
          final responseJson = {
            'id': 1,
            'username': 'Usuario123',
            'email': 'user@email.com',
            'roles': ['ADMIN', 'STOCK_MANAGER'],
            'createdAt': '2026-05-25T12:00:00.000Z',
          };
          when(
            () => mockDio.patch(
              '/api/v1/users/1/roles',
              data: any(named: 'data'),
            ),
          ).thenAnswer(
            (_) async => Response(
              data: responseJson,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/users/1/roles'),
            ),
          );

          // Act
          final result = await api.updateRoles(
            1,
            {UserRole.admin, UserRole.stockManager},
          );

          // Assert
          expect(result, isA<UserModel>());
          expect(result.roles, containsAll([UserRole.admin, UserRole.stockManager]));
          verify(
            () => mockDio.patch(
              '/api/v1/users/1/roles',
              data: any(named: 'data'),
            ),
          ).called(1);
        },
      );

      test('debe enviar roles en formato UPPER_SNAKE_CASE', () async {
        // Arrange
        Object? capturedBody;
        when(
          () => mockDio.patch(
            '/api/v1/users/1/roles',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (invocation) async {
            capturedBody = invocation.namedArguments[#data];
            return Response(
              data: {
                'id': 1,
                'username': 'User',
                'email': 'user@email.com',
                'roles': ['ADMIN', 'STOCK_MANAGER'],
                'createdAt': '2026-05-25T12:00:00.000Z',
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/v1/users/1/roles'),
            );
          },
        );

        // Act
        await api.updateRoles(1, {UserRole.admin, UserRole.stockManager});

        // Assert
        final body = capturedBody as Map<String, dynamic>;
        expect(body['roles'], ['ADMIN', 'STOCK_MANAGER']);
      });

      test('debe lanzar ApiException cuando Dio falla', () async {
        when(
          () => mockDio.patch(
            '/api/v1/users/1/roles',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/users/1/roles'),
            response: Response(
              data: null,
              statusCode: 400,
              requestOptions: RequestOptions(path: '/api/v1/users/1/roles'),
            ),
          ),
        );

        expect(
          () async => await api.updateRoles(1, {UserRole.admin}),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('resetPassword', () {
      test(
        'debe hacer PATCH /api/v1/users/{id}/password con newPassword',
        () async {
          // Arrange
          Object? capturedBody;
          when(
            () => mockDio.patch(
              '/api/v1/users/1/password',
              data: any(named: 'data'),
            ),
          ).thenAnswer(
            (invocation) async {
              capturedBody = invocation.namedArguments[#data];
              return Response(
                data: null,
                statusCode: 204,
                requestOptions: RequestOptions(path: '/api/v1/users/1/password'),
              );
            },
          );

          // Act
          await api.resetPassword(1, 'nuevaPass123');

          // Assert
          final body = capturedBody as Map<String, dynamic>;
          expect(body['newPassword'], 'nuevaPass123');
          verify(
            () => mockDio.patch(
              '/api/v1/users/1/password',
              data: any(named: 'data'),
            ),
          ).called(1);
        },
      );

      test('debe lanzar ApiException cuando Dio falla', () async {
        when(
          () => mockDio.patch(
            '/api/v1/users/1/password',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/users/1/password'),
            response: Response(
              data: null,
              statusCode: 403,
              requestOptions: RequestOptions(path: '/api/v1/users/1/password'),
            ),
          ),
        );

        expect(
          () async => await api.resetPassword(1, 'pass'),
          throwsA(isA<ApiException>()),
        );
      });
    });
  });
}

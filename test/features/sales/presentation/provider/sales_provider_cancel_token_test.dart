// Prueba de ciclo de vida de CancelToken en SalesProvider.
//
// Verifica que el provider:
// - Crea o recibe un CancelToken en su inicialización
// - Cancela el CancelToken al hacer dispose()
//
// TDD: RED → GREEN — B4-01

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';
import 'package:mundo_limpio_app/features/sales/presentation/provider/sales_provider.dart';

// Mock del repositorio para aislar el provider
class MockSalesRepository extends Mock implements SalesRepository {}

// Mock del CancelToken para verificar que cancel() es llamado
class MockCancelToken extends Mock implements CancelToken {}

void main() {
  late MockSalesRepository mockRepo;
  late MockCancelToken mockCancelToken;
  late SalesProvider provider;

  setUp(() {
    registerFallbackValue(CancelToken());
    mockRepo = MockSalesRepository();
    mockCancelToken = MockCancelToken();
  });

  group('CancelToken lifecycle', () {
    test('debe crear CancelToken y cancelarlo en dispose (B4-01)', () {
      // Arrange: crear provider con CancelToken mockeado inyectado
      provider = SalesProvider(mockRepo, cancelToken: mockCancelToken);

      // Assert: CancelToken aún no fue cancelado
      verifyNever(() => mockCancelToken.cancel(any()));

      // Act: hacer dispose del provider
      provider.dispose();

      // Assert: CancelToken fue cancelado exactamente una vez
      verify(() => mockCancelToken.cancel(any())).called(1);
    });
  });
}

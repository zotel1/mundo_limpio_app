// Pruebas de integración contra el backend real en Render.
//
// NO usa mocks — llama a los endpoints HTTP reales y usa las
// mismas clases de API que la app en producción.
//
// Advertencia: Estas pruebas requieren conexión a internet y
// que el backend en Render esté activo. El tier gratuito de
// Render tiene cold start de ~30-60s tras inactividad.
//
// Cada test es independiente: hace su propio login cuando
// necesita autenticación.

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:mundo_limpio_app/core/network/api_client.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/auth/data/api/auth_api.dart';
import 'package:mundo_limpio_app/features/auth/data/models/auth_response.dart';
import 'package:mundo_limpio_app/features/inventory/data/api/inventory_api.dart';
import 'package:mundo_limpio_app/features/inventory/data/models/inventory_response.dart';
import 'package:mundo_limpio_app/features/products/data/api/products_api.dart';
import 'package:mundo_limpio_app/features/products/data/models/product_model.dart';
import 'package:mundo_limpio_app/features/sales/data/api/sales_api.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/users/data/api/users_api.dart';
import 'package:mundo_limpio_app/features/users/data/models/user_model.dart';

const _adminEmail = 'zotelsigel@gmail.com';
const _multiRoleEmail = 'zoteldev@gmail.com';
const _password = '123456';

/// Helper: loguea y retorna un [Dio] autenticado + el [AuthResponse].
///
/// Crea un Dio nuevo con el header `Authorization: Bearer <token>`
/// para no contaminar el Dio compartido de requests no autenticadas.
Future<({Dio dio, AuthResponse auth})> _loginAs(
  Dio baseDio,
  String email,
  String password,
) async {
  final authApi = AuthApi(dio: baseDio);
  final auth = await authApi.login(email, password);
  final authDio = ApiClient.create();
  authDio.options.headers['Authorization'] = 'Bearer ${auth.accessToken}';
  return (dio: authDio, auth: auth);
}

String _uniqueSku() => 'TEST-${DateTime.now().millisecondsSinceEpoch}';
String _uniqueEmail() =>
    'test-integration-${DateTime.now().millisecondsSinceEpoch}@test.com';

void main() {
  late Dio dio;

  setUpAll(() {
    dio = ApiClient.create();
  });

  group('Backend Real Integration Tests', () {
    // ═══════════════════════════════════════════════════════════
    // Test 1: Login as admin → ADMIN role
    // ═══════════════════════════════════════════════════════════
    test(
      '1. Login as admin returns ADMIN role',
      () async {
        final authApi = AuthApi(dio: dio);
        final response = await authApi.login(_adminEmail, _password);

        expect(
          response.accessToken,
          isNotEmpty,
          reason: 'Debe retornar accessToken',
        );
        expect(
          response.refreshToken,
          isNotEmpty,
          reason: 'Debe retornar refreshToken',
        );
        expect(
          response.roles,
          contains('ADMIN'),
          reason: 'El admin debe tener rol ADMIN',
        );
        expect(response.username, isNotEmpty, reason: 'Debe retornar username');
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    // ═══════════════════════════════════════════════════════════
    // Test 2: Login as multi-role user → roles esperados
    // ═══════════════════════════════════════════════════════════
    test(
      '2. Login as multi-role user returns correct roles',
      () async {
        final authApi = AuthApi(dio: dio);
        final response = await authApi.login(_multiRoleEmail, _password);

        expect(
          response.accessToken,
          isNotEmpty,
          reason: 'Debe retornar accessToken',
        );
        expect(
          response.refreshToken,
          isNotEmpty,
          reason: 'Debe retornar refreshToken',
        );
        expect(
          response.roles,
          isNotEmpty,
          reason: 'El usuario multi-rol debe tener al menos un rol',
        );
        expect(response.email, _multiRoleEmail);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    // ═══════════════════════════════════════════════════════════
    // Test 3: Crear producto con token de admin → 201 + datos
    // ═══════════════════════════════════════════════════════════
    test(
      '3. Create product (admin token)',
      () async {
        final auth = await _loginAs(dio, _adminEmail, _password);
        final productsApi = ProductsApi(dio: auth.dio);
        final sku = _uniqueSku();

        final product = await productsApi.createProduct({
          'sku': sku,
          'name': 'Test Product $sku',
          'minPrice': 10.50,
          'active': true,
        });

        expect(product.id, greaterThan(0), reason: 'Producto debe tener ID');
        expect(product.sku, sku, reason: 'SKU debe coincidir');
        expect(
          product.name,
          contains('Test Product'),
          reason: 'Nombre debe coincidir',
        );
        expect(product.active, isTrue, reason: 'Producto debe estar activo');
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    // ═══════════════════════════════════════════════════════════
    // Test 4: Listar productos (público, sin auth)
    // ═══════════════════════════════════════════════════════════
    test('4. List products (public)', () async {
      final productsApi = ProductsApi(dio: dio);
      final products = await productsApi.getProducts();

      expect(products, isA<List<ProductModel>>());
      expect(
        products,
        isNotEmpty,
        reason: 'Debe haber al menos un producto en el sistema',
      );
      expect(products.first.id, greaterThan(0));
      expect(products.first.name, isNotEmpty);
    }, timeout: const Timeout(Duration(seconds: 60)));

    // ═══════════════════════════════════════════════════════════
    // Test 5: Obtener usuarios (solo admin)
    // ═══════════════════════════════════════════════════════════
    test('5. Get users (admin only)', () async {
      final auth = await _loginAs(dio, _adminEmail, _password);
      final usersApi = UsersApi(dio: auth.dio);
      final users = await usersApi.getUsers();

      expect(users, isA<List<UserModel>>());
      expect(
        users,
        isNotEmpty,
        reason: 'Debe haber al menos un usuario en el sistema',
      );
      expect(users.first.id, greaterThan(0));
      expect(users.first.email, isNotEmpty);
      expect(users.first.roles, isNotEmpty);
    }, timeout: const Timeout(Duration(seconds: 60)));

    // ═══════════════════════════════════════════════════════════
    // Test 6: CUSTOMER no puede crear productos → 403
    // ═══════════════════════════════════════════════════════════
    test(
      '6. Try create product as CUSTOMER (expect 403)',
      () async {
        // Registrar un usuario nuevo (el rol default es CUSTOMER)
        final authApi = AuthApi(dio: dio);
        final email = _uniqueEmail();
        await authApi.register(email, _password);

        // Login como el nuevo usuario CUSTOMER
        final auth = await _loginAs(dio, email, _password);

        // Verificar que el rol sea CUSTOMER
        expect(
          auth.auth.roles,
          contains('CUSTOMER'),
          reason: 'Usuario recién registrado debe ser CUSTOMER',
        );

        // Intentar crear producto → debe fallar con 403
        final productsApi = ProductsApi(dio: auth.dio);
        final sku = _uniqueSku();

        expect(
          () async => await productsApi.createProduct({
            'sku': sku,
            'name': 'Should Fail $sku',
            'minPrice': 5.0,
            'active': true,
          }),
          throwsA(isA<ApiException>()),
          reason: 'CUSTOMER debe recibir error 403 al crear producto',
        );
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    // ═══════════════════════════════════════════════════════════
    // Test 7: Crear bulk product con admin
    // ═══════════════════════════════════════════════════════════
    test('7. Create bulk product', () async {
      final auth = await _loginAs(dio, _adminEmail, _password);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final response = await auth.dio.post(
        '/api/v1/bulk-products',
        data: {
          'name': 'Test Bulk Product $timestamp',
          'currentStockLiters': 100.0,
          'costPerLiter': 5.50,
          'conversionRatio': 1.0,
          'active': true,
        },
      );

      expect(
        response.statusCode,
        201,
        reason: 'Creación de bulk product debe retornar 201',
      );
      final data = response.data as Map<String, dynamic>;
      expect(data['id'], greaterThan(0), reason: 'Bulk product debe tener ID');
      expect(
        data['name'],
        contains('Test Bulk Product'),
        reason: 'Nombre debe coincidir',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));

    // ═══════════════════════════════════════════════════════════
    // Test 8: Consultar inventario bajo (admin)
    // ═══════════════════════════════════════════════════════════
    test('8. Check inventory low-stock', () async {
      final auth = await _loginAs(dio, _adminEmail, _password);
      final inventoryApi = InventoryApi(dio: auth.dio);
      final lowStock = await inventoryApi.getLowStock();

      expect(
        lowStock,
        isA<List<InventoryResponse>>(),
        reason: 'Debe retornar una lista de InventoryResponse',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));

    // ═══════════════════════════════════════════════════════════
    // Test 9: Crear una venta con admin
    // ═══════════════════════════════════════════════════════════
    test('9. Create sale', () async {
      final auth = await _loginAs(dio, _adminEmail, _password);

      // Obtener un producto existente para la venta
      final productsApi = ProductsApi(dio: auth.dio);
      final products = await productsApi.getProducts();
      expect(
        products,
        isNotEmpty,
        reason: 'Debe haber al menos un producto para crear una venta',
      );

      final productId = products.first.id;

      final salesApi = SalesApi(dio: auth.dio);
      final saleRequest = SaleRequest(productId: productId, quantity: 1.0);

      final sale = await salesApi.createSale(saleRequest);

      expect(sale.id, greaterThan(0), reason: 'Venta debe tener ID');
      expect(
        sale.items,
        isNotEmpty,
        reason: 'Venta debe tener al menos un item',
      );
      expect(
        sale.totalAmount,
        greaterThan(0),
        reason: 'Total de venta debe ser mayor a 0',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}

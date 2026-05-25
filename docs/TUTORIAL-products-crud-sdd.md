# Tutorial: SDD Products CRUD — De principio a fin

## El Problema

El backend tenía **8 endpoints de productos** listos (CRUD completo + reactivar), pero el frontend solo consumía 1 (`GET /api/v1/products` para la pantalla de ventas). Los admins no podían crear, editar, ni gestionar productos desde la app.

Además, el frontend solo reconocía el rol `ADMIN`, pero el backend ya soportaba `STOCK_MANAGER` como segundo rol con permisos de gestión de productos.

## El Enfoque: SDD en 2 PRs Encadenados

Dividimos la implementación en **2 PRs apilados a develop** porque el forecast daba ~1700 líneas (muy por encima del límite de 400 para revisión).

```
PR 1 → develop (Foundation)
PR 2 → develop (UI + Tests)
```

### PR 1: Foundation (domain, data, drift, multi-role)

#### 🏗️ Domain Layer

Siguiendo Clean Architecture, creamos:

```dart
// lib/features/products/domain/entities/product.dart
class Product extends Equatable {
  final int id;
  final String sku;
  final String name;
  final double minPrice;
  final bool active;
  // ...
}
```

**¿Por qué Equatable?** Porque es el patrón de todo el proyecto. Permite comparar entidades por valor (no por referencia) y es necesario para los tests.

```dart
// lib/features/products/domain/repositories/i_products_repository.dart
abstract class IProductsRepository {
  Future<List<Product>> getAll();
  Future<List<Product>> getAllProducts();
  Future<Product> getById(int id);
  Future<Product> getBySku(String sku);
  Future<Product> create(Product product);
  Future<Product> update(int id, Product product);
  Future<void> delete(int id);
  Future<void> reactivate(int id);
}
```

**8 métodos**, uno por cada endpoint del backend. La interfaz permite testear con mocks sin depender de Dio.

#### 📡 Data Layer

- **ProductsApi**: 8 métodos HTTP con `Dio`, cada uno mapea a un endpoint REST. Maneja errores con `ApiException.fromStatusCode()`.
- **ProductModel**: DTO con `@JsonSerializable` + métodos `fromJson`/`toJson` + `toEntity()` para convertir al dominio.
- **ProductsRepositoryImpl**: Implementa `IProductsRepository` llamando a `ProductsApi` y convirtiendo modelos a entidades.

**Decisión de diseño**: Creamos `ProductsApi` nueva (no extendimos `SalesApi`). Aunque ambas trabajan con productos, son responsabilidades distintas — una es CRUD admin, la otra es para ventas. Clean Architecture: separación de concerns.

#### 🗄️ Drift Migration (v1 → v2)

La tabla `ProductCache` existente tenía solo `id` + `name`. Necesitábamos `sku`, `minPrice`, `active`.

```dart
// Migración: agregar columnas nullable
await migrator.addColumn(table, table.sku);
await migrator.addColumn(table, table.minPrice);
await migrator.addColumn(table, table.active);
// UPDATE para filas existentes
await customUpdate('UPDATE product_cache SET active = 1 WHERE active IS NULL');
```

**¿Por qué nullable?** `addColumn` con `NOT NULL` requiere DEFAULT en SQLite, y Drift no lo maneja bien en migraciones. Agregamos nullable y después hacemos UPDATE para poblar los valores por defecto.

#### 🔐 Multi-Role

El frontend solo chequeaba `role == 'ADMIN'` para mostrar botones de admin y proteger rutas. Cambiamos a:

```dart
// GoRouter redirect
final role = authProvider.role;
if (role != 'ADMIN' && role != 'STOCK_MANAGER') {
  return '/unauthorized';
}

// HomeScreen
if (role == 'ADMIN' || role == 'STOCK_MANAGER') {
  // Mostrar botón Productos
}
```

Solo **2 lugares** en todo el código necesitaron cambio — el router redirect y el HomeScreen. Bonus: tests actualizados para verificar ambos roles.

### PR 2: UI + Wiring

#### 🖥️ ProductsProvider

```dart
enum ProductStatus { initial, loading, loaded, error }

class ProductsProvider extends ChangeNotifier {
  ProductStatus _status = ProductStatus.initial;
  List<Product> _products = [];
  Product? _currentProduct;
  String? _errorMessage;

  // 8 métodos CRUD...
}
```

**Status enum**: Mismo patrón que BulkProductProvider. El widget reacciona al estado para mostrar loading, datos, error, o vacío.

#### 📱 3 Pantallas

| Pantalla | Función | Patrón seguido |
|----------|---------|----------------|
| **ProductsListScreen** | Lista con FAB, toggle activos/todos, swipe-to-delete | BulkProductListScreen |
| **ProductsFormScreen** | Create/edit con validación | BulkProductFormScreen |
| **ProductsDetailScreen** | Vista + delete/reactivate | **Nueva** (no existe en BulkProduct) |

**ProductsDetailScreen es nueva** — no existe en BulkProduct. La agregamos porque:
- Permite ver info completa del producto sin entrar en modo edición
- Tiene botones de eliminar y reactivar con confirmación
- Mejor UX que tener todo en la lista

#### ⚡ Wiring

```dart
// main.dart
Provider<ProductsApi>(create: (_) => ProductsApi(dio: ctx.read<Dio>())),
Provider<IProductsRepository>(create: (ctx) => ProductsRepositoryImpl(ctx.read<ProductsApi>())),
ChangeNotifierProvider<ProductsProvider>(create: (ctx) => ProductsProvider(repository: ctx.read<IProductsRepository>())),
```

```dart
// GoRouter
GoRoute(
  path: '/products',
  builder: (_, __) => const ProductsListScreen(),
  routes: [
    GoRoute(path: 'new', builder: (_, __) => const ProductsFormScreen()),
    GoRoute(path: ':id', builder: (_, state) => ProductsDetailScreen(id: int.parse(state.pathParameters['id']!))),
    GoRoute(path: ':id/edit', builder: (_, state) => ProductsFormScreen(productId: int.parse(state.pathParameters['id']!))),
  ],
),
```

## Resultado Final

| Métrica | Antes | Después |
|---------|-------|---------|
| Endpoints productos consumidos | 1/8 | **8/8** ✅ |
| Features funcionales | 7 | **8** |
| Tests totales | 733 | **842** (+109) |
| Roles soportados | ADMIN | **ADMIN + STOCK_MANAGER** |
| Archivos nuevos | — | **17** |
| PRs a develop | — | **2** |

## Key Learnings

1. **SDD en 2 PRs encadenados** funcionó perfecto para mantener el review budget bajo control (~500 y ~1200 líneas respectivamente)

2. **Modelar sobre features existentes** (BulkProduct CRUD) aceleró muchísimo — no inventamos patrones nuevos, solo copiamos los que ya funcionaban

3. **La Drift migration fue el punto más riesgoso** porque toca el schema de la DB local. Siempre testear con datos existentes

4. **El multi-role fue más fácil de lo esperado**: solo 2 lugares necesitaron cambio. La lección: cuando diseñes guards de roles, hacelo extensible desde el principio

5. **El tutorial-output skill** obliga a documentar cada decisión, lo que fuerza a entender ПОЧЕМU (por qué) y no solo КАК (cómo)

---

*SDD products-crud completado el 2026-05-25 en 2 PRs apilados a develop. Próximo SDD recomendado: User Management.*

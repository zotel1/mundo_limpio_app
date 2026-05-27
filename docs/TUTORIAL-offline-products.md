# Tutorial: Offline Products — Read-Through Cache

## 1. El Problema

La pantalla de productos (admin CRUD) no funcionaba sin conexión. Si perdías internet, no veías nada. Sin embargo, el módulo de Ventas ya tenía productos offline gracias a una caché Drift (`product_cache`). El admin CRUD simplemente no la usaba.

## 2. La Solución

Seguir el mismo patrón que `SalesRepositoryImpl`: **read-through cache**.

```
ONLINE:  API → respuesta → cache upsert → devolver datos
OFFLINE: Cache → devolver datos (o error si cache vacía)
WRITES:  API → cache upsert en éxito
```

## 3. Los Cambios

### ProductCacheDao — +2 métodos
```dart
Future<ProductCacheData?> getById(int id) =>
    (select(productCache)..where((t) => t.id.equals(id))).getSingleOrNull();

Future<void> upsert(ProductCacheData product) =>
    into(productCache).insertOnConflictUpdate(product);
```

### ProductsRepositoryImpl — patrón completo

```dart
Future<List<Product>> getProducts() async {
  if (_connectivity.isOnline) {
    final models = await _api.getProducts();
    await _cacheDao.upsertAll(models.map(_toCacheData).toList());
    return models.map((m) => m.toEntity()).toList();
  } else {
    final cached = await _cacheDao.getAll();
    if (cached.isEmpty) {
      throw ApiException(message: 'Sin conexión y sin datos en caché');
    }
    return cached.map(_cacheToEntity).toList();
  }
}
```

## 4. Resultado

- **921 tests** (4 nuevos)
- **0 issues** en flutter analyze
- **5/5 tareas** completadas
- **~150 líneas** de cambio

## 5. Key Learning

El patrón read-through cache ya estaba probado en el módulo de Ventas. Aplicarlo al admin CRUD fue cuestión de copiar el patrón y ajustar los tipos. La infraestructura (Drift, ConnectivityService) ya existía — solo faltaba conectarla.

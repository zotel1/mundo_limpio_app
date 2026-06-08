# Propuesta: sprint-1-correcciones

## Problema

La auditoría del 08/06/2026 reveló 6 issues críticos que afectan estabilidad,
experiencia de usuario y cobertura de tests. Son independientes entre sí pero
comparten prioridad máxima porque producen crashes en producción (1.1, 1.2),
degradación de performance (1.3), problemas de UI en dispositivos con notch (1.4),
pérdida de mensajes de error del backend (1.5), y falta de blindaje en
Backup (1.6).

## Alcance

### In Scope

| # | Tarea | Archivos a modificar/crear | Tipo |
|---|-------|---------------------------|------|
| 1.1 | Fix `getLowStock()` con array vacío | `lib/features/inventory/data/api/inventory_api.dart` (mod) | fix |
| 1.2 | errorBuilder en GoRouter | `lib/core/router/app_router.dart` (mod) | feat |
| 1.3 | InventoryListScreen: map → ListView.builder | `lib/features/inventory/presentation/screens/inventory_list_screen.dart` (mod) | refactor |
| 1.4 | SafeArea en todas las screens | ~21 screens en `lib/features/*/presentation/screens/*.dart` (mod) | fix |
| 1.5 | fromStatusCode → fromDioException en APIs | 9 archivos API/repository (mod) | refactor |
| 1.6 | Tests faltantes de Backup | 5 archivos en `test/features/admin/backup/` (new) | test |

### Out of Scope

- SafeArea en widgets anidados (solo screens top-level)
- Refactor de otras APIs que no usen `fromStatusCode` (scope limitado a las mencionadas)
- Tests de integración para Backup (solo unit/widget tests)

## Enfoque Técnico

### 1.1 Fix getLowStock

Validar tipo de `response.data` antes de castear. Si es `List` vacía, retornar `[]`.
Si es `Map` con key `content`, usar el path actual.

```dart
final raw = response.data;
if (raw is List) return [];  // array vacío
final data = (raw as Map)['content'] as List<dynamic>;
...
```

Además: cambiar el catch a `fromDioException(e)` ya que estamos ahí (relacionado con 1.5).

### 1.2 errorBuilder en GoRouter

Agregar parámetro `errorBuilder` al `GoRouter` en `createRouter()`:
- Si `state.error` es `FormatException` (int.parse falló) → mostrar pantalla amigable
- Si `state.error` es `null` (ruta no encontrada) → mostrar 404
- Botón "Volver al inicio" en ambos casos

### 1.3 ListView.builder

Reemplazar `SingleChildScrollView + Column + items.map()` por `ListView.builder`
con `itemCount` dinámico. Mantener padding y estructura visual intacta.
La optimización es que `_buildProductCard` solo se invoca para items visibles.

### 1.4 SafeArea

Envolver el `body` de cada `Scaffold` con `SafeArea(child: ...)`.
No tocar `appBar` ni `bottomNavigationBar` (SafeArea nativo de Scaffold ya los cubre).
Estrategia: wrapper en el return del `build()` de cada screen, justo antes del `body`.

### 1.5 fromDioException

Reemplazar en todos los catch de `DioException`:
```dart
// ANTES
throw ApiException.fromStatusCode(e.response?.statusCode ?? 0);
// DESPUÉS
throw ApiException.fromDioException(e);
```

Archivos afectados:
- `inventory_api.dart` (3 ocurrencias)
- `sales_api.dart` (5)
- `backup_api.dart` (3)
- `receipts_api.dart` (4)
- `products_api.dart` (8)
- `users_api.dart` (4)
- `users_repository_impl.dart` (4)
- `production_repository_impl.dart` (4)
- `bulk_product_repository_impl.dart` (5)

`AuthApi` ya usa `fromDioException` — es el modelo a seguir.

### 1.6 Tests Backup

Crear tests unitarios y de widget para los 5 archivos sin cobertura:

| Archivo test | Target | Tipo |
|---|---|---|
| `backup_provider_test.dart` | `BackupProvider` (load, create, download, error) | unit |
| `backup_repository_test.dart` | `BackupRepository` (delegación a BackupApi) | unit |
| `backup_api_test.dart` | `BackupApi` (create, get, download, HTTP errors) | unit |
| `backup_detail_screen_test.dart` | `BackupDetailScreen` (loading, data, error, download) | widget |
| `backup_response_test.dart` | `BackupResponse.fromJson` (completed, failed, edge cases) | unit |

## Riesgos

| Riesgo | Prob | Mitigación |
|--------|------|------------|
| SafeArea rompe layout existente en screens sin notch | Baja | Test visual + revisar cada screen |
| `fromDioException` cambia mensajes de error visibles | Media | Tests existentes de error_handler cubren el mapping |
| 1.5 tiene ~40 catch blocks → mucho cambio | Media | Cambio mecánico (sed/regex), fácil de revisar |
| 1.6 excede 400 líneas en tests | Alta | Tests unitarios concisos, separar por archivo |

## Rollback

Cada tarea es independiente. Se puede revertir por archivo con `git revert` o
reset de commits individuales. Ninguna tarea modifica esquemas de DB ni
contratos de API.

## Dependencias

- Ninguna entre tareas. Se pueden implementar en cualquier orden.
- `fromDioException` ya existe en `api_exception.dart` — no requiere cambios previos.

## Criterios de Éxito

- [ ] 1.1: `getLowStock()` con `[]` del backend no lanza `type 'String' is not a subtype of type 'int'`
- [ ] 1.2: Ruta inválida (`/inventory/abc`) muestra pantalla de error amigable, no crash
- [ ] 1.3: `ListView.builder` reemplaza `map()` — verificar que la lista se renderiza igual
- [ ] 1.4: Todas las screens tienen `SafeArea` — contenido no se solapa con notch/isla
- [ ] 1.5: APIs usan `fromDioException` — mensajes del backend se preservan en errores
- [ ] 1.6: 5 archivos de test nuevos, todos pasan
- [ ] `flutter analyze` 0 issues
- [ ] `flutter test` suite completa verde

## Estimación de Líneas

| Tarea | Lib | Test | Total |
|-------|-----|------|-------|
| 1.1 | 10 | 50 | 60 |
| 1.2 | 15 | 60 | 75 |
| 1.3 | 20 | 30 | 50 |
| 1.4 | 42 | 50 | 92 |
| 1.5 | 40 | 80 | 120 |
| 1.6 | 0 | 400 | 400 |
| **Total** | **127** | **670** | **797** |

> **⚠ 797 líneas estimadas → supera el budget de 400.**
> Se recomienda dividir en PRs encadenados: 1.1+1.2+1.3 (185 líneas), luego 1.4+1.5 (212 líneas), luego 1.6 (400 líneas en 5 archivos separados).

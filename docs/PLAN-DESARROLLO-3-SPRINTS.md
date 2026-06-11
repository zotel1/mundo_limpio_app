# Plan de Desarrollo — 3 Sprints Post-Auditoría

> **Basado en:** Auditoría completa 08/06/2026
> **Proyecto:** mundo_limpio_app (Flutter 3.44 / Dart 3.12)
> **Stack:** Provider, Dio, GoRouter, Drift, Firebase, flutter_secure_storage
> **Score Global:** 78/100

---

## Sprint 1 — Prioridad Máxima 🚨

**Duración estimada:** 1-2 días  
**Objetivo:** Bugs críticos, errores de runtime, y deuda técnica que afecta experiencia de usuario

| # | Tarea | Área | Esfuerzo | Skills necesarias | Dependencias |
|---|-------|------|----------|-------------------|--------------|
| 1.1 | Fix bug `inventory_api.dart:56` — `getLowStock()` falla con array vacío | Data Layer | ⏱️ 30min | `dart-fix-runtime-errors`, `flutter-use-http-package` | Ninguna |
| 1.2 | Agregar `errorBuilder` al GoRouter para manejo de 404 + errores de ruta | Routing | ⏱️ 15min | `flutter-setup-declarative-routing` | Ninguna |
| 1.3 | Convertir `InventoryListScreen` de `map + Column` a `ListView.builder` | UI/Performance | ⏱️ 20min | `flutter-fix-layout-issues` | Ninguna |
| 1.4 | Agregar `SafeArea` en todas las screens | UI/Responsive | ⏱️ 30min | `flutter-fix-layout-issues`, `flutter-build-responsive-layout` | Ninguna |
| 1.5 | Unificar parseo de errores HTTP — todas las APIs usan `fromDioException` | Data Layer | ⏱️ 1h | `flutter-use-http-package`, `dart-add-unit-test` | Ninguna |
| 1.6 | Agregar tests faltantes de Backup (5 archivos: provider, repository, api, detail_screen, response) | Tests | ⏱️ 2h | `dart-add-unit-test`, `flutter-add-widget-test`, `dart-generate-test-mocks` | Ninguna |

**Criterios de éxito Sprint 1:**
- ✅ Bug de `inventory_api.dart` corregido con test que prueba array vacío
- ✅ `flutter analyze` sigue en 0 issues
- ✅ `flutter test` pasa con 100% (los 3 tests rotos de backend_real pueden quedar si son de datos)
- ✅ SafeArea visible en todas las screens
- ✅ Todos los tests de Backup nuevos pasan

---

## Sprint 2 — Prioridad Alta 🟡

**Duración estimada:** 3-5 días  
**Objetivo:** Arquitectura, desacoplamiento de capas, y calidad del data layer

| # | Tarea | Área | Esfuerzo | Skills necesarias | Dependencias |
|---|-------|------|----------|-------------------|--------------|
| 2.1 | Crear entidades de dominio para Auth (`AuthSession`), Sales (`Sale`, `SaleItem`), Inventory (`StockItem`, `Adjustment`), Receipts (`Receipt`, `Purchase`) | Arquitectura | ⏱️ 4h | `flutter-apply-architecture-best-practices`, `dart-add-unit-test` | Ninguna |
| 2.2 | Desacoplar domain/ de data/models/ en las 4 features | Arquitectura | ⏱️ 3h | `flutter-apply-architecture-best-practices` | 2.1 |
| 2.3 | Agregar capa domain/ a Backup feature (repositorio abstracto + entidad) | Arquitectura | ⏱️ 1h | `flutter-apply-architecture-best-practices`, `dart-add-unit-test` | Ninguna |
| 2.4 | Implementar retry con backoff en SyncService (usar `retryCount` existente) | Data Layer | ⏱️ 2h | `flutter-use-http-package`, `dart-add-unit-test` | Ninguna |
| 2.5 | Agregar índices en Drift para `draft_sales(status)` y `batch_cache(product_id)` | Data Layer | ⏱️ 30min | — | Ninguna |
| 2.6 | Generar `firebase_options.dart` con `flutterfire configure` | Firebase | ⏱️ 15min | — | Ninguna |
| 2.7 | Refactorizar `AuthProvider` — mover persistencia de metadata al repositorio | Arquitectura | ⏱️ 2h | `flutter-apply-architecture-best-practices`, `dart-add-unit-test`, `flutter-add-widget-test` | Ninguna |
| 2.8 | Extraer validación inline de `CreateSaleScreen` y `ProductsFormScreen` a helpers | UI/Calidad | ⏱️ 1h | `dart-add-unit-test` | Ninguna |
| 2.9 | Extender `AppTheme` con subtemas faltantes: `InputDecorationTheme`, `CardTheme`, `NavigationBarTheme`, `TextButtonTheme`, `DividerTheme` | UI/Theme | ⏱️ 1h | `flutter-apply-architecture-best-practices` | Ninguna |

**Criterios de éxito Sprint 2:**
- ✅ Domain/ ya no importa `data/models/` en NINGUNA feature
- ✅ Backup tiene capa domain/ completa con tests
- ✅ `flutter analyze` en 0 issues
- ✅ SyncService con límite de 3 reintentos y backoff exponencial (1s, 2s, 4s)
- ✅ Tests unitarios de SyncService con retry
- ✅ `firebase_options.dart` generado y funcionando

---

## Sprint 3 — Prioridad Media 🟢

**Duración estimada:** 5-7 días  
**Objetivo:** UI consistente, performance, actualización de dependencias, y maduración general

| # | Tarea | Área | Esfuerzo | Skills necesarias | Dependencias |
|---|-------|------|----------|-------------------|--------------|
| 3.1 | Migrar toda la navegación a GoRouter-only (eliminar `Navigator.push/pop`) | Routing | ⏱️ 3h | `flutter-setup-declarative-routing`, `flutter-add-widget-test` | Ninguna |
| 3.2 | Reemplazar colores hardcodeados por `Theme.of(context)` en todas las screens | UI/Theme | ⏱️ 2h | `flutter-apply-architecture-best-practices` | 2.9 |
| 3.3 | Actualizar 42 packages desactualizados — migraciones c/ breaking changes | Dependencias | ⏱️ 4h | `dart-resolve-package-conflicts`, `dart-run-static-analysis`, `dart-add-unit-test` | Ninguna |
| 3.4 | Agregar shimmer/skeleton loading para listas (Products, Sales, Inventory) | UI/UX | ⏱️ 2h | `flutter-add-widget-test` | Ninguna |
| 3.5 | Crear `EmptyStateWidget` + `ErrorViewWidget` genéricos y migrar screens | UI/UX | ⏱️ 1h | `flutter-add-widget-test` | Ninguna |
| 3.6 | Agregar `LayoutBuilder` / responsive en `HomeScreen` y screens de listas | UI/Responsive | ⏱️ 3h | `flutter-build-responsive-layout`, `flutter-add-widget-test` | Ninguna |
| 3.7 | Unificar `quantity` (int vs double) según backend — verificar con API | Modelos | ⏱️ 1h | `flutter-implement-json-serialization`, `dart-add-unit-test` | Ninguna |
| 3.8 | Tests de serialización para todos los modelos faltantes (~15 archivos) | Tests | ⏱️ 2h | `dart-add-unit-test`, `flutter-implement-json-serialization` | Ninguna |
| 3.9 | Migrar `pumpUntilSettled` a `pumpAndSettle` con timeout en todos los widget tests | Tests | ⏱️ 30min | `flutter-add-widget-test` | Ninguna |
| 3.10 | Extraer providers de `main.dart` a módulos/archivos separados | Arquitectura | ⏱️ 2h | `flutter-apply-architecture-best-practices` | Ninguna |
| 3.11 | Refactorizar `AuthResponse.fromJson` — eliminar spread de Map | Modelos | ⏱️ 30min | `flutter-implement-json-serialization`, `dart-add-unit-test` | Ninguna |
| 3.12 | Agregar `FocusScope` + dismiss de teclado + `autofocus` en formularios | UI/UX | ⏱️ 30min | `flutter-fix-layout-issues` | Ninguna |

**Criterios de éxito Sprint 3:**
- ✅ Navegación 100% GoRouter
- ✅ 0 colores hardcodeados — todo vía `Theme.of(context)`
- ✅ Packages actualizados, tests verdes
- ✅ Shimmer visible en listas durante carga
- ✅ Screens adaptativas en tablets/landscape
- ✅ `flutter analyze` en 0 issues
- ✅ `flutter test` 100% verde

---

## Tabla de Dependencias Entre Sprints

```
Sprint 1                     Sprint 2                          Sprint 3
─────────                    ─────────                         ─────────
1.1 Fix bug API              (independiente)                   ─
1.2 errorBuilder             (independiente)                   ─
1.3 ListView.builder         (independiente)                   ─
1.4 SafeArea                 (independiente)                   ─
1.5 Parseo unificado         2.1 Entidades dominio ← ayuda     3.2 Colores hardcodeados
1.6 Backup tests             (independiente)                   ─
                             ─                                 ─
                             2.1 Entidades dominio             (base para 3.7, 3.11)
                             2.2 Desacoplar domain/data        3.1 GoRouter-only (si queda mezcla)
                             2.3 Backup domain                 ─
                             2.4 Retry backoff                 ─
                             2.5 Índices Drift                 ─
                             2.6 firebase_options              ─
                             2.7 AuthProvider                  ─
                             2.8 Validación helpers            3.12 FocusScope/autofocus
                             2.9 AppTheme completo             3.2 Colores hardcodeados (post-2.9)
                                                               ─
                                                               ─
                                                               3.1 GoRouter-only
                                                               3.2 Colores hardcodeados
                                                               3.3 Packages outdated
                                                               3.4 Shimmer
                                                               3.5 EmptyStateWidget
                                                               3.6 Responsive
                                                               3.7 Unificar quantity
                                                               3.8 Tests serialización
                                                               3.9 pumpUntilSettled fix
                                                               3.10 main.dart refactor
                                                               3.11 AuthResponse.fix
                                                               3.12 FocusScope
```

---

## Skills por Sprint

### Sprint 1 — Skills involucradas
| Skill | Tareas |
|-------|--------|
| `dart-fix-runtime-errors` | 1.1 |
| `flutter-use-http-package` | 1.1, 1.5 |
| `flutter-setup-declarative-routing` | 1.2 |
| `flutter-fix-layout-issues` | 1.3, 1.4 |
| `flutter-build-responsive-layout` | 1.4 |
| `dart-add-unit-test` | 1.5, 1.6 |
| `flutter-add-widget-test` | 1.6 |
| `dart-generate-test-mocks` | 1.6 |

### Sprint 2 — Skills involucradas
| Skill | Tareas |
|-------|--------|
| `flutter-apply-architecture-best-practices` | 2.1, 2.2, 2.3, 2.7, 2.9 |
| `dart-add-unit-test` | 2.1, 2.3, 2.4, 2.7, 2.8 |
| `flutter-use-http-package` | 2.4 |
| `dart-run-static-analysis` | 2.4, 2.7 |
| `flutter-add-widget-test` | 2.7 |

### Sprint 3 — Skills involucradas
| Skill | Tareas |
|-------|--------|
| `flutter-setup-declarative-routing` | 3.1 |
| `flutter-apply-architecture-best-practices` | 3.2, 3.10 |
| `dart-resolve-package-conflicts` | 3.3 |
| `dart-run-static-analysis` | 3.3 |
| `dart-add-unit-test` | 3.3, 3.8 |
| `flutter-add-widget-test` | 3.4, 3.5, 3.6, 3.9 |
| `flutter-build-responsive-layout` | 3.6 |
| `flutter-implement-json-serialization` | 3.7, 3.8, 3.11 |
| `flutter-fix-layout-issues` | 3.12 |

---

## Veredicto General Post-Sprint 3

| Dimensión | Antes | Después Esperado |
|-----------|-------|------------------|
| Clean Architecture | 7/10 | 9/10 |
| Calidad de código | 10/10 | 10/10 |
| Tests | 9/10 | 10/10 |
| Data Layer | 7/10 | 9/10 |
| UI/UX | 6/10 | 9/10 |
| Modelos/Serialización | 7/10 | 9/10 |
| Seguridad | 8/10 | 9/10 |
| Performance | 7/10 | 9/10 |
| Mantenibilidad | 8/10 | 9/10 |
| DevOps/WF | 9/10 | 9/10 |
| **Score Global** | **78/100** | **92/100** |

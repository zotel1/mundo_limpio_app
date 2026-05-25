# Roadmap: Frontend → Backend Integration

> Mapa completo de la API del backend vs consumo del frontend, con SDDs priorizados para cerrar la brecha.

---

## Estado Actual

**Frontend**: 19 endpoints consumidos, 7 features funcionales, todos los providers cableados en `main.dart`.

**Backend**: 31 endpoints, 12 tablas PostgreSQL, 8 controladores, 6 roles JWT.

**Brecha**: 12 endpoints del backend **no tienen frontend**. Algunos son features enteras (Users, Products CRUD, Sales History, Purchases History, Audit Log).

---

## Backend API — Mapa Completo

### Auth (3/3 endpoints consumidos ✅)

| Endpoint | Método | Frontend | Roles |
|----------|--------|----------|-------|
| `/api/v1/auth/register` | POST | ✅ Login/Register | Público |
| `/api/v1/auth/login` | POST | ✅ Login/Register | Público |
| `/api/v1/auth/refresh` | POST | ✅ AuthInterceptor | Público |

### Products (8 endpoints, 1/8 consumidos ⚠️)

| Endpoint | Método | Frontend | Roles |
|----------|--------|----------|-------|
| `GET /api/v1/products` | GET | ✅ (Sales screen) | Público |
| `GET /api/v1/products/all` | GET | ❌ | Público |
| `GET /api/v1/products/{id}` | GET | ❌ | Público |
| `GET /api/v1/products/sku/{sku}` | GET | ❌ | Público |
| `POST /api/v1/products` | POST | ❌ | ADMIN, STOCK_MANAGER |
| `PUT /api/v1/products/{id}` | PUT | ❌ | ADMIN, STOCK_MANAGER |
| `DELETE /api/v1/products/{id}` | DELETE | ❌ | ADMIN, STOCK_MANAGER |
| `PATCH /api/v1/products/{id}/reactivate` | PATCH | ❌ | ADMIN, STOCK_MANAGER |

### Bulk Products (7 endpoints, 7/7 consumidos ✅)

Completamente cubiertos por el frontend (CRUD completo en pantallas de producción).

### Production Batches (3 endpoints, 3/3 consumidos ✅)

Completamente cubiertos.

### Inventory (3 endpoints, 3/3 consumidos ✅)

Completamente cubiertos.

### Sales (1 endpoint, 1/1 consumido ✅, pero...)

| Endpoint | Método | Frontend | Nota |
|----------|--------|----------|------|
| `POST /api/v1/sales` | POST | ✅ | Creación funcional |
| `GET /api/v1/sales` | GET | ❌ | No existe endpoint ni frontend |
| `GET /api/v1/sales/{id}` | GET | ❌ | No existe endpoint ni frontend |

### Users (4 endpoints, 0/4 consumidos ❌)

| Endpoint | Método | Frontend | Roles |
|----------|--------|----------|-------|
| `GET /api/v1/users` | GET | ❌ | ADMIN |
| `GET /api/v1/users/{id}` | GET | ❌ | ADMIN |
| `PATCH /api/v1/users/{id}/roles` | PATCH | ❌ | ADMIN |
| `PATCH /api/v1/users/{id}/password` | PATCH | ❌ | ADMIN |

### Receipts/Purchases (2 endpoints, 2/2 consumidos ✅)

| Endpoint | Método | Frontend | Nota |
|----------|--------|----------|------|
| `POST /api/v1/receipts/process` | POST | ✅ | OCR funcional |
| `POST /api/v1/receipts/confirm` | POST | ✅ | Confirmación funcional |
| `GET /api/v1/purchases` | GET | ❌ | **No existe endpoint ni frontend** |

### Health (1/1 consumido ✅)

| Endpoint | Frontend |
|----------|----------|
| `GET /actuator/health` | ✅ Splash |

---

## Roadmap de Desarrollo (SDDs Priorizados)

Orden recomendado por **dependencia + valor de negocio**:

### 🥇 SDD 1: Products CRUD (Admin)

**Valor**: Alto — los admins necesitan crear/editar productos sin tocar la DB.

**Backend**: ✅ Todos los endpoints existen
**Frontend a crear**:
- `lib/features/products/` — domain/data/presentation
- ProductListScreen (admin) con search por SKU
- ProductFormScreen (create/edit)
- ProductDetailScreen
- Delete/reactivate con confirmación
- Provider + Repository + API

**Endpoints**: 8 (GET list, GET all, GET by id, GET by SKU, POST, PUT, DELETE, PATCH reactivate)

**Esfuerzo estimado**: Medio (3-4 fases SDD)
**Dependencias**: Ninguna

---

### 🥇 SDD 2: User Management (Admin)

**Valor**: Alto — los admins necesitan asignar roles a usuarios nuevos.

**Backend**: ✅ Todos los endpoints existen
**Frontend a crear**:
- `lib/features/users/` — domain/data/presentation
- UserListScreen con tabla de usuarios
- UserDetailScreen con roles y reset de password
- RolePicker widget (multi-select de roles con validación ADMIN_EXCLUSIVE)

**Endpoints**: 4 (GET list, GET by id, PATCH roles, PATCH password)

**Esfuerzo estimado**: Medio (3 fases SDD)
**Dependencias**: SDD 1 (mismo patrón de admin CRUD)

---

### 🥈 SDD 3: Sales History

**Valor**: Medio — los vendedores necesitan ver ventas pasadas.

**Backend**: ⚠️ **No existe endpoint GET /api/v1/sales**. Hay que crearlo en el backend primero.
**Frontend a crear**:
- SalesHistoryScreen
- SaleDetailScreen

**Extras**: Backend necesita nuevo endpoint + posiblemente DTOs.

**Esfuerzo**: Medio-alto (toca backend + frontend)
**Dependencias**: SDD 1-2 (patrón de listado)

---

### 🥈 SDD 4: Purchase History

**Valor**: Medio — los admins necesitan ver compras pasadas.

**Backend**: ⚠️ **No existe endpoint GET /api/v1/purchases**. Hay que crearlo.
**Frontend a crear**:
- PurchaseHistoryScreen
- PurchaseDetailScreen

**Extras**: Backend necesita nuevo endpoint.

**Esfuerzo**: Medio (backend + frontend)
**Dependencias**: SDD 1-2

---

### 🥉 SDD 5: Production Improvements

**Valor**: Medio — mejora calidad del código existente.

**Backend**: ✅ Sin cambios necesarios
**Frontend a mejorar**:
- Arreglar `production_repository_impl.dart` y `bulk_product_repository_impl.dart` para que lancen `ApiException` en vez de `Exception` genérica
- Agregar offline support (Drift cache + pending queue) a producción
- Refactorizar `ProductionProvider` para inyectar usecases en vez de crearlos internamente
- Eliminar usecases muertos (`GetBulkProducts`, `CreateBulkProduct`) si no se usan

**Esfuerzo**: Bajo-medio (solo frontend, solo refactor)
**Dependencias**: Ninguna (se puede hacer en cualquier momento)

---

### 🥉 SDD 6: Audit Log

**Valor**: Bajo — compliance, pero no crítico para operación diaria.

**Backend**: ⚠️ **No existe endpoint**. Tabla `audit_log` en DB pero sin REST.
**Frontend a crear**:
- AuditLogScreen (solo lectura, filtros por entidad/fecha)

**Esfuerzo**: Medio (backend + frontend)
**Dependencias**: Baja prioridad

---

## Resumen del Roadmap

| # | SDD | Frontend | Backend | Esfuerzo | Prioridad |
|---|-----|----------|---------|----------|-----------|
| 1 | Products CRUD | Nuevo feature | ✅ Existe | Medio | 🔴 Alta |
| 2 | User Management | Nuevo feature | ✅ Existe | Medio | 🔴 Alta |
| 3 | Sales History | Nuevo feature | ❌ Crear endpoint | Medio-Alto | 🟡 Media |
| 4 | Purchase History | Nuevo feature | ❌ Crear endpoint | Medio | 🟡 Media |
| 5 | Production Fixes | Refactor | ✅ Sin cambios | Bajo | 🟢 Baja |
| 6 | Audit Log | Nuevo feature | ❌ Crear endpoint | Medio | 🟢 Baja |

---

## Issues de Calidad Detectados

1. **Production repos lanzan `Exception` genérica** en vez de `ApiException` → los providers nunca muestran mensajes descriptivos
2. **Sin offline support en producción** — a diferencia de Sales e Inventory que tienen Drift cache + cola de pendientes
3. **ProductionProvider crea `ExecuteProduction` internamente** — no se inyecta, tight coupling
4. **Usecases muertos** — `GetBulkProducts` y `CreateBulkProduct` existen en domain pero no se usan
5. **Sin paginación en ningún endpoint** — `GET /products/all` sin límite puede escalar mal
6. **Register devuelve rol vacío** — el frontend debe manejar el estado "logueado sin permisos"

---

*Generado el 2026-05-25 a partir de exploración del frontend (mundo_limpio_app) y backend (mundo-limpio-backend).*

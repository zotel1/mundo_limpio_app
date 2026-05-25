# Tutorial: Cómo analizar la brecha Frontend vs Backend

## El Problema

Tenemos un frontend Flutter y un backend Spring Boot. El frontend consume algunas APIs del backend, pero **no sabemos exactamente qué está cubierto y qué falta**. Queremos un plan de desarrollo ordenado para que el frontend termine consumiendo todo el backend.

## El Enfoque

En vez de ir feature por feature adivinando, usamos el **SDD Explore** en paralelo:

### Paso 1: Explorar el Frontend

Delegamos un sub-agente `sdd-explore` para que investigue el frontend:

```bash
# El agente leyó:
- lib/core/services/api_client.dart     → Configuración de Dio
- lib/core/services/auth_interceptor.dart → Auth JWT + refresh
- Cada feature (auth/sales/inventory/...) → APIs, repos, providers
- main.dart → Qué providers están cableados
- Archivos de test → Qué features están testeadas
```

**¿Qué buscaba?**
- ¿Qué endpoints consume el frontend HOY?
- ¿Qué features están cableadas en main.dart?
- ¿Qué features tienen tests?
- ¿Hay providers sin cablear?

### Paso 2: Explorar el Backend

En paralelo, otro sub-agente exploró el backend completo:

```bash
# El agente leyó:
- src/main/resources/db/migration/*.sql     → 9 migrations, 12 tablas
- src/main/java/.../controller/*.java        → 8 controladores, 31 endpoints
- src/main/java/.../service/*.java           → Todos los servicios
- src/main/java/.../repository/*.java        → Todos los repositorios
- src/main/java/.../domain/*.java            → Todas las entidades
- src/main/java/.../dto/*.java               → Todos los DTOs
- src/main/java/.../security/*.java          → JWT + roles
- application.yml                            → Configuración
```

**¿Qué buscaba?**
- Todas las tablas y relaciones (Flyway migrations)
- Todos los endpoints con método, path, auth, request/response
- El modelo de seguridad (roles, permisos)
- Configuración de CORS, base path, etc.

### Paso 3: Cruzar los Datos

Con ambas exploraciones completas, cruzamos:

```
FRONTEND: 19 endpoints consumidos
BACKEND:  31 endpoints disponibles
BRECHA:   12 endpoints sin frontend
```

Agrupamos los endpoints faltantes por **feature lógica** (Products, Users, Sales History, etc.) y los priorizamos por **valor de negocio + dependencias**.

## El Resultado

### 3 Categorías de Features

| Categoría | Features | Acción |
|-----------|----------|--------|
| ✅ **Completas** | Auth, Bulk Products, Production Batches, Inventory, Receipts (OCR) | No tocar |
| ⚠️ **Parciales** | Sales (solo crear, sin historial), Products (solo lectura pública) | Extender |
| ❌ **Faltantes** | Users CRUD, Products CRUD admin, Sales History, Purchase History, Audit Log | Crear desde cero |

### Priorización

Usamos una matriz simple:

```
Prioridad = Valor de Negocio × Dependencias × Esfuerzo
```

- **Alta**: Products CRUD + User Management → los admins los necesitan YA, los endpoints existen en backend
- **Media**: Sales History + Purchase History → útiles pero requieren crear endpoints nuevos en backend
- **Baja**: Production Fixes + Audit Log → mejora calidad o compliance pero no bloquea operación

## ¿Por qué funciona este enfoque?

1. **Paralelización**: Las dos exploraciones son independientes → se ejecutan al mismo tiempo
2. **Sin adivinanzas**: No especulamos sobre lo que hace el backend — leemos el código real
3. **Visibilidad total**: Sabemos exactamente qué endpoints consumimos, cuáles no, y cuáles faltan en ambos lados
4. **Roadmap objetiv**: Cada SDD del roadmap tiene una justificación clara, no es "porque sí"

## Lección

> Cuando tenés dos sistemas que deben integrarse (frontend + backend), nunca asumas nada. Explorá ambos lados en paralelo, cruzás los datos, y después priorizás. No hay atajo que reemplace leer el código real.

---

*Este tutorial documenta el proceso de análisis frontend-backend realizado el 2026-05-25.*

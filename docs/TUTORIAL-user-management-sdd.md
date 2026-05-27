# Tutorial: User Management — SDD Completo

## 1. El Problema

La app MundoLimpio tenía productos, inventario, ventas, producción... pero **no había forma de gestionar usuarios**. Cualquiera podía registrarse con email y contraseña, pero después quedaba sin roles y no había interfaz para que un ADMIN los asignara.

Además, las **release builds en Android no tenían conexión a internet** porque faltaba el permiso `INTERNET` en el manifest principal.

### Síntomas
- Usuarios se registraban pero no podían hacer nada
- ADMIN no tenía pantalla para ver quiénes eran los usuarios
- Release APK instalada en el celular: sin conexión al backend

---

## 2. La Investigación

### Backend primero
Mandamos un agente a explorar el backend (`mundo-limpio-backend`) y descubrimos que **ya tenía todos los endpoints necesarios**:

```
GET    /api/v1/users          → listar usuarios (ADMIN)
GET    /api/v1/users/{id}     → ver detalle (ADMIN)
PATCH  /api/v1/users/{id}/roles  → cambiar roles (ADMIN)
PATCH  /api/v1/users/{id}/password → reset pass (ADMIN)
```

El backend ya soportaba multi-rol (un usuario con varios roles), reglas de exclusividad ADMIN, y auditoría de cambios.

### Frontend: el problema de red
Después investigamos por qué la app no conectaba desde el celular. Resultado:

| Manifest | ¿Tiene INTERNET? |
|----------|-----------------|
| `android/app/src/debug/AndroidManifest.xml` | ✅ Sí |
| `android/app/src/profile/AndroidManifest.xml` | ✅ Sí |
| **`android/app/src/main/AndroidManifest.xml`** | **❌ No** |

El manifest de release no tenía el permiso. Android 9+ bloquea toda conexión TCP sin él.

---

## 3. Alternativas Consideradas

### Para la conexión de red
| Alternativa | Pros | Contras | Decisión |
|-------------|------|---------|----------|
| Agregar INTERNET permission | Una línea, arregla el problema de raíz | Ninguna | ✅ **Elegida** |
| Usar `network_security_config.xml` | Permite HTTP además de HTTPS | No soluciona el permiso faltante | ❌ No ataca la causa raíz |
| Forzar debug mode siempre | Funciona en debug | Inviable para release | ❌ |

### Para la arquitectura del feature
| Alternativa | Pros | Contras | Decisión |
|-------------|------|---------|----------|
| Clean Architecture (domain/data/presentation) | Consistente con el resto del proyecto, testeable | Más archivos | ✅ **Elegida** |
| Todo en un solo archivo | Rápido de escribir | No testeable, rompe la arquitectura | ❌ |
| Usar el modelo directamente sin entity | Menos código | Rompe el aislamiento de capas | ❌ |

### Para la entrega (PRs)
| Alternativa | Pros | Contras | Decisión |
|-------------|------|---------|----------|
| **Stacked PRs a develop** | 3 PRs pequeños, fáciles de revisar, cada uno independiente | Más PRs | ✅ **Elegida** |
| Feature branch chain | Control de rollback total | Más ramas, más rebases | ❌ |
| Single PR (size exception) | Un solo merge | ~900 líneas de review | ❌ |

---

## 4. La Solución

### Estructura del feature

```
lib/features/users/
├── domain/
│   ├── entities/
│   │   ├── user.dart              # User entity (Equatable)
│   │   └── user_role.dart         # Enum: ADMIN, STOCK_MANAGER, etc.
│   └── repositories/
│       └── i_users_repository.dart # Contrato abstracto
├── data/
│   ├── api/
│   │   └── users_api.dart         # 4 endpoints con Dio
│   ├── models/
│   │   └── user_model.dart        # DTO json_serializable
│   └── repositories/
│       └── users_repository_impl.dart  # Implementación
└── presentation/
    ├── providers/
    │   └── users_provider.dart     # ChangeNotifier con 6 estados
    └── screens/
        ├── users_list_screen.dart  # Lista con RefreshIndicator
        └── user_detail_screen.dart # Detalle + roles + pass
```

### Flujo de datos

```
UsersListScreen ← watch → UsersProvider ← call → IUsersRepository
                              ↓
                       UsersRepositoryImpl
                              ↓
                         UsersApi (Dio)
                              ↓
                    PATCH /api/v1/users/{id}/roles
                              ↓
                    Backend en Render (ya existía)
```

### Reglas de negocio implementadas

1. **Multi-rol**: se envía el Set completo vía PATCH (reemplazo, no add/remove)
2. **ADMIN exclusivo**: si se selecciona ADMIN, los demás roles se deshabilitan
3. **Auto-ADMIN protegido**: un ADMIN no puede sacarse su propio rol ADMIN
4. **Confirmación obligatoria**: antes de guardar roles o resetear pass, diálogo de confirmación

### El fix del INTERNET permission

```xml
<!-- Antes: -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Después: -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

**Importante**: El manifest de debug SÍ tenía el permiso, por eso funcionaba con `flutter run` pero no con APK release.

---

## 5. Estrategia de PRs

Usamos **Stacked PRs a develop** (3 PRs):

```
PR #1 — Foundation + Domain + Data
  feat/user-management → develop ✅
  └── fix: add INTERNET permission
  └── feat(users): domain layer
  └── feat(users): data layer + tests

PR #2 — Presentation
  feat/um-presentation → develop ✅
  └── feat(users): UsersProvider + tests
  └── feat(users): UsersListScreen + tests
  └── feat(users): UserDetailScreen + tests
  └── fix: use_build_context_synchronously lint

PR #3 — Wiring + Tests
  feat/um-wiring-tests → develop ✅
  └── feat(users): /users route + home button
  └── test(users): router + manifest tests
```

---

## 6. Resultado Final

| Métrica | Antes | Después |
|---------|-------|---------|
| Tests totales | 845 | **911** (+66) |
| Análisis estático | 0 issues | 0 issues |
| Permiso INTERNET | ❌ Faltante | ✅ Agregado |
| User Management UI | ❌ No existía | ✅ Lista + detalle + roles + pass |
| PRs merged | 46 | **49** (+3) |

### Acceptance criteria: 13/13 ✅

---

## 7. Key Learnings

### Lo que aprendimos

1. **Siempre verificar el AndroidManifest de release** — el de debug tiene más permisos y puede enmascarar problemas
2. **`dart format` antes de commitear** — Windows y Linux a veces formatean distinto. Correrlo antes evita CI failures
3. **Capturar referencias antes del async gap** — `ScaffoldMessenger.of(context)` y `context.read<Provider>()` capturados antes del `await` evitan lints de `use_build_context_synchronously`
4. **La arquitectura paga dividendos** — seguir el patrón de products-crud hizo que todo fuera predecible y rápido de implementar
5. **Stacked PRs funciona bien** cuando los cambios son independientes por capa (datos → UI → wiring)

### Para la próxima

- Agregar paginación a `GET /api/v1/users` cuando haya muchos usuarios
- Considerar self-service password change (que el usuario cambie su propia pass)
- El rol `ACCOUNTANT` existe en backend pero no tiene endpoints asignados — pendiente para futuro

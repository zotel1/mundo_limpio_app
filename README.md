# MundoLimpio App 🧹

> Aplicación móvil Flutter para gestión de inventario y ventas de productos de limpieza.
> **Frontend**: Flutter 3.x + Dart 3.x
> **Backend**: Java 21 + Spring Boot 3.3.0 + MySQL 8.0 (Railway.app)

---

## 📋 Estado del Proyecto

| Módulo | Estado | Fase SDD |
|--------|--------|----------|
| ⚙️ Core (Red, Auth, Modelos) | 🔜 Pendiente | — |
| 📦 Productos | 🔜 Pendiente | — |
| 🧪 Materia Prima (Bulk) | 🔜 Pendiente | — |
| 🏭 Lotes de Producción | 🔜 Pendiente | — |
| 💰 Ventas (FIFO) | 🔜 Pendiente | — |

---

## 🏗️ Arquitectura

Usamos **Clean Architecture** con 3 capas:

```
lib/
├── core/              ← Infraestructura compartida
│   ├── network/       ← Cliente HTTP, interceptors, manejo de errores
│   ├── storage/       ← Persistencia local (tokens, caché)
│   └── models/        ← Modelos de datos compartidos
├── features/          ← Módulos de negocio
│   └── {modulo}/
│       ├── data/      ← Repositorios y fuentes de datos (API)
│       ├── domain/    ← Servicios con lógica de negocio
│       └── presentation/ ← Pantallas y state management
└── shared/            ← Widgets, helpers y utilidades reutilizables
```

### Patrones de Diseño

| Patrón | Propósito |
|--------|-----------|
| **Repository** | Abstrae la fuente de datos (API local vs remota) |
| **Provider** | State management con ChangeNotifier |
| **Service** | Lógica de negocio pura, sin dependencia de Flutter |
| **Interceptor** | Inyección automática de JWT en cada request |

### Metodología

- **SDD (Spec-Driven Development)**: Cada cambio pasa por 7 fases: exploración → propuesta → especificaciones → diseño → tareas → implementación → verificación → archivo
- **TDD (Test-Driven Development)**: Los tests se escriben ANTES del código de producción
- **Conventional Commits**: Commits atómicos por fase usando `feat:`, `chore:`, `fix:`

---

## 🚀 Cómo Empezar

```bash
# Clonar el repositorio
git clone <url>

# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run

# Ejecutar tests
flutter test

# Ver cobertura
flutter test --coverage
```

---

## 📚 Convenciones

### Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: agregar módulo de autenticación
       - login con JWT
       - registro de usuarios
       - persistencia de tokens

chore: configurar dependencias iniciales

fix: corregir manejo de error 401 en interceptor
```

### Ramas

| Tipo | Formato | Ejemplo |
|------|---------|---------|
| Feature | `feature/{nombre}` | `feature/auth-module` |
| Chore | `chore/{nombre}` | `chore/project-setup` |
| Fix | `fix/{nombre}` | `fix/login-error` |

### Estilo de Código

- **Comentarios en español** — todo método, clase y decisión se explica en español
- **Clean Code** — nombres descriptivos, funciones pequeñas, una responsabilidad por clase
- **Tests primero** — no se escribe código de producción sin su test correspondiente

---

## 📖 Historial de Cambios

| Fecha | Versión | Cambio | Ramas |
|-------|---------|--------|-------|
| — | — | Pendiente | — |

---

## 🔗 Enlaces

- [Documentación de la API del backend](./docs/API_REFERENCE.md)
- [Contexto del backend](./docs/BACKEND_CONTEXT.md)
- [Ruta de aprendizaje recomendada](./docs/LEARNING_PATH.md)

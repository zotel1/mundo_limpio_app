# Guía de Usuario — MundoLimpio

**App móvil** para la gestión integral de una empresa de productos de limpieza.
Flutter + Backend REST en Render.

---

## Índice

1. [Primeros Pasos](#1-primeros-pasos)
2. [Sistema de Roles](#2-sistema-de-roles)
3. [ADMIN — Acceso Total](#3-admin--acceso-total)
4. [STOCK_MANAGER — Gestión de Stock](#4-stock_manager--gestión-de-stock)
5. [STOCK_OPERATOR — Captura de Recibos](#5-stock_operator--captura-de-recibos)
6. [SALES_CLERK — Ventas](#6-sales_clerk--ventas)
7. [PRODUCTION_OP — Producción](#7-production_op--producción)
8. [ACCOUNTANT y CUSTOMER](#8-accountant-y-customer)
9. [Gestión de Inventario y Ratios de Conversión](#9-gestión-de-inventario-y-ratios-de-conversión)
10. [Sistema de OCR](#10-sistema-de-ocr)
11. [Carga Manual de Datos](#11-carga-manual-de-datos)
12. [Pantalla Principal y Navegación](#12-pantalla-principal-y-navegación)

---

## 1. Primeros Pasos

### Ingreso a la App

1. **Login**: ingresá con tu email y contraseña.
2. **Registro**: si no tenés cuenta,创建 una desde la pantalla de login.
3. **Splash**: al abrir la app, ves una pantalla de splash mientras se cargan los recursos y se verifica la sesión.

### Requisitos

- Conexión a internet (la app usa un backend REST en la nube).
- Sesión activa con JWT (el token se guarda en el dispositivo de forma segura).

---

## 2. Sistema de Roles

MundoLimpio tiene **7 roles** que determinan qué puede ver y hacer cada usuario.

| Rol | Etiqueta | Acceso principal |
|-----|----------|------------------|
| `ADMIN` | Administrador | TODO — gestión completa, usuarios incluidos |
| `STOCK_MANAGER` | Gestor de Stock | Inventario, productos, producción, recibos |
| `STOCK_OPERATOR` | Operario de Stock | Captura de recibos (OCR) |
| `SALES_CLERK` | Vendedor | Creación de ventas |
| `PRODUCTION_OP` | Operario de Producción | Creación de lotes de producción |
| `ACCOUNTANT` | Contador | Visión general (funcionalidad futura) |
| `CUSTOMER` | Cliente | Catálogo de productos |

Un usuario puede tener **uno o varios roles**. Se asignan desde la gestión de usuarios (solo ADMIN).

### ¿Dónde ves tus roles?

En la pantalla de **Perfil** (tercer tab del bottom nav) se muestran todos los roles asignados.

---

## 3. ADMIN — Acceso Total

El rol **ADMIN** tiene acceso completo a toda la funcionalidad.

### Puede hacer TODO lo siguiente:

- ✅ **Ventas** — crear nuevas ventas
- ✅ **Inventario** — ver listado, ver detalle de producto, ajustar stock
- ✅ **Productos** — crear, editar, ver listado y detalle
- ✅ **Producción** — gestionar materias primas a granel, crear lotes, ver historial
- ✅ **Recibos (OCR)** — escanear recibos, revisar resultados, confirmar compras
- ✅ **Usuarios** — ver listado de usuarios, editar roles (**solo ADMIN**)
- ✅ **Escaneo de Recibos** — cámara o galería

### Gestión de Usuarios

Es la única pantalla exclusiva de ADMIN. Desde `/users` podés:
- Ver el listado completo de usuarios registrados
- Ver y modificar los roles de cada usuario
- Asignar o quitar roles según sea necesario

---

## 4. STOCK_MANAGER — Gestión de Stock

El **Gestor de Stock** tiene acceso a la mayoría de las funciones operativas.

### Accesos:
- ✅ **Inventario** — ver listado, ver detalle, **ajustar stock** (entradas/salidas)
- ✅ **Productos** — crear, editar, ver listado y detalle
- ✅ **Producción** — materias primas a granel (crear/editar), ver historial
- ✅ **Recibos (OCR)** — escanear, revisar, confirmar
- ✅ **Ventas** — crear nuevas ventas

### Lo que NO puede hacer:
- ❌ Gestión de usuarios (usuarios y roles)
- ❌ Crear lotes de producción (asignado a PRODUCTION_OP)

> Nota: en la pantalla de inicio, ve los mismos botones de gestión que el ADMIN, excepto "Usuarios".

---

## 5. STOCK_OPERATOR — Captura de Recibos

El **Operario de Stock** tiene una función específica: capturar recibos mediante OCR.

### Accesos:
- ✅ **Recibos (OCR)** — seleccionar imagen de cámara o galería, procesar OCR
- ✅ **Productos** — ver catálogo
- ✅ **Perfil** — ver sus datos

### Lo que NO puede hacer:
- ❌ Gestión de usuarios
- ❌ Ajustes de inventario
- ❌ Crear/editar productos
- ❌ Gestión de producción
- ❌ Ventas

---

## 6. SALES_CLERK — Ventas

El **Vendedor** está enfocado exclusivamente en la gestión de ventas.

### Accesos:
- ✅ **Ventas** — crear nuevas ventas con cantidad
- ✅ **Productos** — ver catálogo
- ✅ **Perfil** — ver sus datos

### Lo que NO puede hacer:
- ❌ Gestión de inventario (no ve ajustes de stock)
- ❌ Crear/editar productos
- ❌ Producción
- ❌ Recibos (OCR)
- ❌ Usuarios

> Nota: en el home NO ve los botones de gestión (están ocultos para roles que no son ADMIN o STOCK_MANAGER).

---

## 7. PRODUCTION_OP — Producción

El **Operario de Producción** gestiona los lotes de producción.

### Accesos:
- ✅ **Producción** — **crear lotes de producción** (nuevo batch)
- ✅ **Historial de producción** — ver lotes anteriores
- ✅ **Productos** — ver catálogo
- ✅ **Perfil** — ver sus datos

### Lo que NO puede hacer:
- ❌ Gestión de materias primas a granel (crear/editar bulk products)
- ❌ Ajustes de inventario
- ❌ Recibos (OCR)
- ❌ Usuarios
- ❌ Ventas

---

## 8. ACCOUNTANT y CUSTOMER

### ACCOUNTANT (Contador)

Rol definido en el sistema pero **sin funciones específicas aún implementadas** en la app. Por el momento:
- Ve el catálogo de productos
- Ve su perfil
- No ve botones de gestión

> Está preparado para futuras funcionalidades contables (reportes, balances, etc.).

### CUSTOMER (Cliente)

El **Cliente** puede:
- ✅ Ver el catálogo de productos
- ✅ Ver su perfil
- ✅ Cerrar sesión

Está pensado para que los clientes puedan consultar productos disponibles, sin acceso a la gestión interna.

---

## 9. Gestión de Inventario y Ratios de Conversión

### Inventario

Desde **Inventario** (`/inventory`) podés:
- Ver el listado de todos los productos con su stock actual.
- Ver el detalle de cada producto.
- **Ajustar stock** (solo ADMIN y STOCK_MANAGER): registrar entradas o salidas con un motivo.

### Materias Primas a Granel (Bulk Products)

Los productos a granel son **insumos comprados en volumen** (ej: lavandina concentrada, alcohol, etc.) que se usan para producir los productos finales.

Cada bulk product tiene:
- **Nombre**
- **Stock actual en litros** — cuánto tenés disponible
- **Costo por litro** — para calcular costos de producción
- **Ratio de Conversión** — cuántos litros se necesitan para producir 1 unidad del producto terminado

### ¿Cómo funciona el Ratio de Conversión?

El **ratio de conversión** (`conversionRatio`) es el factor que relaciona el insumo a granel con el producto final.

**Ejemplo:**
- Comprás lavandina concentrada a granel.
- El `conversionRatio` es `0.5` → significa que necesitás **0.5 litros** de lavandina concentrada para producir **1 litro** de lavandina lista para la venta.
- Si producís 100 litros de lavandina lista, consumís `100 × 0.5 = 50 litros` del bulk.

**Cómo se usa:**
1. Definís el `conversionRatio` al crear un bulk product.
2. Al crear un lote de producción, el sistema descuenta automáticamente del stock del bulk según la cantidad producida y el ratio.
3. El `costPerLiter` te permite calcular cuánto sale producir cada unidad.

---

## 10. Sistema de OCR

### ¿Qué es?

El sistema OCR (Reconocimiento Óptico de Caracteres) permite **escaneá un recibo/factura** con la cámara y que el sistema extraiga automáticamente los datos de la compra.

### ¿Quién puede usarlo?

- ADMIN
- STOCK_MANAGER
- STOCK_OPERATOR

### Flujo completo

```
1. IDLE
   │
   ├── 📷 Sacar foto (cámara)
   └── 🖼️ Seleccionar de galería
       │
       ▼
2. IMAGEN SELECCIONADA
   │
   └── ▶️ Procesar Recibo
       │
       ▼
3. PROCESANDO
   │
   ├── ✅ Éxito → Pantalla de Revisión
   └── ❌ Error → Mensaje + botón Reintentar
       │
       ▼
4. REVISIÓN
   │
   ├── Editar proveedor (texto)
   ├── Editar fecha
   ├── Editar productos (nombre, cantidad, precio)
   └── Confirmar compra
       │
       ▼
5. CONFIRMANDO
   │
   ├── ✅ Confirmado → Pantalla de éxito
   └── ❌ Error → Mensaje + Reintentar
```

### ¿El OCR funciona?

El OCR se procesa **del lado del servidor (backend)**. La app:
1. Toma la foto o selecciona una imagen.
2. La envía al backend (API REST).
3. El backend la procesa y devuelve los datos extraídos: proveedor, fecha, productos con cantidades y precios.
4. La app muestra los resultados en la pantalla de **Revisión**.

**Para que el OCR funcione, el backend debe estar online y configurado con el servicio de OCR.**

### Indicadores de Confianza

Cada producto detectado tiene un nivel de **confianza** (de 0 a 1):
- **≥ 0.3** → confianza normal, sin advertencia
- **< 0.3** → se marca con ⚠️ "Confianza baja" en naranja

Siempre podés corregir los datos manualmente antes de confirmar.

---

## 11. Carga Manual de Datos

Además del OCR, la app permite **ingresar y modificar datos manualmente** en varios puntos:

### Productos
- **Crear producto**: formulario con SKU, nombre, descripción, precio, stock inicial.
- **Editar producto**: modificar cualquier campo de un producto existente.

### Materias Primas a Granel
- **Crear bulk product**: nombre, stock en litros, costo por litro, ratio de conversión.
- **Editar bulk product**: modificar cualquier campo.

### Ajuste de Stock
- Desde el detalle de inventario: ingresar cantidad y motivo para ajustar el stock (entrada o salida).

### Ventas
- Crear venta: ingresar cantidad a vender (por ahora es un valor simple).

### Revisión de OCR
- Después del escaneo, todos los campos son **editables**: proveedor, fecha, nombre de cada producto, cantidad y precio unitario.
- Si el OCR no detectó productos, podés agregarlos manualmente en la revisión (funcionalidad futura).

### Producción
- Crear lote: ingresar ID del producto terminado, cantidad usada del bulk, cantidad producida.

---

## 12. Pantalla Principal y Navegación

### Bottom Navigation (3 tabs)

| Tab | Etiqueta | Qué muestra |
|-----|----------|-------------|
| 0 | **Inicio** | Bienvenida + botones de acceso rápido a las funciones según el rol |
| 1 | **Gestión** o **Productos** | Si tenés acceso de gestión (ADMIN/STOCK_MANAGER): lo mismo que Inicio. Si no: catálogo de productos |
| 2 | **Perfil** | Email, roles asignados, botón de cerrar sesión |

### Rutas principales

| Ruta | Pantalla | Roles permitidos |
|------|----------|------------------|
| `/splash` | Splash screen | Todos |
| `/login` | Inicio de sesión | No autenticados |
| `/register` | Registro | No autenticados |
| `/` | Home | Autenticados |
| `/sales/new` | Nueva venta | ADMIN, SALES_CLERK |
| `/inventory` | Listado inventario | ADMIN, STOCK_MANAGER |
| `/inventory/:id` | Detalle producto (inv) | ADMIN, STOCK_MANAGER |
| `/products` | Listado productos | Todos (autenticados) |
| `/products/new` | Crear producto | ADMIN, STOCK_MANAGER |
| `/products/:id` | Detalle producto | Todos (autenticados) |
| `/products/:id/edit` | Editar producto | ADMIN, STOCK_MANAGER |
| `/users` | Gestión usuarios | **Solo ADMIN** |
| `/production/bulk-products` | Materias primas | ADMIN, STOCK_MANAGER |
| `/production/batches` | Historial producción | ADMIN, PRODUCTION_OP |
| `/production/batches/new` | Nueva producción | ADMIN, PRODUCTION_OP |
| `/receipts/new` | Escanear recibo | ADMIN, STOCK_MANAGER, STOCK_OPERATOR |
| `/receipts/review` | Revisar OCR | ADMIN, STOCK_MANAGER, STOCK_OPERATOR |
| `/receipts/confirmed` | Compra confirmada | ADMIN, STOCK_MANAGER, STOCK_OPERATOR |

> **Importante**: si no tenés el rol necesario para una ruta, el sistema te redirige automáticamente al Home.

---

## Resumen Visual por Rol

| Funcionalidad | ADMIN | STOCK_MGR | STOCK_OP | SALES_CLERK | PROD_OP | ACCOUNTANT | CUSTOMER |
|---|---|---|---|---|---|---|---|
| Gestión de Usuarios | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Inventario (ver/ajustar) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Productos (CRUD) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Productos (ver) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Ventas | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Producción (bulk) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Producción (lotes) | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| OCR (escanear) | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| OCR (revisar/confirmar) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

> **¿Preguntas o sugerencias?** Consultá con el administrador del sistema para ajustar roles o recibir capacitación adicional.

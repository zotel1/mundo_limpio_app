# Tutorial: Backend Alignment — Arreglando Mismatches Frontend vs Backend

## 1. El Problema

Después de implementar User Management, nos preguntamos qué más podíamos hacer. Mandamos agentes a hacer un análisis profundo del backend y descubrimos algo preocupante: **varios modelos del frontend no coincidían con lo que el backend realmente devuelve**.

### Síntomas
- `minPrice` de productos siempre era `null` en el frontend
- `BulkProductModel` tenía campos que el backend nunca envía
- `ProductionBatchModel` esperaba nombres distintos a los reales
- `AuthResponse` ignoraba el `email` y la lista completa de `roles`

No eran errores que rompieran la app, pero eran **bugs silenciosos** que hacían que datos válidos del backend se perdieran en el frontend.

---

## 2. La Investigación

Dos agentes exploraron en paralelo:

### Agente 1: Backend Deep Dive
Escaneó todas las entidades JPA, DTOs, y controllers del backend. Documentó:
- Cada campo con su tipo Java exacto
- El nombre de la columna en la base de datos
- El nombre de la propiedad JSON que Spring Boot genera
- Códigos de estado HTTP de cada endpoint

### Agente 2: Frontend Drift + Offline
Escaneó toda la base de datos Drift local, los servicios de conectividad, el SyncService, y los patrones de caché offline.

### El hallazgo clave
El backend usa **camelCase puro** (`minPrice`, `currentStockLiters`, `productId`), pero el frontend en algunos modelos esperaba **snake_case** (`min_price`, `unit_of_measure`, `finished_product_id`). Esto pasaba porque en algún momento alguien asumió que el backend usaba snake_case y puso `@JsonKey(name: 'snake_case')` en los modelos.

---

## 3. Los 4 Fixes

### Fix 1: AuthResponse — email + roles

**Antes**:
```dart
@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String role;        // deprecated, solo el primer rol
  final String username;
  final String createdAt;
  // email y roles NO EXISTÍAN
}
```

**Después**:
```dart
@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String role;              // deprecated, pero se mantiene
  final String? email;            // NUEVO
  final String username;
  final String createdAt;
  final List<String>? roles;      // NUEVO — lista completa
}
```

Y en `AuthProvider`:
```dart
String? get email => _email;
List<String>? get roles => _roles;

// Backward compat: role sigue funcionando
String get role => _roles?.first ?? _role ?? '';
```

**Por qué nullable**: si el backend cambia o si hay un token viejo en storage, no rompe.

### Fix 2: ProductModel — @JsonKey incorrecto

**Antes**:
```dart
@JsonKey(name: 'min_price')  // ← esto busca "min_price" en el JSON
final double? minPrice;
```

**Después**:
```dart
// Sin @JsonKey — el nombre del campo (minPrice) ya coincide con camelCase del backend
final double? minPrice;
```

El backend envía `"minPrice": 150.0` (camelCase). El frontend buscaba `"min_price"` (snake_case). Resultado: `minPrice` siempre era `null`.

### Fix 3: BulkProductModel — rediseño completo

**Antes** (inventado, no coincide con backend):
```dart
final int id;
final String name;
final String unitOfMeasure;  // ← no existe en backend
final double stock;          // ← backend lo llama currentStockLiters
```

**Después** (coincide con backend):
```dart
final int id;
final String name;
final double currentStockLiters;
final double costPerLiter;
final double conversionRatio;
final bool active;  // default: true
```

**El typo del backend**: El backend tiene un bug — su DTO de request espera `costperLiter` (con "p" minúscula), pero su response devuelve `costPerLiter` (bien). Para el request, el repositorio construye el Map manualmente:
```dart
'costperLiter': product.costPerLiter,  // typo intencional, coincide con backend
```

### Fix 4: ProductionBatchModel — de 5 a 9 campos

**Antes** (5 campos, nombres inventados):
```dart
final int id;
final int finishedProductId;  // backend lo llama productId
final int bulkProductId;
final double quantityUsed;    // backend lo llama rawQuantityUsed
final double quantityProduced; // backend lo llama initialQuantity
final DateTime date;          // backend lo llama productionDate
```

**Después** (9 campos, exactos del backend):
```dart
final int id;
final int productId;
final String? productName;    // NUEVO — el backend incluye el nombre
final int? bulkProductId;
final String? bulkProductName; // NUEVO
final double initialQuantity;
final double currentStock;    // NUEVO
final double unitCostAtProduction; // NUEVO
final double rawQuantityUsed;
final DateTime productionDate;
```

---

## 4. Lo que aprendimos

### Lección 1: Siempre verificar el JSON real del backend
Antes de escribir un modelo en el frontend, hay que pegarle al endpoint y ver el JSON que devuelve. No asumir convenciones.

### Lección 2: @JsonKey(name: ...) es poder y peligro
Si lo ponés, estás diciendo "el JSON usa este nombre". Si el backend cambia, el frontend lee null. Mejor evitar `@JsonKey` a menos que sea estrictamente necesario.

### Lección 3: Backend first
El backend es la fuente de verdad. Si el backend manda camelCase, el frontend usa camelCase. Punto.

### Lección 4: Los agentes de exploración son oro
Los dos agentes que mandamos al backend y al frontend encontraron estos mismatches en minutos. Sin ellos, probablemente nunca nos dábamos cuenta de que `minPrice` era siempre null.

---

## 5. Resultado Final

| Métrica | Antes | Después |
|---------|-------|---------|
| Tests | 911 | **917** (+6) |
| Análisis | 0 issues | 0 issues |
| Modelos alineados con backend | ❌ 4 rotos | ✅ 4 arreglados |
| Archivos modificados | — | 44 (12 source, 25 test, 4 .g.dart, 3 mocks) |

### Próximos pasos
Con los modelos ahora alineados, podemos:
- Mostrar productos offline (el Drift cache ya existe para ventas)
- Ventas pendientes con auto-sync (ya existe draft_sales, mejorar el SyncService)
- Control de stock offline (ya existe inventory_pending_queue)

# Ruta de Aprendizaje Recomendada 🎓

> Temas específicos de Flutter, Dart e Ingeniería de Software
> para que entiendas NO SOLO cómo hacerlo, sino POR QUÉ se hace así.

---

## 🎯 Fundamentos de Ingeniería de Software

### 1. Clean Architecture
**Qué es**: Arquitectura en capas donde el código se organiza por responsabilidades, NO por tipo de archivo. La regla de oro es que las capas internas (dominio) NO dependen de las externas (UI, datos).
**Por qué importa**: Separás la lógica de negocio de los frameworks. Si mañana cambiás Flutter por otra tecnología, tu lógica de negocio viaja con vos.
**Analogía**: Como un edificio — los cimientos (dominio) no cambian aunque remodeles la fachada (UI).

### 2. Principios SOLID
- **S** — Single Responsibility: Una clase, una responsabilidad. Un método, una cosa.
- **O** — Open/Closed: Abierto para extensión, cerrado para modificación.
- **L** — Liskov Substitution: Las subclases deben poder reemplazar a sus padres.
- **I** — Interface Segregation: Muchas interfaces específicas > una interfaz general.
- **D** — Dependency Inversion: Dependé de abstracciones, no de implementaciones.

### 3. Repository Pattern
**Qué es**: Un intermediario entre la fuente de datos (API, base de datos local) y el resto de la app.
**Por qué importa**: El dominio NO SABE si los datos vienen de internet, de una cache local, o de un archivo. Cambiás la fuente sin tocar el negocio.
**En nuestro proyecto**: `ProductRepository` puede llamar a la API o a una cache local — el `ProductService` no sabe ni le importa.

### 4. Inyección de Dependencias (DI)
**Qué es**: En lugar de que una clase cree sus dependencias internamente (`new HttpClient()`), las recibe por constructor o parámetro.
**Por qué importa**: Testeabilidad. Si querés testear `SaleService` sin hacer llamadas HTTP reales, injectás un `SaleRepository` mockeado.

### 5. State Management
**Qué es**: Cómo manejás el estado de la UI y cómo reacciona cuando los datos cambian.
**Opciones en Flutter**: Provider, Riverpod, Bloc, GetX, MobX.
**Por qué Provider**: Es el más simple, oficialmente recomendado por el equipo de Flutter, y suficiente para apps pequeñas/medianas. Si la app crece, migrar a Riverpod es directo porque comparten el mismo concepto de `ChangeNotifier`.

### 6. TDD (Test-Driven Development)
**Qué es**: Escribir el test ANTES del código de producción. El ciclo es: **Red** (test falla) → **Green** (código mínimo para pasar) → **Refactor** (mejorar sin romper).
**Por qué importa**: Garantizás que cada línea de código tiene un propósito. No escribís código "por si acaso". Además, los tests son documentación viva.

### 7. Conventional Commits
**Qué es**: Un formato estandarizado para mensajes de commit: `tipo(alcance): descripción`.
**Por qué importa**: Generás changelogs automáticos, facilitás la navegación del historial git, y todo el equipo habla el mismo idioma.

---

## 📱 Flutter & Dart

### 8. Widget Tree vs Element Tree vs Render Tree
**Qué es**: Flutter tiene 3 árboles paralelos. El Widget Tree (lo que escribís), el Element Tree (instancias), y el Render Tree (cómo se pinta en pantalla).
**Por qué importa**: Entender esto explica POR QUÉ ciertos widgets se reconstruyen y otros no. Es la base para optimizar rendimiento.
**Concepto clave**: Los widgets son "configuraciones", no "cosas". Cada vez que rebuild eas, creás nuevas configuraciones que se comparan con el Element Tree existente.

### 9. StatefulWidget vs StatelessWidget
**Qué es**: `StatelessWidget` no tiene estado mutable. `StatefulWidget` tiene un `State` que puede cambiar durante la vida del widget.
**Cuándo usar cada uno**: Stateless cuando la UI depende solo de los parámetros recibidos. Stateful cuando necesitás mantener estado o suscribirte a streams.
**Error común**: Poner todo como StatefulWidget por costumbre. Si no cambiás estado, usá Stateless.

### 10. BuildContext y su ciclo de vida
**Qué es**: `BuildContext` es la ubicación de un widget en el árbol de elementos. Te permite acceder al tema, navegación, inherited widgets, etc.
**Por qué importa**: Usar un `BuildContext` fuera de su ámbito (por ejemplo, en un callback asíncrono después de que el widget se destruyó) causa errores difíciles de debuggear.
**Regla**: Nunca guardes `BuildContext` en variables. Si necesitás acceso diferido, usá ` mounted` para verificar que el widget sigue vivo.

### 11. InheritedWidget e InheritedNotifier
**Qué es**: La base del sistema de estado de Flutter. `InheritedWidget` propaga datos hacia abajo en el árbol sin pasarlos explícitamente por constructor.
**Por qué importa**: Provider, Riverpod, Theme, MediaQuery — TODO se basa en InheritedWidget. Entenderlo te da superpoderes.
**En nuestro proyecto**: Provider usa InheritedWidget bajo el capó.

### 12. Streams y Futures en Dart
**Qué es**: `Future` representa un valor que va a llegar (una vez). `Stream` representa una secuencia de valores que llegan con el tiempo.
**Por qué importa**: Toda comunicación asíncrona en Dart se basa en estos dos conceptos. HTTP calls, file I/O, eventos de UI, sensores — todo son streams o futures.
**Dato importante**: `async`/`await` es azúcar sintáctica sobre Futures. No es magia — seguí siendo async, solo más legible.

### 13. Null Safety y el tipo `?`
**Qué es**: Dart 3 tiene null safety completo. Las variables NO pueden ser null a menos que explícitamente uses `?` (ej: `String? nombre`).
**Por qué importa**: Cero null pointer exceptions en runtime. El compilador te obliga a manejar los casos null.
**Patrón común**: Usar `??` (operador de coalescencia) para valores por defecto: `nombre ?? 'Sin nombre'`.

### 14. Extensions y métodos de extensión
**Qué es**: Podés agregar métodos a clases existentes SIN modificarlas ni heredarlas.
**Por qué importa**: Es la alternativa de Dart a los utility classes llenas de métodos estáticos.
**Ejemplo**: `extension FormatearPrecio on double { String get comoPrecio => '\$${toStringAsFixed(2)}'; }`

### 15. `const` vs `final` vs `static const`
**Qué es**: 
- `const`: Valor conocido en tiempo de compilación, NUNCA cambia, mismo objeto en memoria siempre.
- `final`: Se asigna una vez (puede ser en runtime), no se reasigna.
- `static const`: Constante de clase, conocida en compilación.
**Por qué importa**: Usar `const` donde sea posible mejora el rendimiento porque Flutter canibaliza instancias.

### 16. `copyWith` en objetos inmutables
**Qué es**: Patrón para crear una copia de un objeto con algunos campos modificados.
**Por qué importa**: En Flutter, trabajar con objetos inmutables previene bugs raros de estado. `copyWith` te da la flexibilidad de "cambiar" algo sin mutar el original.
**Ejemplo**: `producto.copyWith(minPrice: 2000.00)` — crea un nuevo producto con el precio cambiado, el original intacto.

---

## 🏛️ Patrones de Diseño Específicos para Mobile

### 17. MVC vs MVP vs MVVM vs MVI
**Qué es**: Diferentes formas de organizar la UI y el estado.
**En Flutter**: No hay un patrón "oficial". Nosotros usamos una variante de **MVVM** con Provider donde:
- **Model**: Los datos (repositories, modelos)
- **View**: Los widgets (pantallas)
- **ViewModel**: Los providers (lógica de presentación, estado)

### 18. Patrón Observer (con ChangeNotifier)
**Qué es**: Un objeto (sujeto) notifica a múltiples observadores cuando cambia.
**En nuestro proyecto**: `AuthProvider` extiende `ChangeNotifier`. Cuando el usuario se loguea, llama a `notifyListeners()` y todos los widgets que escuchan se reconstruyen automáticamente.

### 19. Patrón Singleton (y por qué evitarlo)
**Qué es**: Una clase con una única instancia global.
**Cuándo usarlo**: Casi nunca. Preferí inyección de dependencias.
**Excepción**: El `HttpClient` de Dio puede ser singleton. Pero incluso ahí, mejor injectarlo.
**Por qué evitarlo**: Dificulta los tests (no podés reemplazar la instancia), acopla el código, y esconde dependencias.

### 20. Patrón Adapter (con DTOs)
**Qué es**: Convertís datos de un formato a otro sin acoplar las capas.
**En nuestro proyecto**: Los modelos (DTOs) convierten JSON del backend a objetos Dart. Si el backend cambia su respuesta, solo tocás el modelo, no la UI.

---

## 🔧 Temas Operativos

### 21. Git Flow vs GitHub Flow
**Qué es**: Estrategias de ramas.
**Nosotros**: Usamos **GitHub Flow** simplificado: `main` → `feature/*` → PR a `main`. Simple, efectivo.

### 22. Code Review
**Qué es**: Otro ser humano (o AI) revisa tu código antes de mergear.
**Por qué importa**: Atrapás bugs antes de que lleguen a producción, compartís conocimiento, y mejorás la calidad del código.
**En nuestro proyecto**: Usamos `judgment-day` skill para reviews adversariales.

### 23. CI/CD
**Qué es**: Integración Continua (tests automáticos en cada push) + Despliegue Continuo (subir a producción automáticamente).
**Para mobile**: GitHub Actions + Firebase App Distribution (Android) o TestFlight (iOS).

### 24. Gestión de Errores y Logging
**Qué es**: No solo try/catch. Es tener una estrategia: qué errores mostrás al usuario, cuáles logueás, cuáles reportás.
**En nuestro proyecto**: `ErrorHandler` centralizado que distingue entre errores de red, de validación, y del servidor.

---

## 📚 Cómo estudiar estos temas

1. **No los leas todos de una** — elegí UNO por semana y profundizá
2. **Relacioná con el código** — cuando implementemos algo, fijate qué patrón/principio estamos usando
3. **Preguntame** — cada vez que no entiendas algo, decime "¿por qué hacemos esto así?" y te explico
4. **Experimentá** — abrí DartPad y probá conceptos aislados

> "No es magia, es ingeniería." — cada línea de código es una decisión con fundamento.

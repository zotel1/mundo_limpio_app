# Guía de Estudio — Ingeniería de Software (Mobile/Flutter)

> Guía viva — se actualiza a medida que avanzamos en el proyecto MundoLimpio.
> Cada concepto incluye: definición, por qué importa, y relación con el proyecto (si aplica).

---

## 📍 Sesión 1 — Core Auth Setup (Fase Spec)

Conceptos relacionados al cambio actual: infraestructura de red, autenticación JWT, estado y routing.

---

### 1. JWT (JSON Web Tokens)

**Concepto**: Es un estándar abierto (RFC 7519) para transmitir información de forma segura entre dos partes usando un token firmado digitalmente. Un JWT tiene tres partes: Header (algoritmo + tipo), Payload (datos del usuario como `username`, `role`), y Signature (firma que verifica que no fue alterado).

**Por qué importa**: A diferencia de sessions tradicionales (que guardan estado en el servidor), JWT es **stateless** — el servidor no necesita almacenar la sesión. Solo verifica la firma del token. Esto escala horizontalmente sin esfuerzo.

**En el proyecto**: El backend genera un JWT al hacer login/register. El frontend lo recibe, lo guarda en `flutter_secure_storage`, y lo envía en cada request como `Authorization: Bearer <token>`. El `AuthInterceptor` de dio lo inyecta automáticamente.

---

### 2. Patrón Interceptor (Chain of Responsibility)

**Concepto**: Un interceptor es una capa intermedia que se ejecuta antes o después de una request HTTP. Podés tener múltiples interceptors encadenados: uno para logging, otro para auth, otro para errores. Cada uno decide si procesa o pasa al siguiente.

**Por qué importa**: Separa responsabilidades transversales (auth, logging, errores) del código de negocio. Sin interceptors, cada llamada API tendría que manejar tokens manualmente.

**En el proyecto**: `AuthInterceptor` en dio intercepta CADA request saliente para:
1. Antes (onRequest): agrega el token al header
2. Después (onError): si recibe 401, intenta refrescar el token automáticamente y reintenta la request

Esto es **transparente** para el código de negocio — los repositorios ni se enteran de que existe el interceptor.

---

### 3. Principio de Responsabilidad Única (SRP — Single Responsibility Principle)

**Concepto**: El "S" de SOLID. Dice que **una clase debe tener UNA y SOLO UNA razón para cambiar**. Si una clase hace demasiadas cosas, cuando algo cambia, tenés que tocarla por múltiples motivos.

**Por qué importa**: Si metés lógica de red + storage + UI en una misma clase, cambiás el proveedor de almacenamiento y tenés que tocar la UI. Eso es código frágil.

**En el proyecto**: En `core-auth-setup` aplicamos SRP estrictamente:
- `TokenStorage` — solo lee/escribe tokens
- `AuthApi` — solo hace llamadas HTTP (register, login, refresh)
- `AuthRepository` — solo orquesta (API + storage)
- `AuthProvider` — solo maneja estado de UI
- `AuthInterceptor` — solo intercepta requests

Cada uno hace UNA cosa y la hace bien.

---

### 4. Patrón Repositorio (Repository Pattern)

**Concepto**: Es una capa de abstracción entre la fuente de datos (API, base de datos local, cache) y el resto de la aplicación. El dominio NUNCA sabe si los datos vienen de internet, del disco, o de un archivo.

**Por qué importa**: Desacoplás la fuente de datos del consumo. Si mañana el backend cambia su API, solo tocás el repositorio, no las pantallas. Si agregás cache offline, el repositorio maneja la lógica sin que la UI se entere.

**En el proyecto**: `AuthRepository` es una interfaz abstracta con métodos como `login()`, `register()`, `logout()`. La implementación concreta `AuthRepositoryImpl` orquesta: llama a `AuthApi`, guarda tokens en `TokenStorage`, maneja errores. El `AuthProvider` solo conoce la **interfaz**, no la implementación.

---

### 5. Provider + ChangeNotifier (State Management)

**Concepto**: Provider es un wrapper sobre `InheritedWidget` de Flutter que permite propagar estado hacia abajo en el árbol de widgets sin pasarlo explícitamente por constructor. `ChangeNotifier` es una clase que notifica a los listeners cuando cambia (llamás `notifyListeners()` y los widgets que escuchan se reconstruyen).

**Por qué importa**: Resolvé el problema de "prop drilling" (pasar datos por 15 niveles de widgets). El estado vive en un provider arriba en el árbol, y cualquier widget hijo puede accederlo con `context.watch<AuthProvider>()`.

**En el proyecto**: `AuthProvider` extiende `ChangeNotifier` y expone:
- `AuthStatus` (unauthenticated / authenticated / loading)
- `login()`, `register()`, `logout()` — llama al repositorio, actualiza estado, notifica
- Los widgets de LoginScreen, HomeScreen, y el redirect de go_router WATCH este provider para saber si mostrar login o home

---

### 6. GoRouter y Redirects Declarativos

**Concepto**: go_router es un paquete de routing declarativo para Flutter. En lugar de navegar con `Navigator.push()` imperativo, definís rutas y redirects con funciones puras que se ejecutan automáticamente cuando cambia el estado.

**Por qué importa**: Los redirects declarativos son la forma más limpia de manejar autenticación. Cuando el usuario cierra sesión, el estado cambia, y go_router AUTOMÁTICAMENTE redirige a login. No necesitás `Navigator.pushReplacement()` en cada lugar.

**En el proyecto**: El router tiene:
```dart
redirect: (context, state) {
  final authStatus = context.read<AuthProvider>().status;
  final isLoginRoute = state.matchedLocation == '/login';
  
  if (authStatus == AuthStatus.unauthenticated && !isLoginRoute) {
    return '/login'; // Redirige a login si no está autenticado
  }
  if (authStatus == AuthStatus.authenticated && isLoginRoute) {
    return '/'; // Redirige a home si ya está logueado
  }
  return null; // Sigue normal
}
```
Esto se ejecuta en CADA navegación. Sin if-else enredados.

---

### 7. Secure Storage vs SharedPreferences

**Concepto**: `SharedPreferences` guarda datos en texto plano (XML en Android, plist en iOS). `flutter_secure_storage` usa el keystore del sistema operativo (Keychain en iOS, EncryptedSharedPreferences en Android).

**Por qué importa**: Guardar un JWT en SharedPreferences es como dejar la llave de tu casa debajo del felpudo. Cualquier app con acceso al dispositivo puede leerlo. Secure storage encripta los datos en reposo.

**En el proyecto**: Es una regla NO NEGOCIABLE. Los JWT solo van en `flutter_secure_storage`. Punto. En la spec (R1) está especificado: `MUST NOT use shared_preferences`.

---

### 8. Inyección de Dependencias (Dependency Injection)

**Concepto**: En lugar de que una clase cree sus dependencias internamente (`new HttpClient()`), las recibe por constructor o parámetro. Quién las provee es un "contenedor" (en nuestro caso, el árbol de providers de Flutter).

**Por qué importa**: **Testeabilidad**. Para testear `AuthProvider` sin hacer llamadas HTTP reales, injectás un `AuthRepository` mockeado que siempre devuelve éxito. Sin DI, no podrías reemplazar la implementación sin tocar el código.

**En el proyecto**:
```dart
// MAL — AuthProvider crea sus dependencias (no testeable)
class AuthProvider extends ChangeNotifier {
  final _repository = AuthRepositoryImpl();
}

// BIEN — recibe las dependencias (testeable)
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  AuthProvider(this._repository); // Podés pasar un mock en tests
}
```

---

### 9. Arquitectura Limpia (Clean Architecture) — Capas

**Concepto**: Organización del código en capas concéntricas donde las capas internas (dominio) NO saben nada de las externas (UI, datos). Regla de dependencia: **las dependencias apuntan hacia adentro**, nunca hacia afuera.

**Por qué importa**: Separás la lógica de negocio de los frameworks. Si cambiás Flutter por otra tecnología, tu lógica de dominio viaja con vos. Si cambiás Provider por Riverpod, solo tocás la capa de presentación.

**En el proyecto**: Estructura por feature:
```
lib/features/auth/
├── data/              ← Capa externa (implementación concreta)
│   ├── api/           ←   AuthApi (dio calls)
│   ├── repository/    ←   AuthRepositoryImpl
│   └── models/        ←   AuthResponse, LoginRequest (json_serializable)
├── domain/            ← Capa interna (interfaces, entidades puras)
│   └── repository/    ←   AuthRepository (interfaz abstracta)
└── presentation/      ← Capa externa (Flutter-specific)
    ├── provider/      ←   AuthProvider (ChangeNotifier)
    └── screens/       ←   LoginScreen, RegisterScreen
```

El `domain/` NO importa nada de Flutter, dio, ni flutter_secure_storage. Es Dart puro.

---

### 10. DTO (Data Transfer Object) vs Entidad de Dominio

**Concepto**: Un DTO es un objeto que transporta datos entre capas (generalmente entre la API y la app). Una entidad de dominio es un objeto que representa un concepto de negocio con reglas y comportamiento.

**Por qué importa**: Mezclar DTOs con entidades de dominio acopla tu lógica de negocio al formato de la API. Si el backend cambia el nombre de un campo, tu lógica de negocio se rompe.

**En el proyecto**: Los DTOs (`AuthResponse`, `LoginRequest`) son los que se serializan/deserializan con `json_serializable`. Viven en `data/models/`. Son simplemente datos, sin lógica. Si el backend cambia el response, solo toco el DTO, no la lógica de negocio.

---

## 📍 Sesión 2 — Core Auth Setup (Fase Design)

Conceptos que surgieron al diseñar la arquitectura.

---

### 11. Máquina de Estados (State Machine) en UI

**Concepto**: Una máquina de estados define un conjunto finito de estados y las transiciones válidas entre ellos. En UI se usa para modelar pantallas que cambian según un estado global. Ejemplo clásico: `loading → authenticated | unauthenticated`.

**Por qué importa**: Sin una máquina de estados explícita, terminás con booleanos sueltos (`isLoading`, `isLoggedIn`, `hasError`) que se pueden combinar en estados imposibles (ej: `isLoading=true AND isLoggedIn=true`). Un enum de estados elimina esas combinaciones inválidas de raíz.

**En el proyecto**: `AuthStatus` es un enum con tres valores: `loading`, `authenticated`, `unauthenticated`. Arranca en `loading` (mientras resuelve si hay tokens guardados), después pasa a `authenticated` o `unauthenticated`. Nunca puede estar en dos estados a la vez. GoRouter mira este enum para decidir el redirect. No hay booleans.

```dart
enum AuthStatus { loading, authenticated, unauthenticated }
// Transiciones: loading → authenticated | unauthenticated
// No existe: loading + authenticated al mismo tiempo
```

---

### 12. Patrón Estrategia (Strategy Pattern) con Abstract Classes

**Concepto**: Definís una interfaz/contrato (abstract class en Dart) y múltiples implementaciones concretas. El consumidor usa la interfaz sin saber qué implementación está usando.

**Por qué importa**: Es la base del Open/Closed Principle (SOLID). Podés cambiar implementaciones sin modificar el consumidor. Para tests, injectás una implementación mockeada.

**En el proyecto**: `AuthRepository` es una abstract class con métodos como `login()`, `register()`, `logout()`. Cuando el `AuthProvider` habla con el repositorio, no sabe si la implementación real está llamando a la API o si es un mock devolviendo datos falsos. Eso permite testear el provider sin hacer llamadas HTTP.

```dart
// Contrato (domain layer — Dart puro)
abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<void> register(String email, String password);
}

// Implementación real (data layer — usa dio)
class AuthRepositoryImpl implements AuthRepository { ... }

// Mock para tests
class MockAuthRepository implements AuthRepository { ... }
```

---

### 13. Provider Tree y MultiProvider

**Concepto**: En Flutter con Provider, los providers se organizan en un árbol. `MultiProvider` es un widget que envuelve toda la app y registra múltiples providers. Cada provider puede depender de otros providers (ej: `AuthRepository` necesita `TokenStorage`).

**Por qué importa**: El orden en que declarás los providers importa — si `AuthProvider` depende de `AuthRepository`, este último debe declararse primero. Si te equivocás de orden, la app explota al iniciar.

**En el proyecto**: `main.dart` va a tener:

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>(create: (_) => TokenStorage()),        // 1º — sin dependencias
        Provider<AuthRepository>(                                      // 2º — depende de TokenStorage
          create: (ctx) => AuthRepositoryImpl(
            api: AuthApi(dio),
            storage: ctx.read<TokenStorage>(),
          ),
        ),
        ChangeNotifierProvider<AuthProvider>(                           // 3º — depende de AuthRepository
          create: (ctx) => AuthProvider(ctx.read<AuthRepository>()),
        ),
      ],
      child: const MundoLimpioApp(),
    ),
  );
}
```

El orden es: dependencias → dependientes. `TokenStorage` no depende de nadie → primero. `AuthProvider` depende de `AuthRepository` → último.

---

### 14. json_serializable y build_runner (Code Generation)

**Concepto**: `json_serializable` genera automáticamente los métodos `fromJson()` / `toJson()` para tus clases Dart, basándose en anotaciones como `@JsonSerializable()`. `build_runner` es el motor que ejecuta los generadores de código.

**Por qué importa**: Escribir `fromJson/toJson` a mano para 8+ modelos es tedioso, propenso a errores (typós en keys), y un dolor de mantener. La generación de código elimina esa fricción. Cambiás un campo y el código se regenera solo.

**En el proyecto**: Necesitamos 3 modelos serializables (`AuthResponse`, `LoginRequest`, `RegisterRequest`). Con `json_serializable`:

```dart
@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String role;
  final String username;
  final DateTime createdAt;

  AuthResponse({required this.accessToken, ...});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
```

Corrés `dart run build_runner build` y los métodos `_$AuthResponseFromJson` se generan automáticamente.

**Concepto relacionado**: **Code Generation vs Reflection**. Dart no tiene reflection en producción (por tree-shaking). La generación de código es la alternativa: generás el código en build time en vez de inferirlo en runtime.

---

### 15. Modelo Vista VistaModelo (MVVM)

**Concepto**: MVVM separa tres roles: **Model** (datos y lógica de negocio), **View** (UI, widgets), **ViewModel** (estado de la pantalla, lógica de presentación). La View se SUSCRIBE al ViewModel y se actualiza automáticamente cuando el estado cambia.

**Por qué importa**: Separás la lógica de presentación de los widgets. Los widgets quedan tontos (solo renderizan estado). El ViewManager se testea sin UI. En Flutter esto es natural: los widgets son la View, los providers/ChangeNotifiers son el ViewModel.

**En el proyecto**: Nuestra variante de MVVM con Provider:
- **Model**: `AuthRepository` + `AuthApi` + `TokenStorage` (datos y lógica)
- **View**: `LoginScreen`, `RegisterScreen`, `HomeScreen` (widgets)
- **ViewModel**: `AuthProvider` (estado: `AuthStatus`, métodos: `login()`, `register()`, `logout()`)

```dart
// ViewModel
class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.loading;
  AuthStatus get status => _status;

  Future<void> login(String email, String password) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      await _repository.login(email, password);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
    }
    notifyListeners();
  }
}

// View (widget) — se suscribe automáticamente
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    // provider.status → decide qué renderizar
    // provider.login() → se llama desde un botón
  }
}
```

---

### 16. GoRouter ShellRoute y Nested Navigation

**Concepto**: `ShellRoute` te permite envolver un grupo de rutas con un layout común (ej: BottomNavigationBar, AppBar persistente). Nested navigation significa tener múltiples navegadores anidados (ej: tabs que mantienen su propio stack).

**Por qué importa**: En apps móviles es común tener un shell con tabs. Sin ShellRoute, cada tab pierde su estado al navegar. ShellRoute preserva el stack de cada rama.

**En el proyecto**: Por ahora solo usamos rutas planas (`/login`, `/register`, `/`), pero cuando agreguemos tabs (Productos, Ventas, Stock), usaremos `ShellRoute` para envolverlas con un AppBar + BottomNavigationBar persistente. El redirect de auth sigue funcionando porque `GoRouter.redirect` se ejecuta antes de cualquier ruta.

```dart
// Ahora — rutas planas
GoRouter(routes: [
  GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
  GoRoute(path: '/register', builder: (_, __) => RegisterScreen()),
  GoRoute(path: '/', builder: (_, __) => HomeScreen()),
]);

// Después — shell con tabs
GoRouter(routes: [
  ShellRoute(builder: (_, __, child) => AppShell(child: child), routes: [
    GoRoute(path: '/products', ...),
    GoRoute(path: '/sales', ...),
    GoRoute(path: '/stock', ...),
  ]),
]);
```

---

### 17. Manejo de Errores en Capas (Error Handling Strategy)

**Concepto**: No es solo try/catch. Es una jerarquía: qué errores atrapás en cada capa, cómo los transformás, y qué llega al usuario final. La regla de oro es: **las capas internas lanzan excepciones específicas; las capas externas las transforman en mensajes de usuario**.

**Por qué importa**: Si dejas que un `DioException` crudo llegue a la UI, tenés dos problemas: (1) la UI sabe que estás usando Dio (acoplamiento), (2) el usuario ve "SocketException: Connection refused" en vez de "No hay conexión a internet".

**En el proyecto**:
```
DioException (de Dio) → ApiException (capa core)
  ├── AuthException (401, tokens expirados)
  ├── NetworkException (sin conexión, timeout)
  └── ServerException (500, errores del backend)
```

`ErrorHandler` transforma cada `ApiException` en un mensaje amigable. El `AuthProvider` solo ve `ApiException` — no sabe que existe Dio.

```dart
// Capa core — traduce errores de Dio a nuestra jerarquía
try {
  return await _dio.post(...);
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    throw NetworkException('Sin conexión al servidor');
  }
  if (e.response?.statusCode == 401) {
    throw AuthException('Sesión expirada');
  }
  throw ServerException('Error del servidor');
}
```

---

## 📚 Notas de Estudio

| # | Concepto | Sesión | ¿Entendido? | Profundizar |
|---|----------|--------|-------------|-------------|
| 1 | JWT | Spec | ⬜ | RFC 7519, access vs refresh tokens |
| 2 | Interceptor Pattern (Chain of Responsibility) | Spec | ⬜ | Implementar tu propio interceptor desde cero |
| 3 | SRP (SOLID) | Spec | ⬜ | Los 5 principios SOLID completos |
| 4 | Repository Pattern | Spec | ⬜ | Vs DAO, cuándo usar cada uno |
| 5 | Provider / ChangeNotifier | Spec | ⬜ | Vs Riverpod, Vs Bloc |
| 6 | GoRouter redirects | Spec | ⬜ | Deep linking, nested routes, ShellRoute |
| 7 | Secure Storage | Spec | ⬜ | Keychain vs EncryptedSharedPreferences |
| 8 | Dependency Injection | Spec | ⬜ | Vs Service Locator, Dagger/Hilt en Android |
| 9 | Clean Architecture | Spec | ⬜ | Vs MVC, Vs MVVM hexagonal, arquitectura limpia |
| 10 | DTO / Domain Entities | Spec | ⬜ | Mapper pattern, Value Objects, anemic domain model |
| 11 | State Machine (enum states) | Design | ⬜ | State pattern, finite state machines en UI |
| 12 | Strategy Pattern (abstract classes) | Design | ⬜ | Template Method, Open/Closed Principle |
| 13 | MultiProvider / Provider Tree | Design | ⬜ | Dependencias entre providers, orden de creación |
| 14 | json_serializable / Code Generation | Design | ⬜ | freezed, build_runner, code gen vs reflection |
| 15 | MVVM (Model-View-ViewModel) | Design | ⬜ | MVC vs MVP vs MVVM vs MVI en Flutter |
| 16 | ShellRoute / Nested Navigation | Design | ⬜ | GoRouter advanced patterns |
| 17 | Error Handling Strategy | Design | ⬜ | Either type (dartz/fpdart), Result pattern |

---

> *"No es magia, es ingeniería." — cada concepto acá tiene un por qué.*
> Próxima actualización: cuando avancemos a Tasks.

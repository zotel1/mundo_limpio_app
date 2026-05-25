# Tutorial: Cómo arreglamos 25 tests que fallaban

## El Problema

Teníamos **25 tests fallando** en el proyecto MundoLimpio, distribuidos en **17 archivos**. Lo peor: estos tests **ya fallaban antes** de que tocáramos nada — no eran regresiones de nuestro código, sino un problema de **entorno de tests** que arrastrábamos desde el update a Flutter 3.44.0.

```bash
# El comando que lo mostraba:
flutter test
# Resultado: 694 passed, 25 failed 😱
```

## La Investigación (fase explore)

En vez de adivinar, delegamos un sub-agente `sdd-explore` para que ejecutara `flutter test`, capturara TODOS los errores, leyera cada archivo de test, y categorizara las causas raíz.

El resultado fue sorprendente: **solo 2 causas raíz** para 25 failures.

### Causa 1: El Shader `ink_sparkle` (17 failures, 16 archivos)

**¿Qué pasaba?**

Flutter 3.44.0 viene con Material 3 activado por defecto. Material 3 usa `InkSparkle.splashFactory` como el efecto de ripple al tocar botones. El problema: cuando un test ejecuta un `tap()` o `pumpAndSettle()`, Flutter intenta cargar el shader `shaders/ink_sparkle.frag` compilado.

Pero hay un mismatch de versiones — el binario del shader está compilado con SPIR-V version 1, y el test framework espera version 2. Resultado:

```
Exception: Asset 'shaders/ink_sparkle.frag' manifest could not be decoded:
INVALID_ARGUMENT: Unsupported runtime stages format version. Expected 2, got 1.
```

**¿Por qué pasaba solo en tests?**

Porque en producción el shader se carga de otra forma. El test framework usa `FragmentProgram.fromAsset` que es más estricto con la versión del formato. No es un bug de nuestro código — es un **bug conocido de Flutter 3.44.0** en entorno de testing.

**¿Por qué no lo habíamos visto antes?** Porque la versión anterior de Flutter (3.41.x) no tenía este problema. Apareció al hacer el upgrade.

### Causa 2: Workaround Rotero (8 failures, 1 archivo)

**¿Qué pasaba?**

Alguien (yo, en un commit anterior 😅) intentó arreglar el problema del shader con este workaround:

```dart
setUpAll(() {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
});

tearDownAll(() {
  debugDefaultTargetPlatformOverride = null;
});
```

La idea: cambiar el target platform a Android evita que Flutter intente cargar el shader. **No funcionó.** Y además, modificar `debugDefaultTargetPlatformOverride` hace que el test framework tire error porque estás cambiando una variable de debug de Foundation.

**Moraleja**: Los workaround apurados sin entender la causa raíz suelen empeorar las cosas.

## Las Soluciones

### Solución 1: NoSplash.splashFactory (17 tests)

En vez de parchar el comportamiento global, aprendimos que existe `NoSplash.splashFactory` — una fábrica de splash que **no genera animaciones de ripple**. Al usarla en el `MaterialApp` de cada test, el shader `ink_sparkle` nunca se invoca porque no hay splash que renderizar.

**Antes**:
```dart
await tester.pumpWidget(
  const MaterialApp(home: MyWidget()),
);
```

**Después**:
```dart
await tester.pumpWidget(
  MaterialApp(
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
    home: MyWidget(),
  ),
);
```

**¿Por qué funciona?** `NoSplash.splashFactory` implementa `InteractiveInkFeatureFactory` pero devuelve un `NoSplash` que no dibuja nada. El shader nunca se carga, el error nunca aparece.

**Tradeoff**: Los tests no prueban el efecto visual del ripple. Eso está bien — los widget tests verifican estructura y comportamiento, no animaciones visuales.

### Solución 2: Borrar el Workaround (8 tests)

Simple pero importante: eliminamos el `setUpAll`/`tearDownAll` que modificaba `debugDefaultTargetPlatformOverride`. Al aplicar la Solución 1, este workaround ya no era necesario.

**Cambio**: Eliminar 6 líneas, 1 import (`package:flutter/foundation.dart`).

## El Paso a Paso de la Implementación

### Fase 1: branded_error_banner (1 archivo, ~2 min)

1. Leer el archivo `test/core/widgets/branded_error_banner_test.dart`
2. Identificar el `setUpAll` y `tearDownAll` con `debugDefaultTargetPlatformOverride`
3. Eliminarlos
4. Eliminar `import 'package:flutter/foundation.dart'` si ya no se usa
5. Verificar que el archivo compile

### Fase 2: NoSplash en 16 archivos (~30 min)

Para CADA archivo de test:

1. **Leer** el archivo para entender su estructura
2. **Buscar** el `MaterialApp` o `MaterialApp.router` dentro del test
3. **Si es `const`**: sacar el `const` (porque `ThemeData()` no es const)
4. **Agregar**: `theme: ThemeData(splashFactory: NoSplash.splashFactory),`
5. **Si ya tiene `theme:`**: fusionar el splashFactory dentro del ThemeData existente
6. **Si es `MaterialApp.router`**: funciona igual, solo se agrega el parámetro `theme`

#### Patrones encontrados

| Patrón | Ejemplo | Cambio |
|--------|---------|--------|
| `const MaterialApp(...)` | `const MaterialApp(home: Text('Hola'))` | Sacar `const`, agregar `theme:` |
| `MaterialApp.router(...)` | `MaterialApp.router(routerConfig: router)` | Agregar `theme:` |
| Con `theme:` existente | `MaterialApp(theme: appTheme, ...)` | Agregar `.copyWith(splashFactory: NoSplash.splashFactory)` o modificar el ThemeData |

### Fase 3: Verificación (~5 min)

```bash
flutter test        # → 719/719 ✅
flutter analyze     # → No issues found ✅
dart format --set-exit-if-changed lib/ test/  # → 0 files changed ✅
```

## Resultado Final

| Métrica | Antes | Después |
|---------|-------|---------|
| Tests pasando | 694 | **719** |
| Tests fallando | 25 | **0** ✅ |
| flutter analyze | OK | OK |
| dart format | OK | OK |
| Código producción tocado | — | **0 archivos** |
| Archivos de test modificados | — | 17 |

## Key Learnings

1. **Siempre investigar la causa raíz** antes de aplicar workarounds. El primer fix (commit 5249f29) intentó parchar el síntoma sin entender el problema real y solo empeoró las cosas (8 failures nuevos).

2. **`NoSplash.splashFactory` es tu amigo** en tests cuando el shader de Material 3 da problemas. No afecta producción y es una solución quirúrgica.

3. **El SDD cycle vale la pena** incluso para arreglos "chicos". La fase `explore` nos ahorró horas de prueba y error al identificar las 2 causas raíz en vez de ir archivo por archivo adivinando.

4. **El contexto importa**: estos tests fallaban en `develop` también, pero nadie los había investigado sistemáticamente porque "ya fallaban antes". La exploración estructurada encontró la causa real en minutos.

5. **Flutter 3.44.0 cambió cosas**: el upgrade de Flutter trajo Material 3 por defecto, y con eso, efectos secundarios en tests que antes no existían. Siempre revisar los changelogs de Flutter cuando se actualiza la versión.

---

## Bonus: Error de `dart format` en CI post-rebase

Después de mergear los fixes, el CI de GitHub Actions falló con:

```
dart format --set-exit-if-changed lib/ test/
Formatted 204 files (4 changed) in 0.73 seconds.
Error: Process completed with exit code 1.
```

### ¿Por qué pasó?

El workflow de CI corre sobre **el merge commit** del PR (tu branch + develop mergeados por GitHub). Entre que nosotros arrancamos el SDD y creamos el PR, **otro branch se mergeó a develop** (`feat/r4-deep-link`). Ese merge trajo archivos nuevos con formato no estandarizado:

- `lib/core/services/url_launcher_service.dart`
- `test/core/services/url_launcher_service_test.dart`
- `lib/core/services/notifications_service.dart` (ya existía pero con formato viejo)
- `test/core/services/notifications_service_test.dart`

Al calcular el merge commit del PR, GitHub mezcla nuestro código + develop, y esos 4 archivos aparecen con formato incorrecto. `dart format --set-exit-if-changed` los detecta, los corrige, y como los cambió... sale con exit code 1 (fail).

### ¿Qué hay que hacer?

**Paso 1 — No asustarse**. No es un error nuestro, es que develop avanzó mientras tanto.

**Paso 2 — Rebasear la branch sobre develop actualizado**:

```bash
git fetch origin develop
git rebase origin/develop
```

Esto reaplica nuestros commits encima del develop más reciente, incorporando todos los cambios nuevos (incluyendo los archivos con formato incorrecto).

**Paso 3 — Correr `dart format` en TODO el proyecto**:

```bash
dart format --set-exit-if-changed lib/ test/
```

Si muestra archivos como "Formatted", esos son los que necesitan commit.

**Paso 4 — Commitear los format fixes y pushear con fuerza**:

```bash
git add -A
git commit -m "style: fix dart formatting after rebase on develop"
git push --force-with-lease origin feat/main-di-wiring
```

⚠️ **`--force-with-lease`** es obligatorio porque el rebase reescribe la historia. No usar `--force` a secas — `--force-with-lease` es más seguro porque verifica que nadie más haya pusheado cambios mientras tanto.

### ¿Por qué `dart format` no se puede safear?

Porque el CI corre `--set-exit-if-changed`. Ese flag hace que `dart format`:
1. Formatee los archivos que encuentra
2. Pero si formateó AL MENOS UNO, sale con exit code 1

No importa si los archivos son nuestros o no — el CI los ve a todos. La postura correcta: **formatear todo lo que el CI ve, sin importar de quién sea el código**. Es un commit mecánico, no toca lógica.

### Lección

Cuando trabajás en una rama por varios días, develop avanza. Al crear el PR pueden aparecer falsos positivos de formato de archivos que no tocaste. La solución es siempre la misma:

```
git fetch origin develop
git rebase origin/develop
dart format --set-exit-if-changed lib/ test/
git add -A && git commit -m "style: format after rebase"
git push --force-with-lease origin <tu-rama>
```

---

*Este tutorial fue generado a partir del SDD `test-fix-suite`, completado el 2026-05-25. Actualizado con el bonus del error de formato CI.*

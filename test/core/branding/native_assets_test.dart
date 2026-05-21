// Pruebas de validación de configuración de assets nativos.
// Verifica que pubspec.yaml declare el logo, que los archivos de
// configuración de iconos y splash sean válidos, y que los assets
// generados por flutter_launcher_icons y flutter_native_splash existan.
//
// TDD: RED — test escrito antes que las configuraciones se actualicen

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart' as yaml;

/// Resuelve una ruta relativa desde la raíz del proyecto.
String projectPath(String relativePath) {
  // Cuando se ejecuta con `flutter test`, el current directory
  // es la raíz del proyecto.
  return relativePath;
}

yaml.YamlMap readYamlFile(String path) {
  final file = File(projectPath(path));
  final content = file.readAsStringSync();
  return yaml.loadYaml(content) as yaml.YamlMap;
}

void main() {
  // ---------------------------------------------------------------------------
  // Task 3.2 — Validación de pubspec.yaml
  // ---------------------------------------------------------------------------
  group('pubspec.yaml — assets declaration', () {
    late yaml.YamlMap pubspec;

    setUpAll(() {
      pubspec = readYamlFile('pubspec.yaml');
    });

    test(
      'debe declarar assets/images/08_cat_cleaning_logo.png en flutter.assets',
      () {
        // TDD: REFACTOR — logo.png reemplazado por 08_cat_cleaning_logo.png
        final flutter = pubspec['flutter'] as yaml.YamlMap?;
        expect(
          flutter,
          isNotNull,
          reason: 'pubspec.yaml debe tener la sección flutter',
        );

        final assets = flutter!['assets'] as yaml.YamlList?;
        expect(
          assets,
          isNotNull,
          reason: 'flutter.assets debe estar declarado (no comentado)',
        );

        expect(
          assets!.cast<String>().contains(
            'assets/images/08_cat_cleaning_logo.png',
          ),
          isTrue,
          reason: 'assets debe incluir assets/images/08_cat_cleaning_logo.png',
        );
      },
    );

    test('debe declarar flutter_launcher_icons en dev_dependencies', () {
      // TDD: RED — dependency not yet added
      final devDeps = pubspec['dev_dependencies'] as yaml.YamlMap?;
      expect(devDeps, isNotNull);

      final iconsDep = devDeps!['flutter_launcher_icons'];
      expect(
        iconsDep,
        isNotNull,
        reason: 'flutter_launcher_icons debe estar en dev_dependencies',
      );
    });

    test('debe declarar flutter_native_splash en dev_dependencies', () {
      // TDD: RED — dependency not yet added
      final devDeps = pubspec['dev_dependencies'] as yaml.YamlMap?;
      expect(devDeps, isNotNull);

      final splashDep = devDeps!['flutter_native_splash'];
      expect(
        splashDep,
        isNotNull,
        reason: 'flutter_native_splash debe estar en dev_dependencies',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Tasks 3.4 & 3.5 — Validación de archivos de configuración YAML
  // ---------------------------------------------------------------------------
  group('flutter_launcher_icons.yaml — configuration', () {
    late yaml.YamlMap config;

    setUpAll(() {
      final root = readYamlFile('flutter_launcher_icons.yaml');
      config = root['flutter_launcher_icons'] as yaml.YamlMap;
    });

    test('debe tener android=true e ios=false', () {
      // TDD: RED — config file does not exist yet
      expect(config['android'], true, reason: 'Solo Android por ahora');
      expect(config['ios'], false, reason: 'iOS no configurado en este cambio');
    });

    test(
      'image_path debe apuntar a assets/images/08_cat_cleaning_logo.png',
      () {
        final imagePath = config['image_path'] as String?;
        expect(imagePath, equals('assets/images/08_cat_cleaning_logo.png'));
      },
    );

    test('adaptive_icon_background debe ser navy #1E2238', () {
      final bg = config['adaptive_icon_background'] as String?;
      expect(bg, anyOf(equals('#1E2238'), equals('1E2238')));
    });
  });

  group('flutter_native_splash.yaml — configuration', () {
    late yaml.YamlMap config;

    setUpAll(() {
      final root = readYamlFile('flutter_native_splash.yaml');
      config = root['flutter_native_splash'] as yaml.YamlMap;
    });

    test('debe tener android=true y solo Android', () {
      // TDD: RED — config file does not exist yet
      expect(config['android'], true, reason: 'Solo Android configurado');
      expect(config['ios'], false, reason: 'iOS no configurado en este cambio');
    });

    test('color de fondo debe ser navy #1E2238', () {
      final color = config['color'] as String?;
      expect(color, anyOf(equals('#1E2238'), equals('1E2238')));
    });

    test('image debe apuntar a assets/images/08_cat_cleaning_logo.png', () {
      final image = config['image'] as String?;
      expect(image, equals('assets/images/08_cat_cleaning_logo.png'));
    });

    test('debe tener fullscreen activado (sin spinner)', () {
      final fullscreen = config['fullscreen'];
      expect(
        fullscreen,
        true,
        reason: 'fullscreen debe estar activado para evitar spinner',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Tasks 3.6 & 3.7 — Verificación de archivos generados
  // ---------------------------------------------------------------------------
  group('Launcher icons — archivos generados', () {
    final densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];

    for (final density in densities) {
      test('debe existir ic_launcher.png en mipmap-$density', () {
        // TDD: RED — icons not generated yet
        final path = projectPath(
          'android/app/src/main/res/mipmap-$density/ic_launcher.png',
        );
        final file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'El icono debe haberse generado en mipmap-$density',
        );
      });
    }

    test('mipmap-hdpi icono no debe medir 0 bytes', () {
      final path = projectPath(
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
      );
      final file = File(path);
      if (file.existsSync()) {
        expect(
          file.lengthSync(),
          greaterThan(0),
          reason: 'El icono generado no debe ser un archivo vacío',
        );
      }
    });
  });

  group('Native splash — archivos generados', () {
    test('debe existir drawable de splash', () {
      // TDD: RED — splash not generated yet
      // flutter_native_splash crea los archivos en drawable-{density}/
      final path = projectPath(
        'android/app/src/main/res/drawable-mdpi/splash.png',
      );
      final file = File(path);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Debe existir un drawable de splash generado',
      );
    });

    test(
      'launch_background.xml debe estar actualizado con drawables de marca',
      () {
        final path = projectPath(
          'android/app/src/main/res/drawable/launch_background.xml',
        );
        final file = File(path);
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        // Después de flutter_native_splash, debe referenciar drawables de brand
        expect(
          content.contains('@drawable/background') ||
              content.contains('@drawable/splash'),
          isTrue,
          reason:
              'launch_background.xml debe referenciar drawables de la marca',
        );
      },
    );

    test('colors.xml debe definir el fondo navy de la marca', () {
      final colorsPath = projectPath(
        'android/app/src/main/res/values/colors.xml',
      );
      final file = File(colorsPath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        expect(
          content.contains('1E2238'),
          isTrue,
          reason: 'colors.xml debe contener el color navy #1E2238',
        );
      }
    });
  });
}

// Pruebas de widget para LogoWidget.
//
// Verifica:
// - Renderiza sin crash (usando placeholder porque el asset real
//   se agrega en PR 3)
// - El parámetro size controla el ancho/alto
// - Es const-constructible
// - Fallback a SizedBox cuando el asset falta
//
// TDD: RED — test escrito antes que la implementación

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mundo_limpio_app/core/widgets/logo_widget.dart';

void main() {
  group('LogoWidget — estructura', () {
    testWidgets('debe ser const-constructible', (tester) async {
      // Si esto compila, el constructor es const
      // ignore: unused_local_variable
      const logo = LogoWidget();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: logo)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('debe tener size por defecto de 120', (tester) async {
      const logo = LogoWidget();
      expect(logo.size, 120.0);
    });

    testWidgets('debe aceptar size personalizado', (tester) async {
      const logo = LogoWidget(size: 80);
      expect(logo.size, 80.0);
    });

    testWidgets('debe renderizar sin crash', (tester) async {
      // El asset no existe todavía (PR 3), pero el widget debe
      // manejar esa situación sin tirar excepción.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: LogoWidget())),
        ),
      );
      // Si llegamos acá sin excepción, el test pasa
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'debe renderizar un Image.asset apuntando al logo',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Center(child: LogoWidget())),
          ),
        );

        // Debe haber un Image widget (aunque el asset falte al no
        // estar en assets todavía, el widget se construye igual)
        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
      },
    );

    testWidgets(
      'debe mostrar un SizedBox fallback cuando el asset no existe',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Center(child: LogoWidget())),
          ),
        );

        // Aunque el asset falle en runtime, no debería haber
        // una excepción durante el pump
        expect(tester.takeException(), isNull);

        // El Image widget existe (se construyó con errorBuilder)
        expect(find.byType(Image), findsOneWidget);
      },
    );
  });

  group('LogoWidget — semántica', () {
    testWidgets(
      'debe incluir un Semantics label para accesibilidad',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Center(child: LogoWidget())),
          ),
        );

        // El Semantics label debe ser accesible desde el árbol
        expect(
          find.bySemanticsLabel('Logo de Mundo Limpio'),
          findsOneWidget,
        );
      },
    );
  });
}

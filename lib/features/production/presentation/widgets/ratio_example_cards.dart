// Widget informativo con ejemplos de conversión de producción.
//
// Muestra 4 cards con ejemplos reales de cómo los ratios de conversión
// determinan la cantidad producida a partir de materias primas.
//
// Uso: insertar entre el título y el formulario en la pantalla
// de creación de batch para orientar al usuario.

import 'package:flutter/material.dart';

/// Tarjetas con ejemplos de conversión de materias primas.
///
/// Cada card muestra: cantidad de materia prima × ratio = cantidad producida.
/// Son informativas y no interactivas.
class RatioExampleCards extends StatelessWidget {
  const RatioExampleCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ejemplos de conversión',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.amber.shade800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildExampleCard(
            icon: Icons.opacity,
            base: '20L Base',
            ratio: '3.0',
            result: '60L Detergente',
          ),
          _buildExampleCard(
            icon: Icons.clean_hands,
            base: '20L Cloro',
            ratio: '4.0',
            result: '80L Lavandina',
          ),
          _buildExampleCard(
            icon: Icons.air,
            base: '1L Esencia',
            ratio: '81.0',
            result: '81L Desodorante',
          ),
          _buildExampleCard(
            icon: Icons.soap,
            base: '160L Jabón Base',
            ratio: '1.0',
            result: '160L Jabón',
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard({
    required IconData icon,
    required String base,
    required String ratio,
    required String result,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: base,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const TextSpan(text: ' × '),
                    TextSpan(
                      text: ratio,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const TextSpan(text: '  →  '),
                    TextSpan(
                      text: result,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

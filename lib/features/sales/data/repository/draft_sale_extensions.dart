// Extensión de DraftSale para conversión a SaleRequest.
//
// Agrega toRequest() al tipo generado DraftSale de Drift
// para poder enviar un borrador al backend al confirmarlo.
//
// TDD: GREEN — implementación mínima para pasar draft_sale_extensions_test.dart

import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';

/// Extensión que permite convertir un [DraftSale] en un [SaleRequest].
extension DraftSaleToRequest on DraftSale {
  /// Convierte este borrador en un request para la API de ventas.
  ///
  /// Toma [productId] y [quantity] del borrador.
  SaleRequest toRequest() => SaleRequest(
        productId: productId,
        quantity: quantity,
      );
}

// Modelo DTO para la respuesta de productos del backend.
//
// Contiene los datos mínimos necesarios para el selector
// de productos en el formulario de venta.
//
// TDD: GREEN — implementación mínima para pasar los tests

/// Respuesta del backend con los datos básicos de un producto.
///
/// Mapea el JSON del endpoint:
/// - `GET /api/v1/products`
class ProductResponse {
  /// ID único del producto.
  final int id;

  /// Nombre del producto.
  final String name;

  /// Crea un [ProductResponse] con todos los campos requeridos.
  const ProductResponse({
    required this.id,
    required this.name,
  });

  /// Construye un [ProductResponse] desde un mapa JSON.
  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

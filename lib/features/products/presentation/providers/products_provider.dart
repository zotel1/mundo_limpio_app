// Provider de estado para la gestión de productos (admin CRUD).
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Expone el estado de operaciones CRUD sobre Product como ChangeNotifier
// para que los widgets se reconstruyan reactivamente.
//
// Estados posibles:
// - initial: estado inicial, sin operaciones
// - loading: operación en progreso
// - loaded: operación exitosa con datos
// - error: operación fallida con mensaje de error

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/network/error_handler.dart';
import 'package:mundo_limpio_app/features/products/domain/entities/product.dart';
import 'package:mundo_limpio_app/features/products/domain/repositories/i_products_repository.dart';

/// Estados posibles del flujo de Productos.
///
/// - [initial]: estado inicial, sin operaciones realizadas
/// - [loading]: mientras se ejecuta una operación
/// - [loaded]: operación exitosa con datos disponibles
/// - [error]: operación fallida con mensaje de error
enum ProductStatus { initial, loading, loaded, error }

/// Provider de estado para Productos (admin CRUD).
///
/// Usa [IProductsRepository] para las operaciones CRUD
/// y expone el estado via ChangeNotifier para la UI reactiva.
///
/// Cada método:
/// 1. Setea loading y notifica
/// 2. Ejecuta la operación (try)
/// 3. Setea status/error y notifica
class ProductsProvider extends ChangeNotifier {
  final IProductsRepository _repository;
  final CancelToken _cancelToken;

  ProductStatus _status = ProductStatus.initial;
  String? _error;
  List<Product> _products = [];
  Product? _currentProduct;

  /// Estado actual de las operaciones.
  ProductStatus get status => _status;

  /// Mensaje de error actual (null si no hay error).
  String? get error => _error;

  /// True mientras se está procesando una operación.
  bool get isLoading => _status == ProductStatus.loading;

  /// Lista de productos.
  ///
  /// Retorna una copia inmutable para evitar mutaciones externas.
  List<Product> get products => List.unmodifiable(_products);

  /// Producto actual (cargado via loadProduct, reactivateProduct).
  Product? get currentProduct => _currentProduct;

  /// Crea un [ProductsProvider] con el [repository] inyectado.
  ProductsProvider(this._repository, {CancelToken? cancelToken})
    : _cancelToken = cancelToken ?? CancelToken();

  /// Obtiene todos los productos activos.
  ///
  /// En caso de éxito: status = loaded, products = lista obtenida.
  /// En caso de error: status = error con mensaje descriptivo.
  Future<void> loadProducts() async {
    _setLoading();
    try {
      _products = await _repository.getAll(cancelToken: _cancelToken);
      _status = ProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = ProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = ProductStatus.error;
    }
    notifyListeners();
  }

  /// Obtiene todos los productos (activos e inactivos).
  Future<void> loadAllProducts() async {
    _setLoading();
    try {
      _products = await _repository.getAllProducts(cancelToken: _cancelToken);
      _status = ProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = ProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = ProductStatus.error;
    }
    notifyListeners();
  }

  /// Obtiene un producto por su ID y lo setea como currentProduct.
  Future<void> loadProduct(int id) async {
    _setLoading();
    try {
      _currentProduct = await _repository.getById(
        id,
        cancelToken: _cancelToken,
      );
      _status = ProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = ProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = ProductStatus.error;
    }
    notifyListeners();
  }

  /// Crea un nuevo producto.
  Future<void> createProduct(Product product) async {
    _setLoading();
    try {
      await _repository.create(product, cancelToken: _cancelToken);
      _status = ProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = ProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = ProductStatus.error;
    }
    notifyListeners();
  }

  /// Actualiza un producto existente.
  Future<void> updateProduct(Product product) async {
    _setLoading();
    try {
      await _repository.update(product, cancelToken: _cancelToken);
      _status = ProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = ProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = ProductStatus.error;
    }
    notifyListeners();
  }

  /// Elimina (soft-delete) un producto por su [id].
  Future<void> deleteProduct(int id) async {
    // Remover de la lista local primero para que Dismissible
    // desaparezca del árbol inmediatamente.
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
    _setLoading();
    try {
      await _repository.delete(id, cancelToken: _cancelToken);
      _status = ProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = ProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = ProductStatus.error;
    }
    notifyListeners();
  }

  /// Reactiva un producto previamente eliminado.
  Future<void> reactivateProduct(int id) async {
    _setLoading();
    try {
      _currentProduct = await _repository.reactivate(
        id,
        cancelToken: _cancelToken,
      );
      _status = ProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = ProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = ProductStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelToken.cancel('dispose');
    super.dispose();
  }

  /// Setea estado a loading y notifica.
  void _setLoading() {
    _status = ProductStatus.loading;
    notifyListeners();
  }
}

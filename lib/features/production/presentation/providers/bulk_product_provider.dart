// Provider de estado para la gestión de productos a granel (Bulk Products).
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Expone el estado de operaciones CRUD sobre BulkProducts como ChangeNotifier
// para que los widgets se reconstruyan reactivamente.
//
// Estados posibles:
// - initial: estado inicial, sin operaciones
// - loading: operación en progreso
// - loaded: operación exitosa con datos
// - error: operación fallida con mensaje de error

import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/core/network/error_handler.dart';
import 'package:mundo_limpio_app/features/production/domain/entities/bulk_product.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_bulk_product_repository.dart';

/// Estados posibles del flujo de Bulk Products.
///
/// - [initial]: estado inicial, sin operaciones realizadas
/// - [loading]: mientras se ejecuta una operación
/// - [loaded]: operación exitosa con datos disponibles
/// - [error]: operación fallida con mensaje de error
enum BulkProductStatus { initial, loading, loaded, error }

/// Provider de estado para Bulk Products.
///
/// Usa [IBulkProductRepository] para las operaciones CRUD
/// y expone el estado via ChangeNotifier para la UI reactiva.
///
/// Cada método:
/// 1. Setea loading y notifica
/// 2. Ejecuta la operación (try)
/// 3. Setea status/error y notifica
class BulkProductProvider extends ChangeNotifier {
  final IBulkProductRepository _repository;

  BulkProductStatus _status = BulkProductStatus.initial;
  String? _error;
  List<BulkProduct> _bulkProducts = [];

  /// Estado actual de las operaciones.
  BulkProductStatus get status => _status;

  /// Mensaje de error actual (null si no hay error).
  String? get error => _error;

  /// True mientras se está procesando una operación.
  bool get isLoading => _status == BulkProductStatus.loading;

  /// Lista de productos a granel.
  ///
  /// Retorna una copia inmutable para evitar mutaciones externas.
  List<BulkProduct> get bulkProducts => List.unmodifiable(_bulkProducts);

  /// Crea un [BulkProductProvider] con el [repository] inyectado.
  BulkProductProvider(this._repository);

  /// Obtiene todos los productos a granel.
  ///
  /// En caso de éxito: status = loaded, bulkProducts = lista obtenida.
  /// En caso de error: status = error con mensaje descriptivo.
  Future<void> getBulkProducts() async {
    _setLoading();
    try {
      _bulkProducts = await _repository.getBulkProducts();
      _status = BulkProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = BulkProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = BulkProductStatus.error;
    }
    notifyListeners();
  }

  /// Crea un nuevo producto a granel.
  ///
  /// En caso de éxito: status = loaded.
  /// En caso de error: status = error con mensaje descriptivo.
  Future<void> createBulkProduct(BulkProduct product) async {
    _setLoading();
    try {
      await _repository.createBulkProduct(product);
      _status = BulkProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = BulkProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = BulkProductStatus.error;
    }
    notifyListeners();
  }

  /// Actualiza un producto a granel existente.
  ///
  /// En caso de éxito: status = loaded.
  /// En caso de error: status = error con mensaje descriptivo.
  Future<void> updateBulkProduct(BulkProduct product) async {
    _setLoading();
    try {
      await _repository.updateBulkProduct(product);
      _status = BulkProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = BulkProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = BulkProductStatus.error;
    }
    notifyListeners();
  }

  /// Elimina un producto a granel por su [id].
  ///
  /// En caso de éxito: status = loaded.
  /// En caso de error: status = error con mensaje descriptivo.
  Future<void> deleteBulkProduct(int id) async {
    _setLoading();
    try {
      await _repository.deleteBulkProduct(id);
      _status = BulkProductStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = BulkProductStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = BulkProductStatus.error;
    }
    notifyListeners();
  }

  /// Setea estado a loading y notifica.
  void _setLoading() {
    _status = BulkProductStatus.loading;
    notifyListeners();
  }
}

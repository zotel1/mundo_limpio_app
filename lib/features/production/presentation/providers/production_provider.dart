// Provider de estado para la gestión de lotes de producción.
//
// TDD: GREEN — implementación mínima para pasar los tests
//
// Expone el estado de operaciones sobre ProductionBatches como ChangeNotifier
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
import 'package:mundo_limpio_app/features/production/domain/entities/production_batch.dart';
import 'package:mundo_limpio_app/features/production/domain/repositories/i_production_repository.dart';

/// Estados posibles del flujo de Production Batches.
///
/// - [initial]: estado inicial, sin operaciones realizadas
/// - [loading]: mientras se ejecuta una operación
/// - [loaded]: operación exitosa con datos disponibles
/// - [error]: operación fallida con mensaje de error
enum ProductionStatus { initial, loading, loaded, error }

/// Provider de estado para Production Batches.
///
/// Usa [IProductionRepository] para las operaciones
/// y expone el estado via ChangeNotifier para la UI reactiva.
///
/// Cada método:
/// 1. Setea loading y notifica
/// 2. Ejecuta la operación (try)
/// 3. Setea status/error y notifica
class ProductionProvider extends ChangeNotifier {
  final IProductionRepository _repository;

  ProductionStatus _status = ProductionStatus.initial;
  String? _error;
  List<ProductionBatch> _productionBatches = [];
  ProductionBatch? _lastCreatedBatch;

  /// Estado actual de las operaciones.
  ProductionStatus get status => _status;

  /// Mensaje de error actual (null si no hay error).
  String? get error => _error;

  /// True mientras se está procesando una operación.
  bool get isLoading => _status == ProductionStatus.loading;

  /// Lista de lotes de producción.
  ///
  /// Retorna una copia inmutable para evitar mutaciones externas.
  List<ProductionBatch> get productionBatches =>
      List.unmodifiable(_productionBatches);

  /// Último lote de producción creado (null si no se ha creado ninguno).
  ProductionBatch? get lastCreatedBatch => _lastCreatedBatch;

  /// Crea un [ProductionProvider] con el [repository] inyectado.
  ProductionProvider(this._repository);

  /// Obtiene todos los lotes de producción.
  ///
  /// En caso de éxito: status = loaded, productionBatches = lista obtenida.
  /// En caso de error: status = error con mensaje descriptivo.
  Future<void> getProductionBatches() async {
    _setLoading();
    try {
      _productionBatches = await _repository.getProductionBatches();
      _status = ProductionStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = ProductionStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = ProductionStatus.error;
    }
    notifyListeners();
  }

  /// Crea un nuevo lote de producción.
  ///
  /// En caso de éxito: status = loaded, lastCreatedBatch = batch creado.
  /// En caso de error: status = error con mensaje descriptivo.
  Future<void> createProductionBatch(ProductionBatchRequest request) async {
    _setLoading();
    try {
      _lastCreatedBatch = await _repository.createProductionBatch(request);
      _status = ProductionStatus.loaded;
      _error = null;
    } on ApiException catch (e) {
      _error = ErrorHandler.getMessage(e);
      _status = ProductionStatus.error;
    } catch (e) {
      _error = 'Error inesperado. Intentalo de nuevo.';
      _status = ProductionStatus.error;
    }
    notifyListeners();
  }

  /// Setea estado a loading y notifica.
  void _setLoading() {
    _status = ProductionStatus.loading;
    notifyListeners();
  }
}

// Provider de Inventario con ChangeNotifier y máquina de estados.
//
// Gestiona el estado de las operaciones de inventario:
// - loadInventory: consulta stock de un producto
// - loadLowStock: consulta productos con stock bajo
// - adjustStock: ajusta el stock de un producto
// - reset: limpia el estado
//
// La UI reacciona a los cambios vía context.watch() y
// renderiza según el estado actual con un switch().
//
// Estados:
// - idle: estado inicial, sin operación en curso
// - loading: operación en progreso (mostrar spinner)
// - inventoryLoaded: loadInventory completado
// - lowStockLoaded: loadLowStock completado
// - success: adjustStock completado
// - error: operación falló (mostrar mensaje de error)
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/inventory/domain/entities/adjustment.dart';
import 'package:mundo_limpio_app/features/inventory/domain/entities/stock_item.dart';
import 'package:mundo_limpio_app/features/inventory/domain/repository/inventory_repository.dart';

/// Estados posibles del [InventoryProvider].
///
/// Usar switch() en build() de la UI para renderizar
/// el widget correspondiente a cada estado:
/// - `idle` → pantalla vacía / vista inicial
/// - `loading` → CircularProgressIndicator
/// - `inventoryLoaded` → InventoryDetailScreen
/// - `lowStockLoaded` → InventoryListScreen
/// - `success` → feedback de ajuste exitoso
/// - `error` → mensaje de error con botón reintentar
enum InventoryStatus {
  idle,
  loading,
  inventoryLoaded,
  lowStockLoaded,
  success,
  error,
}

/// Provider de Inventario.
///
/// Inyectar [InventoryRepository] vía constructor.
/// Escuchar cambios con `context.watch<InventoryProvider>()`.
/// Disparar acciones con `context.read<InventoryProvider>().metodo()`.
class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;

  // ─── Estado interno ──────────────────────────────────
  InventoryStatus _status = InventoryStatus.idle;
  StockItem? _currentInventory;
  List<StockItem> _lowStockItems = [];
  StockItem? _lastAdjustment;
  String? _errorMessage;

  // ─── Getters públicos ────────────────────────────────

  /// Estado actual del provider.
  InventoryStatus get status => _status;

  /// Último inventario cargado via [loadInventory].
  StockItem? get currentInventory => _currentInventory;

  /// Lista de productos con stock bajo.
  List<StockItem> get lowStockItems => _lowStockItems;

  /// Respuesta del último ajuste exitoso.
  StockItem? get lastAdjustment => _lastAdjustment;

  /// Mensaje de error de la última operación fallida.
  String? get errorMessage => _errorMessage;

  /// Crea un [InventoryProvider] con el repositorio inyectado.
  ///
  /// [repository]: implementación de [InventoryRepository].
  InventoryProvider({required InventoryRepository repository})
    : _repository = repository;

  // ─── Acciones ────────────────────────────────────────

  /// Consulta el stock de un producto por ID.
  ///
  /// Transición: idle → loading → inventoryLoaded | error
  Future<void> loadInventory(int productId) async {
    _status = InventoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentInventory = await _repository.getInventory(productId);
      _status = InventoryStatus.inventoryLoaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = InventoryStatus.error;
    }

    notifyListeners();
  }

  /// Consulta la lista de productos con stock bajo.
  ///
  /// Transición: idle → loading → lowStockLoaded | error
  Future<void> loadLowStock() async {
    _status = InventoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _lowStockItems = await _repository.getLowStock();
      _status = InventoryStatus.lowStockLoaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = InventoryStatus.error;
    }

    notifyListeners();
  }

  /// Ajusta el stock de un producto.
  ///
  /// Transición: → loading → success | error
  Future<void> adjustStock(int productId, Adjustment request) async {
    _status = InventoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastAdjustment = await _repository.adjustStock(productId, request);
      _status = InventoryStatus.success;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = InventoryStatus.error;
    }

    notifyListeners();
  }

  @override
  // ignore: unnecessary_overrides
  void dispose() {
    super.dispose();
  }

  /// Resetea el estado a idle, limpiando datos y errores.
  ///
  /// Útil después de mostrar un error para volver
  /// al estado inicial.
  void reset() {
    _status = InventoryStatus.idle;
    _errorMessage = null;
    _currentInventory = null;
    _lowStockItems = [];
    _lastAdjustment = null;
    notifyListeners();
  }
}

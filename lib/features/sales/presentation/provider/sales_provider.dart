// Provider del flujo de creación de venta.
//
// Maneja 6 estados explícitos (SalesStatus) que cubren todo
// el ciclo de vida: cargar productos → consultar stock → crear venta.
//
// Estados:
//   idle ──loadProducts()──→ loading ──→ productsLoaded ──loadStock(id)──→ loading ──→ stockLoaded
//   stockLoaded ──createSale(qty)──→ loading ──→ success ──reset()──→ idle
//   Cualquier error ──→ error ──clearError()──→ idle
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/sales/data/models/product_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/production_batch_response.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_request.dart';
import 'package:mundo_limpio_app/features/sales/data/models/sale_response.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';

/// Estados posibles del flujo de creación de venta.
///
/// - [idle]: estado inicial o después de reset/clearError
/// - [loading]: operación en curso (carga de productos, stock o creación)
/// - [productsLoaded]: productos cargados exitosamente, listo para seleccionar
/// - [stockLoaded]: lotes del producto cargados, listo para crear venta
/// - [success]: venta creada exitosamente
/// - [error]: ocurrió un error en cualquier operación
enum SalesStatus { idle, loading, productsLoaded, stockLoaded, success, error }

/// Provider del flujo de creación de venta.
///
/// Implementa una máquina de estados de 6 estados para guiar la UI
/// a través del proceso completo: cargar productos, seleccionar producto,
/// verificar stock y crear la venta.
///
/// Cada método sigue el patrón:
/// 1. Actualiza estado y notifica
/// 2. Ejecuta operación asíncrona
/// 3. Actualiza estado/error y notifica
class SalesProvider extends ChangeNotifier {
  final SalesRepository _repository;

  SalesStatus _status = SalesStatus.idle;
  List<ProductResponse> _products = [];
  List<ProductionBatchResponse> _batches = [];
  int? _selectedProductId;
  String? _errorMessage;
  SaleResponse? _lastSale;

  /// Estado actual del flujo de venta.
  SalesStatus get status => _status;

  /// Lista de productos disponibles.
  List<ProductResponse> get products => _products;

  /// Lista de lotes del producto seleccionado.
  List<ProductionBatchResponse> get batches => _batches;

  /// ID del producto seleccionado (null si no hay selección).
  int? get selectedProductId => _selectedProductId;

  /// Mensaje de error actual (null si no hay error).
  String? get errorMessage => _errorMessage;

  /// Última venta creada (null si no hay venta).
  SaleResponse? get lastSale => _lastSale;

  /// Crea un [SalesProvider] con el [repository] inyectado.
  SalesProvider(this._repository);

  /// Carga la lista de productos desde el repositorio.
  ///
  /// Transición: idle/productsLoaded/stockLoaded/success → loading → productsLoaded | error
  /// Limpia [errorMessage] antes de comenzar.
  Future<void> loadProducts() async {
    _setLoading();
    _errorMessage = null;
    try {
      _products = await _repository.getProducts();
      _status = SalesStatus.productsLoaded;
    } on ApiException catch (e) {
      _status = SalesStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = SalesStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Carga los lotes de producción de un producto.
  ///
  /// [productId]: ID del producto a consultar.
  /// Setea [selectedProductId] inmediatamente.
  /// Transición: cualquier estado → loading → stockLoaded | error
  Future<void> loadStock(int productId) async {
    _setLoading();
    _selectedProductId = productId;
    try {
      _batches = await _repository.getBatchesByProduct(productId);
      _status = SalesStatus.stockLoaded;
    } on ApiException catch (e) {
      _status = SalesStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = SalesStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Crea una nueva venta con la [quantity] especificada.
  ///
  /// Requiere [selectedProductId] seteado y status [SalesStatus.stockLoaded].
  /// Si no se cumplen las precondiciones, la operación se ignora.
  /// Transición: stockLoaded → loading → success | error
  Future<void> createSale(double quantity) async {
    if (_status != SalesStatus.stockLoaded || _selectedProductId == null) {
      return;
    }
    _setLoading();
    try {
      final request = SaleRequest(
        productId: _selectedProductId!,
        quantity: quantity,
      );
      _lastSale = await _repository.createSale(request);
      _status = SalesStatus.success;
    } on ApiException catch (e) {
      _status = SalesStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = SalesStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Resetea todos los campos al estado inicial.
  ///
  /// Transición: cualquier estado → idle
  void reset() {
    _status = SalesStatus.idle;
    _products = [];
    _batches = [];
    _selectedProductId = null;
    _errorMessage = null;
    _lastSale = null;
    notifyListeners();
  }

  /// Limpia el mensaje de error y vuelve a idle.
  ///
  /// Transición: error → idle
  void clearError() {
    _status = SalesStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Setea estado a loading y notifica.
  void _setLoading() {
    _status = SalesStatus.loading;
    notifyListeners();
  }
}

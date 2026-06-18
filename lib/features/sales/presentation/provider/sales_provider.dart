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
// También expone métodos para borradores offline:
// - loadDrafts(): carga los borradores pendientes
// - confirmDraft(id): confirma un borrador al reconectar
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/drift/app_database.dart';
import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/batch_info.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/create_sale_data.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/product_info.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/sale.dart';
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
  List<ProductInfo> _products = [];
  List<BatchInfo> _batches = [];
  List<DraftSale> _drafts = [];
  int? _selectedProductId;
  String? _errorMessage;
  Sale? _lastSale;

  /// Estado actual del flujo de venta.
  SalesStatus get status => _status;

  /// Lista de productos disponibles.
  List<ProductInfo> get products => _products;

  /// Lista de lotes del producto seleccionado.
  List<BatchInfo> get batches => _batches;

  /// ID del producto seleccionado (null si no hay selección).
  int? get selectedProductId => _selectedProductId;

  /// Mensaje de error actual (null si no hay error).
  String? get errorMessage => _errorMessage;

  /// Stock total disponible sumando todos los lotes.
  ///
  /// Retorna 0.0 si no hay lotes cargados.
  double get stockTotal =>
      _batches.fold<double>(0, (sum, batch) => sum + batch.quantity);

  /// Última venta creada (null si no hay venta).
  Sale? get lastSale => _lastSale;

  /// Lista de borradores de ventas offline pendientes de confirmar.
  List<DraftSale> get drafts => _drafts;

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
      final data = CreateSaleData(
        productId: _selectedProductId!,
        quantity: quantity,
      );
      _lastSale = await _repository.createSale(data);
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
    _drafts = [];
    _selectedProductId = null;
    _errorMessage = null;
    _lastSale = null;
    notifyListeners();
  }

  /// Carga los borradores de ventas offline pendientes de confirmar.
  ///
  /// Transición: idle → loading → idle | error
  Future<void> loadDrafts() async {
    _setLoading();
    try {
      _drafts = await _repository.getDrafts();
      _status = SalesStatus.idle;
    } on ApiException catch (e) {
      _status = SalesStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = SalesStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Confirma un borrador enviándolo al backend.
  ///
  /// [draftId]: ID del borrador a confirmar.
  /// Transición: idle → loading → success | error
  Future<void> confirmDraft(int draftId) async {
    _setLoading();
    try {
      _lastSale = await _repository.confirmDraft(draftId);
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

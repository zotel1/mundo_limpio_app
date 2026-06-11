// Provider del historial de ventas (GET endpoints).
//
// Maneja 4 estados explícitos (SalesHistoryStatus) para cubrir
// la carga de lista y detalle de ventas desde el backend.
// Es un provider read-only: no crea ni modifica ventas.
//
// Estados:
//   idle ──loadSales()──→ loading ──→ success | error
//   idle ──loadSaleById(id)──→ loading ──→ success | error
//   error ──clearError()──→ idle
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/sales/domain/entities/sale.dart';
import 'package:mundo_limpio_app/features/sales/domain/repository/sales_repository.dart';

/// Estados posibles del historial de ventas.
///
/// - [idle]: estado inicial o después de clearError
/// - [loading]: operación en curso
/// - [success]: datos cargados exitosamente
/// - [error]: ocurrió un error en la operación
enum SalesHistoryStatus { idle, loading, success, error }

/// Provider del historial de ventas (consulta GET).
///
/// Implementa una máquina de estados de 4 estados para listar ventas
/// y ver el detalle de una venta específica.
///
/// Cada método sigue el patrón:
/// 1. Actualiza estado y notifica
/// 2. Ejecuta operación asíncrona
/// 3. Actualiza estado/error y notifica
class SalesHistoryProvider extends ChangeNotifier {
  final SalesRepository _repository;
  final CancelToken _cancelToken;

  SalesHistoryStatus _status = SalesHistoryStatus.idle;
  List<Sale> _sales = [];
  Sale? _selectedSale;
  String? _errorMessage;

  /// Estado actual del historial de ventas.
  SalesHistoryStatus get status => _status;

  /// Lista de ventas cargadas desde el backend.
  List<Sale> get sales => _sales;

  /// Venta seleccionada para ver detalle (null si no hay selección).
  Sale? get selectedSale => _selectedSale;

  /// Mensaje de error actual (null si no hay error).
  String? get errorMessage => _errorMessage;

  /// Crea un [SalesHistoryProvider] con el [repository] inyectado.
  SalesHistoryProvider(this._repository, {CancelToken? cancelToken})
    : _cancelToken = cancelToken ?? CancelToken();

  /// Carga la lista de ventas desde el backend.
  ///
  /// Transición: idle → loading → success | error
  /// Limpia [errorMessage] antes de comenzar.
  Future<void> loadSales() async {
    _setLoading();
    _errorMessage = null;
    try {
      _sales = await _repository.getSales(cancelToken: _cancelToken);
      _status = SalesHistoryStatus.success;
    } on ApiException catch (e) {
      _status = SalesHistoryStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = SalesHistoryStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Carga el detalle de una venta por su ID.
  ///
  /// [id]: ID de la venta a consultar.
  /// Transición: idle → loading → success | error
  Future<void> loadSaleById(int id) async {
    _setLoading();
    try {
      _selectedSale = await _repository.getSaleById(
        id,
        cancelToken: _cancelToken,
      );
      _status = SalesHistoryStatus.success;
    } on ApiException catch (e) {
      _status = SalesHistoryStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = SalesHistoryStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelToken.cancel('dispose');
    super.dispose();
  }

  /// Limpia el mensaje de error y vuelve a idle.
  ///
  /// Transición: error → idle
  void clearError() {
    _status = SalesHistoryStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Setea estado a loading y notifica.
  void _setLoading() {
    _status = SalesHistoryStatus.loading;
    notifyListeners();
  }
}

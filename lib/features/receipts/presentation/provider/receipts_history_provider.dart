// Provider del historial de recibos (GET endpoints).
//
// Maneja 4 estados explícitos (ReceiptsHistoryStatus) para cubrir
// la carga de lista y detalle de compras desde el backend.
// Es un provider read-only: no crea ni modifica compras.
//
// Estados:
//   idle ──loadReceipts()──→ loading ──→ success | error
//   idle ──loadReceiptById(id)──→ loading ──→ success | error
//   error ──clearError()──→ idle
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/purchase_response.dart';
import 'package:mundo_limpio_app/features/receipts/domain/repository/receipts_repository.dart';

/// Estados posibles del historial de recibos.
///
/// - [idle]: estado inicial o después de clearError
/// - [loading]: operación en curso
/// - [success]: datos cargados exitosamente
/// - [error]: ocurrió un error en la operación
enum ReceiptsHistoryStatus { idle, loading, success, error }

/// Provider del historial de recibos (consulta GET).
///
/// Implementa una máquina de estados de 4 estados para listar compras
/// y ver el detalle de una compra específica.
///
/// Cada método sigue el patrón:
/// 1. Actualiza estado y notifica
/// 2. Ejecuta operación asíncrona
/// 3. Actualiza estado/error y notifica
class ReceiptsHistoryProvider extends ChangeNotifier {
  final ReceiptsRepository _repository;

  ReceiptsHistoryStatus _status = ReceiptsHistoryStatus.idle;
  List<PurchaseResponse> _receipts = [];
  PurchaseResponse? _selectedReceipt;
  String? _errorMessage;

  /// Estado actual del historial de recibos.
  ReceiptsHistoryStatus get status => _status;

  /// Lista de compras cargadas desde el backend.
  List<PurchaseResponse> get receipts => _receipts;

  /// Compra seleccionada para ver detalle (null si no hay selección).
  PurchaseResponse? get selectedReceipt => _selectedReceipt;

  /// Mensaje de error actual (null si no hay error).
  String? get errorMessage => _errorMessage;

  /// Crea un [ReceiptsHistoryProvider] con el [repository] inyectado.
  ReceiptsHistoryProvider(this._repository);

  /// Carga la lista de compras desde el backend.
  ///
  /// Transición: idle → loading → success | error
  /// Limpia [errorMessage] antes de comenzar.
  Future<void> loadReceipts() async {
    _setLoading();
    _errorMessage = null;
    try {
      _receipts = await _repository.getReceipts();
      _status = ReceiptsHistoryStatus.success;
    } on ApiException catch (e) {
      _status = ReceiptsHistoryStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = ReceiptsHistoryStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Carga el detalle de una compra por su ID.
  ///
  /// [id]: ID de la compra a consultar.
  /// Transición: idle → loading → success | error
  Future<void> loadReceiptById(int id) async {
    _setLoading();
    try {
      _selectedReceipt = await _repository.getReceiptById(id);
      _status = ReceiptsHistoryStatus.success;
    } on ApiException catch (e) {
      _status = ReceiptsHistoryStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = ReceiptsHistoryStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Limpia el mensaje de error y vuelve a idle.
  ///
  /// Transición: error → idle
  void clearError() {
    _status = ReceiptsHistoryStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Setea estado a loading y notifica.
  void _setLoading() {
    _status = ReceiptsHistoryStatus.loading;
    notifyListeners();
  }
}

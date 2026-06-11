// Provider del flujo de escaneo OCR de recibos.
//
// Maneja 7 estados explícitos (ReceiptsStatus) que cubren todo
// el ciclo de vida: seleccionar imagen → procesar OCR → revisar → confirmar.
//
// Estados:
//   idle ──selectImage(path)──→ imageSelected
//     ↑                              │
//     ├──resetImage()────────────────┘
//     │
//   imageSelected ──processReceipt()──→ processing
//                                         │
//                            success ────┴──── error
//                                │              │
//                        processSuccess        error
//                                │              │
//                confirmReceipt(req)    clearError()─→ idle
//                                │      selectImage()─→ imageSelected
//                   success ────┴── error
//                       │             │
//                  confirmed         error
//                       │
//   └──reset()─────────┘
//
// error ──selectImage(path)──→ imageSelected  (retake photo)
// confirmed ──reset()──→ idle  (start fresh)
//
// TDD: GREEN — implementación mínima para pasar los tests

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:mundo_limpio_app/core/network/api_exception.dart';
import 'package:mundo_limpio_app/features/receipts/data/models/receipt_confirm_request.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/purchase.dart';
import 'package:mundo_limpio_app/features/receipts/domain/entities/receipt.dart';
import 'package:mundo_limpio_app/features/receipts/domain/repository/receipts_repository.dart';

/// Estados posibles del flujo de escaneo OCR de recibos.
///
/// - [idle]: estado inicial o después de reset/clearError
/// - [imageSelected]: imagen seleccionada, lista para procesar
/// - [processing]: OCR en curso (upload + procesamiento)
/// - [processSuccess]: OCR completado, datos listos para revisar
/// - [confirming]: confirmación en curso
/// - [confirmed]: compra confirmada exitosamente
/// - [error]: ocurrió un error en cualquier operación
enum ReceiptsStatus {
  idle,
  imageSelected,
  processing,
  processSuccess,
  confirming,
  confirmed,
  error,
}

/// Provider del flujo de escaneo OCR de recibos.
///
/// Implementa una máquina de estados de 7 estados para guiar la UI
/// a través del proceso completo: capturar imagen, procesar OCR,
/// revisar resultados y confirmar la compra.
///
/// ADMIN-only, always-online — sin lógica offline/drafts.
///
/// Cada método sigue el patrón:
/// 1. Actualiza estado y notifica
/// 2. Ejecuta operación asíncrona (si aplica)
/// 3. Actualiza estado/error y notifica
class ReceiptsProvider extends ChangeNotifier {
  final ReceiptsRepository _repository;
  final CancelToken _cancelToken;

  ReceiptsStatus _status = ReceiptsStatus.idle;
  Receipt? _processResponse;
  Purchase? _purchaseResponse;
  String? _selectedImagePath;
  String? _errorMessage;

  /// Estado actual del flujo de escaneo.
  ReceiptsStatus get status => _status;

  /// Resultado del procesamiento OCR (null si no se ha procesado).
  Receipt? get processResponse => _processResponse;

  /// Resultado de la compra confirmada (null si no se ha confirmado).
  Purchase? get purchaseResponse => _purchaseResponse;

  /// Ruta local de la imagen seleccionada (null si no hay selección).
  String? get selectedImagePath => _selectedImagePath;

  /// Mensaje de error actual (null si no hay error).
  String? get errorMessage => _errorMessage;

  /// Crea un [ReceiptsProvider] con el [repository] inyectado.
  ReceiptsProvider(this._repository, {CancelToken? cancelToken})
    : _cancelToken = cancelToken ?? CancelToken();

  /// Selecciona una imagen de la galería o cámara.
  ///
  /// [path]: ruta local del archivo de imagen.
  /// Precondición: idle o error
  /// Transición: → imageSelected, limpia errorMessage
  void selectImage(String path) {
    _selectedImagePath = path;
    _errorMessage = null;
    _status = ReceiptsStatus.imageSelected;
    notifyListeners();
  }

  /// Descarta la imagen seleccionada y vuelve a idle.
  ///
  /// Precondición: imageSelected o error
  /// Transición: → idle, limpia imagePath y errorMessage
  void resetImage() {
    _selectedImagePath = null;
    _errorMessage = null;
    _status = ReceiptsStatus.idle;
    notifyListeners();
  }

  /// Sube la imagen para procesamiento OCR.
  ///
  /// Precondición: imageSelected (imagePath no null)
  /// Transición: imageSelected → processing → processSuccess | error
  Future<void> processReceipt() async {
    if (_selectedImagePath == null) return;
    _setStatus(ReceiptsStatus.processing);
    try {
      _processResponse = await _repository.processReceipt(
        _selectedImagePath!,
        cancelToken: _cancelToken,
      );
      _status = ReceiptsStatus.processSuccess;
    } on ApiException catch (e) {
      _status = ReceiptsStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = ReceiptsStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Confirma la compra revisada para persistir en el backend.
  ///
  /// [request]: datos revisados de la compra a confirmar.
  /// Precondición: processSuccess
  /// Transición: processSuccess → confirming → confirmed | error
  Future<void> confirmReceipt(ReceiptConfirmRequest request) async {
    if (_status != ReceiptsStatus.processSuccess) return;
    _setStatus(ReceiptsStatus.confirming);
    try {
      _purchaseResponse = await _repository.confirmReceipt(
        request,
        cancelToken: _cancelToken,
      );
      _status = ReceiptsStatus.confirmed;
    } on ApiException catch (e) {
      _status = ReceiptsStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = ReceiptsStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelToken.cancel('dispose');
    super.dispose();
  }

  /// Resetea todos los campos al estado inicial.
  ///
  /// Transición: cualquier estado → idle
  void reset() {
    _status = ReceiptsStatus.idle;
    _processResponse = null;
    _purchaseResponse = null;
    _selectedImagePath = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia el mensaje de error y vuelve a idle.
  ///
  /// Transición: error → idle
  void clearError() {
    _status = ReceiptsStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Setea estado y notifica listeners.
  void _setStatus(ReceiptsStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import 'qr_scan_screen.dart';

/// The real camera for the QR scanner (KLD-052, KLD-080): package
/// `flutter_zxing`, i.e. zxing-cpp (Apache-2.0) via Dart FFI on the frames of
/// the official `camera` plugin (CameraX on Android, AVFoundation on iOS). No
/// proprietary barcode engine (ML Kit, Apple Vision) is involved. QR codes
/// only. Not used on the web: FFI does not exist there, and the web build
/// shows no scan button.
///
/// The preview is flutter_zxing's [ReaderWidget] with all of its own buttons
/// and overlays switched off; the scanner screen draws the viewfinder, torch
/// and messages itself (see [state]).
class MobileQrScanner implements QrScanner {
  final StreamController<String> _codes = StreamController<String>.broadcast();
  final ValueNotifier<QrCameraState> _state = ValueNotifier(const QrCameraState());
  CameraController? _controller;
  bool _disposed = false;

  MobileQrScanner() {
    unawaited(_checkCameras());
  }

  /// [ReaderWidget] silently shows nothing when the device has no camera, so
  /// look for one up front.
  Future<void> _checkCameras() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) _set(const QrCameraState(status: QrCameraStatus.unavailable));
    } on CameraException catch (e) {
      _onError(e);
    } catch (_) {
      _set(const QrCameraState(status: QrCameraStatus.unavailable));
    }
  }

  void _set(QrCameraState state) {
    if (!_disposed) _state.value = state;
  }

  /// `camera` reports a refused or restricted permission with these codes
  /// (iOS: all three; Android: CameraAccessDenied).
  static bool _isPermissionError(Object error) =>
      error is CameraException && error.code.startsWith('CameraAccess');

  void _onError(Object error) => _set(QrCameraState(
        status: _isPermissionError(error) ? QrCameraStatus.permissionDenied : QrCameraStatus.unavailable,
      ));

  /// Called by [ReaderWidget] for every camera it opens (again after the app
  /// comes back from the background), or with the error that stopped it.
  void _onController(CameraController? controller, Exception? error) {
    if (_disposed) return;
    if (error != null || controller == null) {
      _controller = null;
      _onError(error ?? Exception('no camera'));
      return;
    }
    _controller = controller;
    // `camera` cannot ask for a torch up front; assume the back camera has one
    // and hide the button if switching it fails (see [toggleTorch]). A fresh
    // camera starts with the torch off.
    _set(QrCameraState(
      status: QrCameraStatus.running,
      torchAvailable: controller.description.lensDirection == CameraLensDirection.back,
    ));
  }

  void _onScan(Code code) {
    final text = code.text;
    if (_disposed || !code.isValid || text == null || text.isEmpty) return;
    _codes.add(text);
  }

  @override
  Stream<String> get codes => _codes.stream;

  @override
  ValueListenable<QrCameraState> get state => _state;

  @override
  Widget buildPreview(BuildContext context) => ReaderWidget(
        codeFormat: Format.qrCode,
        onScan: _onScan,
        onControllerCreated: _onController,
        // The screen draws the viewfinder, torch and cancel itself.
        showScannerOverlay: false,
        showFlashlight: false,
        showGallery: false,
        showToggleCamera: false,
        allowPinchZoom: false,
        // The decoded square: 80 % of the shorter side, a bit larger than the
        // screen's viewfinder so a code held roughly inside it is read.
        cropPercent: 0.8,
        // Defaults are a full second between frames; a join code should be
        // read as soon as it is in view. The screen ignores repeats.
        scanDelay: const Duration(milliseconds: 150),
        scanDelaySuccess: const Duration(milliseconds: 500),
        tryInverted: true,
      );

  @override
  Future<void> toggleTorch() async {
    final controller = _controller;
    if (_disposed || controller == null || !controller.value.isInitialized) return;
    final on = controller.value.flashMode == FlashMode.torch;
    try {
      await controller.setFlashMode(on ? FlashMode.off : FlashMode.torch);
      _set(QrCameraState(status: QrCameraStatus.running, torchAvailable: true, torchOn: !on));
    } catch (_) {
      // No torch on this camera after all.
      _set(const QrCameraState(status: QrCameraStatus.running));
    }
  }

  /// The camera itself is released by [ReaderWidget] when the preview leaves
  /// the tree.
  @override
  void dispose() {
    _disposed = true;
    _controller = null;
    unawaited(_codes.close());
    _state.dispose();
  }
}

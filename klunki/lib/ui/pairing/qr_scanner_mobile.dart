import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'qr_scan_screen.dart';

/// The real camera for the QR scanner (KLD-052), package `mobile_scanner`
/// (Apple Vision + AVFoundation on iOS, CameraX + ML Kit on Android). QR
/// codes only. Not used on the web: its web decoders load from a CDN, which
/// the offline PWA cannot do, so the web build shows no scan button.
class MobileQrScanner implements QrScanner {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final ValueNotifier<QrCameraState> _state = ValueNotifier(const QrCameraState());
  late final Stream<String> _codes = _controller.barcodes
      .expand((capture) => capture.barcodes)
      .map((b) => b.rawValue)
      .where((v) => v != null && v.isNotEmpty)
      .cast<String>()
      .asBroadcastStream();

  MobileQrScanner() {
    _controller.addListener(_sync);
  }

  void _sync() {
    final v = _controller.value;
    final error = v.error;
    final status = switch (error?.errorCode) {
      MobileScannerErrorCode.permissionDenied => QrCameraStatus.permissionDenied,
      MobileScannerErrorCode.unsupported || MobileScannerErrorCode.genericError => QrCameraStatus.unavailable,
      _ => v.isRunning ? QrCameraStatus.running : QrCameraStatus.starting,
    };
    _state.value = QrCameraState(
      status: status,
      torchAvailable: v.isRunning && v.torchState != TorchState.unavailable,
      torchOn: v.torchState == TorchState.on,
    );
  }

  @override
  Stream<String> get codes => _codes;

  @override
  ValueListenable<QrCameraState> get state => _state;

  @override
  Widget buildPreview(BuildContext context) => MobileScanner(
        controller: _controller,
        fit: BoxFit.cover,
        // The screen shows its own messages for errors (see [state]).
        errorBuilder: (context, error) => const ColoredBox(color: Colors.black),
      );

  @override
  Future<void> toggleTorch() => _controller.toggleTorch();

  @override
  void dispose() {
    _controller.removeListener(_sync);
    unawaited(_controller.dispose());
    _state.dispose();
  }
}

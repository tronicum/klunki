import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

import '../../net/scanned_join_code.dart';

/// What the camera is doing.
enum QrCameraStatus { starting, running, permissionDenied, unavailable }

@immutable
class QrCameraState {
  final QrCameraStatus status;

  /// The device has a torch the scanner can switch.
  final bool torchAvailable;
  final bool torchOn;

  const QrCameraState({this.status = QrCameraStatus.starting, this.torchAvailable = false, this.torchOn = false});

  @override
  bool operator ==(Object other) =>
      other is QrCameraState &&
      other.status == status &&
      other.torchAvailable == torchAvailable &&
      other.torchOn == torchOn;

  @override
  int get hashCode => Object.hash(status, torchAvailable, torchOn);

  @override
  String toString() => 'QrCameraState($status, torch: $torchAvailable/$torchOn)';
}

/// The camera behind the scanner screen (KLD-052): the real one is
/// `MobileQrScanner` (package mobile_scanner); tests use a fake that emits
/// [codes] and [state] without a camera.
abstract class QrScanner {
  /// The text of every QR code the camera reads (repeats included).
  Stream<String> get codes;

  /// Camera status and torch.
  ValueListenable<QrCameraState> get state;

  /// The camera preview (fills its box). Starting the camera is up to the
  /// scanner (e.g. when the preview is first shown).
  Widget buildPreview(BuildContext context);

  Future<void> toggleTorch();

  /// Stops the camera and releases it.
  void dispose();
}

/// Creates a scanner for one visit of the scanner screen.
typedef QrScannerFactory = QrScanner Function();

/// Opens the full-screen scanner; completes with the scanned join code, or
/// null when the player cancelled (or chose to type the code instead).
Future<ScannedJoin?> scanJoinCode(BuildContext context, QrScannerFactory scanner) =>
    Navigator.of(context).push<ScannedJoin>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => QrScanScreen(scanner: scanner),
    ));

/// Full-screen QR scanner: the camera preview with a viewfinder, a torch
/// toggle (if the device has one), cancel, and a hint for codes that are not
/// Klunki codes (scanning continues). A Klunki code pops the route with the
/// parsed [ScannedJoin]. A denied permission or a missing camera shows a
/// message and a way back to typing the code.
class QrScanScreen extends StatefulWidget {
  final QrScannerFactory scanner;

  const QrScanScreen({super.key, required this.scanner});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  late final QrScanner _scanner = widget.scanner();
  StreamSubscription<String>? _codes;
  bool _notKlunki = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _codes = _scanner.codes.listen(_onCode);
  }

  @override
  void dispose() {
    _codes?.cancel();
    _scanner.dispose();
    super.dispose();
  }

  void _onCode(String raw) {
    if (_done || !mounted) return;
    final join = parseScannedJoinCode(raw);
    if (join == null) {
      if (!_notKlunki) setState(() => _notKlunki = true);
      return;
    }
    _done = true;
    _codes?.cancel();
    Navigator.of(context).pop(join);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<QrCameraState>(
      valueListenable: _scanner.state,
      builder: (context, state, _) {
        final blocked = state.status == QrCameraStatus.permissionDenied || state.status == QrCameraStatus.unavailable;
        return Scaffold(
          key: const Key('qr-scan-screen'),
          backgroundColor: blocked ? null : Colors.black,
          appBar: AppBar(
            title: Text(l10n.qrScanButton),
            backgroundColor: blocked ? null : Colors.black,
            foregroundColor: blocked ? null : Colors.white,
            leading: IconButton(
              key: const Key('qr-scan-cancel'),
              icon: const Icon(Icons.close),
              tooltip: l10n.pairingCancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (!blocked && state.torchAvailable)
                IconButton(
                  key: const Key('qr-scan-torch'),
                  icon: Icon(state.torchOn ? Icons.flashlight_off : Icons.flashlight_on),
                  tooltip: state.torchOn ? l10n.qrScanTorchOff : l10n.qrScanTorchOn,
                  onPressed: _scanner.toggleTorch,
                ),
            ],
          ),
          body: blocked ? _blocked(context, state.status) : _camera(context),
        );
      },
    );
  }

  Widget _camera(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        _scanner.buildPreview(context),
        const IgnorePointer(child: CustomPaint(painter: _ViewfinderPainter())),
        Positioned(
          left: 16,
          right: 16,
          bottom: 32,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_notKlunki)
                  Container(
                    key: const Key('qr-scan-not-klunki'),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.qrScanNotKlunki,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                Text(
                  l10n.qrScanHint,
                  key: const Key('qr-scan-hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _blocked(BuildContext context, QrCameraStatus status) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final denied = status == QrCameraStatus.permissionDenied;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            key: Key(denied ? 'qr-scan-denied' : 'qr-scan-unavailable'),
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.no_photography_outlined, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                denied ? l10n.qrScanPermissionDenied : l10n.qrScanUnavailable,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (denied) ...[
                const SizedBox(height: 8),
                Text(l10n.qrScanPermissionHint, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('qr-scan-type-instead'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.keyboard),
                label: Text(l10n.qrScanTypeInstead),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Darkens everything but a centred square and draws its corners.
class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = (size.shortestSide * 0.7).clamp(120.0, 320.0);
    final window = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(window, const Radius.circular(16)));
    canvas.drawPath(shade, Paint()..color = Colors.black54);

    final corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    final r = window;
    for (final (p, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(p, p + Offset(dx * len, 0), corner);
      canvas.drawLine(p, p + Offset(0, dy * len), corner);
    }
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) => false;
}

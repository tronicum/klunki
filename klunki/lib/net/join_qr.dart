import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'join_payload.dart';

/// Shows [payload] as a QR code (the canonical `klunki://join?...` string)
/// with `host:port` underneath for typing it in by hand. Display only;
/// scanning is KLD-052.
class JoinQrCode extends StatelessWidget {
  final JoinPayload payload;

  /// Edge length of the QR code itself.
  final double size;

  /// Whether to show `host:port` below the code.
  final bool showAddress;

  const JoinQrCode({super.key, required this.payload, this.size = 200, this.showAddress = true});

  /// The string encoded in the QR code.
  String get data => payload.format();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KlunkiQrCode(data: data, size: size, semanticLabel: 'QR-Code zum Beitreten: ${payload.address}'),
        if (showAddress) ...[
          const SizedBox(height: 8),
          SelectableText(
            payload.address,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ],
    );
  }
}

/// A plain QR code for [data], always dark on white (scanners need the
/// contrast, whatever the theme). Used for the `klunki://` join payload and
/// for the relay room link (KLD-057).
class KlunkiQrCode extends StatelessWidget {
  final String data;
  final double size;
  final String semanticLabel;

  const KlunkiQrCode({super.key, required this.data, this.size = 200, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: Container(
          // Always dark on white: scanners need the contrast, whatever the theme.
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: QrImageView(
            data: data,
            size: size,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            errorStateBuilder: (context, error) => SizedBox.square(
              dimension: size,
              child: const Center(child: Text('QR-Code nicht verfügbar', textAlign: TextAlign.center)),
            ),
          ),
        ),
      ),
    );
  }
}

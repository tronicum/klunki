import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_net/guest_web.dart' show VersionMismatch;

import '../../transport/network_transport.dart';
import 'relay_errors.dart';

/// Host waiting screens (KLD-085): a guest whose build does not fit this one
/// tried to join and was refused. Says which device has to update; the
/// host keeps waiting. Empty while no guest was refused.
class RefusedGuestNotice extends StatelessWidget {
  final NetworkTransport transport;
  const RefusedGuestNotice({super.key, required this.transport});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VersionMismatch?>(
      valueListenable: transport.refusedGuest,
      builder: (context, mismatch, _) {
        if (mismatch == null) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            l10n.versionMismatchGuestRefused(versionMismatchMessage(l10n, mismatch)),
            key: const Key('host-refused-guest'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      },
    );
  }
}

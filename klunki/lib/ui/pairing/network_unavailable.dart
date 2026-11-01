import 'package:flutter/material.dart';
import 'package:klunki/app/web_channel.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/about_screen.dart' show openExternalLink;

/// The sheet behind a greyed-out "Mit anderen", "Raum starten" or "Raum
/// beitreten" (KLD-108): network play can't work in this browser (an https
/// page without a `wss://` relay, see `browserCannotPlayOnline`). Says so,
/// teases the app beta and, when the build configures them
/// ([iosBetaUri], [androidAppUri]), shows buttons to the app links. With
/// no links: just the two lines.
Future<void> showNetworkUnavailableSheet(BuildContext context) =>
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => const NetworkUnavailableSheet());

class NetworkUnavailableSheet extends StatelessWidget {
  const NetworkUnavailableSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final ios = iosBetaUri, android = androidAppUri;
    return SafeArea(
      child: Padding(
        key: const Key('network-unavailable-sheet'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              l10n.networkUnavailableWeb,
              key: const Key('network-unavailable-text'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appBetaTeaser,
              key: const Key('network-unavailable-teaser'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (ios != null || android != null) const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                if (ios != null)
                  FilledButton.tonalIcon(
                    key: const Key('network-unavailable-ios'),
                    icon: const Icon(Icons.phone_iphone),
                    label: Text(l10n.appBetaIos),
                    onPressed: () => openExternalLink(context, ios),
                  ),
                if (android != null)
                  FilledButton.tonalIcon(
                    key: const Key('network-unavailable-android'),
                    icon: const Icon(Icons.android),
                    label: Text(l10n.appBetaAndroid),
                    onPressed: () => openExternalLink(context, android),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import 'web_join_screen.dart';

/// Web: join-only over WebSocket (KLD-055); a page cannot host or browse mDNS.
WidgetBuilder? get pairingScreenBuilder => (_) => WebJoinScreen(pageUrl: Uri.base);

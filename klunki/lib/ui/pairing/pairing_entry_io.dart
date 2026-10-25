import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'pairing_screen.dart';

/// Native: the real pairing screen with the platform dependencies.
WidgetBuilder? get pairingScreenBuilder => kIsWeb ? null : (_) => PairingScreen();

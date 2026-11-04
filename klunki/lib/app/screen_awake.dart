import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the screen from locking by itself while a network game runs
/// (KLD-120): a locked phone is suspended and drops the connection. A tiny
/// platform channel, no package: iOS sets `isIdleTimerDisabled`
/// (`AppDelegate.swift`), Android `FLAG_KEEP_SCREEN_ON` (`MainActivity.kt`).
/// Elsewhere (web, desktop, tests) it does nothing.
class ScreenAwake {
  static const MethodChannel _channel = MethodChannel('klunki/screen');

  /// Test hook: every value passed to [keepOn], in order.
  @visibleForTesting
  static final List<bool> debugCalls = [];

  /// [on]: the screen stays on until called with false. Never throws.
  static Future<void> keepOn(bool on) async {
    debugCalls.add(on);
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('keepOn', on);
    } on MissingPluginException {
      // a platform without the channel
    } on PlatformException {
      // nothing to do: the screen may lock as usual
    }
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';

/// A readable default name for this device, e.g. "Stefans iPhone" from the
/// host name `Stefans-iPhone.local`. Falls back to the platform name when the
/// OS hides the host name (newer iOS versions report `localhost`).
String defaultDeviceName() {
  String raw;
  try {
    raw = Platform.localHostname;
  } catch (_) {
    raw = '';
  }
  return deviceNameFromHostname(raw, defaultTargetPlatform);
}

/// [defaultDeviceName] without the platform call, for tests.
String deviceNameFromHostname(String hostname, TargetPlatform platform) {
  var name = hostname.trim();
  if (name.toLowerCase().endsWith('.local')) name = name.substring(0, name.length - '.local'.length);
  name = name.replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (name.isEmpty || name.toLowerCase() == 'localhost') {
    return switch (platform) {
      TargetPlatform.iOS => 'iPhone/iPad',
      TargetPlatform.android => 'Android',
      TargetPlatform.macOS => 'Mac',
      _ => 'Klunki',
    };
  }
  return name;
}

import 'dart:convert';
import 'dart:io';

import 'package:klunki_engine/sha256.dart';

import 'relay_protocol.dart';

/// The club codes of a gated relay (KLD-112, `klunki relay --codes FILE`):
/// a plain text file, one code per line, an optional `# label` after it:
///
///     K7QX-M2PA  # Familie Müller
///     # a whole-line comment
///     MNPQ-RSTU
///
/// The file is read again on every connection attempt (it is tiny), so an
/// added line works and a removed line is revoked for the next connection,
/// without a restart and without file watchers or signals (the same on
/// macOS and Linux, and robust against editors that save by renaming).
/// A file that cannot be read refuses every code (fail closed) until it is
/// readable again.
///
/// Codes are compared in constant time (SHA-256 digests, every entry
/// compared) and are never logged: [log] gets only labels, or a short hash
/// (`#1a2b3c`) for a code without a label.
class ClubCodes {
  /// The codes file.
  final File file;

  /// Receives one line per change of the file (and per unreadable file).
  final void Function(String line)? log;

  String? _text;
  List<ClubCode> _codes = const [];
  bool _unreadable = false;
  bool _loaded = false;

  ClubCodes._(this.file, this.log);

  /// Reads [path] once (it must exist; throws [FileSystemException]).
  static Future<ClubCodes> load(String path, {void Function(String line)? log}) async {
    final codes = ClubCodes._(File(path), log);
    final text = await codes.file.readAsString(); // throws if missing
    codes._apply(text);
    return codes;
  }

  /// The codes as last read.
  List<ClubCode> get codes => _codes;

  /// The entry for [raw] (as sent by a client), or null if it is not a
  /// current code. Re-reads the file first.
  Future<ClubCode?> check(String raw) async {
    await _reload();
    final code = normalizeClubCode(raw);
    final probe = sha256(utf8.encode(code ?? raw));
    ClubCode? match;
    for (final entry in _codes) {
      var diff = 0;
      for (var i = 0; i < probe.length; i++) {
        diff |= probe[i] ^ entry._digest[i];
      }
      if (diff == 0) match ??= entry;
    }
    return code == null ? null : match;
  }

  Future<void> _reload() async {
    final String text;
    try {
      text = await file.readAsString();
    } on FileSystemException {
      if (!_unreadable) log?.call('Club codes: cannot read ${file.path}; refusing every code until it is back.');
      _unreadable = true;
      _text = null;
      _codes = const [];
      return;
    }
    _unreadable = false;
    if (text != _text) _apply(text);
  }

  void _apply(String text) {
    final first = !_loaded;
    _loaded = true;
    _text = text;
    final codes = <ClubCode>[];
    final lines = const LineSplitter().convert(text);
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final hash = line.indexOf('#');
      final raw = (hash < 0 ? line : line.substring(0, hash)).trim();
      final label = hash < 0 ? '' : line.substring(hash + 1).trim();
      if (raw.isEmpty) continue;
      final code = normalizeClubCode(raw);
      if (code == null) {
        log?.call('Club codes: line ${i + 1} of ${file.path} is not a code (letters and digits, 4 to 64); ignored.');
        continue;
      }
      codes.add(ClubCode._(code, label));
    }
    _codes = List.unmodifiable(codes);
    final names = codes.map((c) => c.logName).join(', ');
    log?.call('Club codes ${first ? 'loaded' : 'reloaded'} from ${file.path}: ${codes.length}'
        '${codes.isEmpty ? ' (nobody can connect)' : ' ($names)'}');
  }
}

/// One line of the codes file.
class ClubCode {
  /// The normalised code ([normalizeClubCode]). Never log it.
  final String code;

  /// The `# label` of its line, or empty.
  final String label;

  final List<int> _digest;

  ClubCode._(this.code, this.label) : _digest = sha256(utf8.encode(code));

  /// What may appear in a log: the label, or `#` and the first 6 hex digits
  /// of the code's SHA-256.
  String get logName => label.isNotEmpty ? label : '#${sha256Hex(code).substring(0, 6)}';
}

/// Counts wrong club codes per remote address (KLD-112): after [limit]
/// wrong codes within [window], that address is refused (as a wrong code)
/// until the window has passed. Behind a reverse proxy every client has the
/// proxy's address, so the limit is shared (see PROTOCOL.md).
class ClubStrikes {
  final int limit;
  final Duration window;
  final Map<String, (int, Stopwatch)> _strikes = {};

  ClubStrikes({this.limit = 10, this.window = const Duration(minutes: 10)});

  /// Whether [address] used up its wrong attempts.
  bool blocked(String address) {
    final s = _strikes[address];
    if (s == null) return false;
    if (s.$2.elapsed > window) {
      _strikes.remove(address);
      return false;
    }
    return s.$1 >= limit;
  }

  /// Records a wrong code from [address].
  void strike(String address) {
    final s = _strikes[address];
    if (s == null || s.$2.elapsed > window) {
      _strikes[address] = (1, Stopwatch()..start());
    } else {
      _strikes[address] = (s.$1 + 1, s.$2);
    }
  }

  /// Forgets windows that have passed.
  void prune() => _strikes.removeWhere((_, s) => s.$2.elapsed > window);
}

import 'dart:convert';
import 'dart:math';

/// The relay's wire vocabulary (see PROTOCOL.md, "Relay"), shared by the
/// server (`package:klunki_net/relay_server.dart`, `dart:io`) and the
/// web-safe clients ([KlunkiHost.startRelay], [KlunkiGuest.connectRelay]).
///
/// Relay control messages are JSON objects with a `t` key (never `type`),
/// whose value starts with `relay.`; game messages always have `type`, so the
/// two can never be confused.

/// The WebSocket path of the relay endpoint.
const String relayPath = '/relay';

/// Default port of `klunki relay`.
const int defaultRelayPort = 4749;

/// Length of a room code.
const int roomCodeLength = 5;

/// Characters of a room code: digits and capital letters without the
/// lookalikes 0/O, 1/I/L (31 symbols, 31^5 ≈ 28.6 million codes).
const String roomCodeAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/// relay → host: the room exists; `code` is what the guest types. Since
/// KLD-120 also `key`: the room's secret host key, which lets the host come
/// back after its connection dropped ([relayResumeUri]).
const String relayRoom = 'relay.room';

/// relay → host: a guest joined the room; game lines follow.
const String relayPeer = 'relay.peer';

/// relay → host: the guest's connection ended (`reason`); the room stays
/// open and a guest may join again with the same code.
const String relayLeft = 'relay.left';

/// relay → host or guest: the room is gone (`reason`: host left, expired,
/// relay shutting down); the relay closes the connection right after.
const String relayClosed = 'relay.closed';

/// relay → anyone: a refused request or a broken rule (`message`: unknown
/// room, room full, line too long, …); the relay closes the connection
/// right after.
const String relayError = 'relay.error';

/// host → relay: drop the current guest connection (the host session closed
/// it); lines sent before it are delivered first.
const String relayKick = 'relay.kick';

// ------------------------------------------- host away and back (KLD-120)

/// Query parameter of a host that comes back to its room:
/// `?resume=CODE&key=KEY` ([relayResumeUri]).
const String relayResumeParam = 'resume';

/// Query parameter carrying the room's host key (from `relay.room`).
const String relayKeyParam = 'key';

/// `relay.error {error: "host-away"}`: the room exists, but its host's
/// connection dropped and it has not come back yet; try again in a moment.
const String relayErrorHostAway = 'host-away';

/// The client-side text of a [relayErrorHostAway] refusal
/// (`NetException("relay: the host is away")`), fixed whatever the relay's
/// `message` says, so apps can recognise it and retry.
const String relayHostAwayText = 'the host is away';

/// The URL a host uses to come back to room [code] with its [key] (and
/// `&club=CODE` when [clubCode] is set).
Uri relayResumeUri(Uri relay, String code, String key, {String? clubCode}) => relay.replace(queryParameters: {
      relayResumeParam: code,
      relayKeyParam: key,
      if (clubCode != null) relayClubParam: clubCode,
    });

/// Encodes a relay control message.
String relayControl(String t, [Map<String, Object?> fields = const {}]) => jsonEncode({'t': t, ...fields});

/// The control message in [line] (its decoded object), or null for any other
/// line (game messages, garbage). Cheap for game lines: only lines that
/// mention `"t"` are decoded.
Map<String, dynamic>? parseRelayControl(String line) {
  if (!line.contains('"t"')) return null;
  try {
    final decoded = jsonDecode(line);
    if (decoded is Map<String, dynamic>) {
      final t = decoded['t'];
      if (t is String && t.startsWith('relay.') && !decoded.containsKey('type')) return decoded;
    }
  } on FormatException {
    // not JSON: a game-level problem, not ours
  }
  return null;
}

/// A random room code (`roomCodeLength` symbols of [roomCodeAlphabet]).
String newRoomCode([Random? random]) {
  final r = random ?? Random.secure();
  return String.fromCharCodes(
      List.generate(roomCodeLength, (_) => roomCodeAlphabet.codeUnitAt(r.nextInt(roomCodeAlphabet.length))));
}

/// Normalises a typed room code: case-insensitive, spaces and dashes are
/// ignored (`k7q-2m` → `K7Q2M`). Returns null if the result is not a valid
/// code (wrong length, or a character outside [roomCodeAlphabet], e.g. `0`,
/// `O`, `1`, `I`, `L`).
String? normalizeRoomCode(String input) {
  final code = input.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
  if (code.length != roomCodeLength) return null;
  for (final c in code.split('')) {
    if (!roomCodeAlphabet.contains(c)) return null;
  }
  return code;
}

/// Parses a relay address as a user types it: `ws://host:port`,
/// `wss://host[:port]`, `http(s)://host:port` (mapped to ws/wss) or a bare
/// `host:port` (ws). The path defaults to [relayPath]; query and fragment are
/// dropped. Returns null for anything else.
Uri? parseRelayUrl(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'ws://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) return null;
  final scheme = switch (uri.scheme.toLowerCase()) {
    'ws' || 'http' => 'ws',
    'wss' || 'https' => 'wss',
    _ => null,
  };
  if (scheme == null) return null;
  if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) return null;
  final path = uri.path.isEmpty || uri.path == '/' ? relayPath : uri.path;
  return Uri(
      scheme: scheme, userInfo: uri.userInfo, host: uri.host, port: uri.hasPort ? uri.port : null, path: path);
}

/// The relay URL of the server that served [page] (the PWA's own origin,
/// `Uri.base` in the browser): `http://h:p/…` → `ws://h:p/relay`,
/// `https://…` → `wss://…/relay`. Null if [page] is not http(s).
Uri? relayUriForPage(Uri page) {
  final scheme = switch (page.scheme) { 'http' => 'ws', 'https' => 'wss', _ => null };
  if (scheme == null || page.host.isEmpty) return null;
  return Uri(scheme: scheme, host: page.host, port: page.hasPort ? page.port : null, path: relayPath);
}

/// The URL the host connects to: [relay] with `?create` (and
/// `&club=CODE` when [clubCode] is set, KLD-112).
Uri relayCreateUri(Uri relay, {String? clubCode}) => relay.replace(
    query: clubCode == null ? 'create' : 'create&$relayClubParam=${Uri.encodeQueryComponent(clubCode)}');

/// The URL a guest connects to: [relay] with `?join=CODE` (and
/// `&club=CODE` when [clubCode] is set, KLD-112).
Uri relayJoinUri(Uri relay, String code, {String? clubCode}) =>
    relay.replace(queryParameters: {'join': code, if (clubCode != null) relayClubParam: clubCode});

// ------------------------------------------------- club codes (KLD-112)

/// Query parameter carrying the club code (server access code) of a gated
/// relay (`klunki relay --codes FILE`). An open relay ignores it.
const String relayClubParam = 'club';

/// `relay.error` field naming a machine-readable refusal reason. Only club
/// refusals carry it; `message` stays for people.
const String relayErrorField = 'error';

/// `relay.error {error: "club-missing"}`: the relay needs a club code and
/// none was sent.
const String relayErrorClubMissing = 'club-missing';

/// `relay.error {error: "club-wrong"}`: the club code is unknown or revoked,
/// or this address sent too many wrong codes (indistinguishable on purpose).
const String relayErrorClubWrong = 'club-wrong';

/// The client-side text of a [relayErrorClubMissing] refusal
/// (`NetException("relay: club code required")`), fixed whatever the
/// relay's `message` says, so apps can recognise it.
const String relayClubMissingText = 'club code required';

/// The client-side text of a [relayErrorClubWrong] refusal.
const String relayClubWrongText = 'club code not accepted';

/// The `NetException` text for a refusal [control] message (`relay.error`):
/// the fixed club texts for club refusals, else the relay's `message`.
String relayRefusalText(Map<String, dynamic> control, String fallback) => switch (control[relayErrorField]) {
      relayErrorClubMissing => relayClubMissingText,
      relayErrorClubWrong => relayClubWrongText,
      relayErrorHostAway => relayHostAwayText,
      _ => '${control['message'] ?? fallback}',
    };

/// Normalises a club code as typed or written in the codes file:
/// case-insensitive, spaces and dashes ignored (`k7qx-m2pa` → `K7QXM2PA`).
/// Null if the result is shorter than 4 or longer than 64 characters, or
/// contains anything but `A`–`Z` and `0`–`9`.
String? normalizeClubCode(String input) {
  final code = input.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
  if (code.length < 4 || code.length > 64) return null;
  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) return null;
  return code;
}

/// A random, readable club code: two groups of four symbols of
/// [roomCodeAlphabet], e.g. `K7QX-M2PA` (31^8 ≈ 8.5 · 10^11 codes).
String newClubCode([Random? random]) {
  final r = random ?? Random.secure();
  String group() => String.fromCharCodes(
      List.generate(4, (_) => roomCodeAlphabet.codeUnitAt(r.nextInt(roomCodeAlphabet.length))));
  return '${group()}-${group()}';
}

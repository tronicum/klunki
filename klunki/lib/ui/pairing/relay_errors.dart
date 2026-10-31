import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_net/guest_web.dart' show NetException, PeerAge, VersionMismatch;

import '../../net/room_link.dart';
import '../ltr.dart';

/// What went wrong with a relay room (KLD-057), from the `klunki_net` error
/// text (`relay: no room with code …`, `relay: room … is full`,
/// `relay: host left`, `relay: room expired (idle)`, `cannot connect: …`).
enum RelayFailure {
  /// The code names no open room (typo, or the host is gone).
  unknownCode,

  /// The room already has a guest.
  roomFull,

  /// The host refused the join: its guest seat belongs to someone else, who
  /// can come back only with the session token (`session full`, KLD-071).
  seatTaken,

  /// The host left: the room is closed.
  hostLeft,

  /// The room expired after the relay's idle timeout.
  expired,

  /// No relay answered at that address (e.g. the page is served by a plain
  /// web server without `/relay`).
  unreachable,

  /// The relay connection broke later (relay stopped, network loss).
  lost,
}

String _text(Object error) => error is NetException ? error.message : '$error';

/// Classifies [error] (a [NetException], a reason string, a timeout); null
/// for anything that is not a relay problem (e.g. a handshake failure).
RelayFailure? classifyRelayError(Object error) {
  if (error is TimeoutException) return RelayFailure.unreachable;
  final s = _text(error);
  if (isSeatTaken(error)) return RelayFailure.seatTaken;
  if (s.contains('no room with code')) return RelayFailure.unknownCode;
  if (s.contains('is full')) return RelayFailure.roomFull;
  if (s.contains('host left') || s.contains('host connection failed')) return RelayFailure.hostLeft;
  if (s.contains('expired')) return RelayFailure.expired;
  if (s.startsWith('cannot connect') ||
      s.contains('relay closed the connection') ||
      s.contains('not a Klunki relay') ||
      s.contains('no room from the relay') ||
      (s.contains('relay connection failed') && !s.startsWith('relay:'))) {
    return RelayFailure.unreachable;
  }
  if (s.startsWith('relay')) return RelayFailure.lost;
  return null;
}

/// Whether the host refused [error]'s join because its seat is taken
/// (`session full`): only the guest with the session token gets back in
/// (KLD-071). Same over TCP, WebSocket and a relay.
bool isSeatTaken(Object error) => _text(error).contains('session full');

/// The version mismatch behind [error] (KLD-085): the [NetException]'s
/// [NetException.mismatch], or null.
VersionMismatch? versionMismatchOf(Object error) => error is NetException ? error.mismatch : null;

/// A localized sentence for a version mismatch (KLD-085): which device has
/// to update, "both" when that is unknown.
String versionMismatchMessage(AppLocalizations l10n, VersionMismatch mismatch) => switch (mismatch.peer) {
  PeerAge.older => l10n.versionMismatchUpdateOther,
  PeerAge.newer => l10n.versionMismatchUpdateThis,
  PeerAge.unknown => l10n.versionMismatchBoth,
};

/// [versionMismatchMessage] for [error] if the join failed because the two
/// builds do not fit together, else null.
String? versionMismatchText(BuildContext context, Object error) {
  final mismatch = versionMismatchOf(error);
  return mismatch == null ? null : versionMismatchMessage(AppLocalizations.of(context), mismatch);
}

/// Whether [failure] means the room is gone for good (rejoining is useless).
bool relayRoomClosed(RelayFailure? failure) =>
    failure == RelayFailure.hostLeft || failure == RelayFailure.expired || failure == RelayFailure.lost;

/// A friendly, localized sentence for [error], or null if it is not a relay
/// problem. [code] (the room) and [relay] fill in the details.
/// Room codes and addresses are kept left-to-right in RTL locales.
String? relayErrorText(BuildContext context, Object error, {String? code, Uri? relay}) {
  final l10n = AppLocalizations.of(context);
  final failure = classifyRelayError(error);
  final room = code == null ? '' : bidiLtr(context, formatRoomCode(code));
  return switch (failure) {
    null => null,
    RelayFailure.unknownCode => l10n.relayErrorUnknownCode(room),
    RelayFailure.roomFull => l10n.relayErrorRoomFull(room),
    RelayFailure.seatTaken => l10n.pairingSeatTaken,
    RelayFailure.hostLeft => l10n.relayErrorHostLeft,
    RelayFailure.expired => l10n.relayErrorExpired,
    RelayFailure.unreachable => l10n.relayErrorUnreachable(
      relay == null ? '?' : bidiLtr(context, relayAddressLabel(relay)),
    ),
    RelayFailure.lost => l10n.relayErrorLost,
  };
}

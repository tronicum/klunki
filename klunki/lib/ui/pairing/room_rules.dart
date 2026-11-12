import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../games/maexchen/maexchen_options.dart';
import '../games/maumau/maumau_options.dart';

/// The house rules a room starts with, for the games that have them in the
/// start dialog (network steps of Mau-Mau, KLD-118, and Mäxchen, KLD-121:
/// lives, "Unbegrenzte Leben", "Mäxchen doppelt"). The host chooses them on
/// "Raum starten" (on this device or through the relay); they travel to the
/// guest in the game's public config, and the waiting room and the game show
/// them ([roomRulesSummary]).
class RoomRules {
  final MauMauRules mauMau;
  final MaexchenOptions maexchen;

  const RoomRules({this.mauMau = const MauMauRules(), this.maexchen = defaultMaexchenOptions});

  RoomRules copyWith({MauMauRules? mauMau, MaexchenOptions? maexchen}) =>
      RoomRules(mauMau: mauMau ?? this.mauMau, maexchen: maexchen ?? this.maexchen);

  /// [config] with these rules for its game (the others ignore them).
  GameConfig applyTo(GameConfig config) => GameConfig.fromJson({
        ...config.toJson(),
        if (config.gameId == 'maumau' && !mauMau.isDefault) 'maumau': mauMau.toJson(),
        if (config.gameId == 'maexchen') ...GameConfig('maexchen',
                lives: maexchen.lives, maexchenDouble: maexchen.double, maexchenUnlimited: maexchen.unlimited)
            .publicJson(),
      });
}

/// Whether [gameId] has house rules in a room.
bool hasRoomRules(String gameId) => gameId == 'maumau' || gameId == 'maexchen';

/// The house-rule switches of [gameId] for "Raum starten" (nothing for a
/// game without them). Keys: `<keyPrefix>maumau-rule-<name>` (see
/// [MauMauOptionsPicker]), `<keyPrefix>maexchen-lives-<n>`,
/// `<keyPrefix>maexchen-unlimited`, `<keyPrefix>maexchen-double` (see
/// [MaexchenOptionsPicker]).
class RoomRulesPicker extends StatelessWidget {
  final String gameId;
  final RoomRules value;
  final ValueChanged<RoomRules> onChanged;
  final bool enabled;
  final String keyPrefix;

  const RoomRulesPicker({
    super.key,
    required this.gameId,
    required this.value,
    required this.onChanged,
    required this.keyPrefix,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => switch (gameId) {
        'maumau' => MauMauOptionsPicker(
            keyPrefix: '${keyPrefix}maumau-',
            value: value.mauMau,
            enabled: enabled,
            onChanged: (r) => onChanged(value.copyWith(mauMau: r)),
          ),
        'maexchen' => MaexchenOptionsPicker(
            keyPrefix: '${keyPrefix}maexchen-',
            value: value.maexchen,
            enabled: enabled,
            onChanged: (o) => onChanged(value.copyWith(maexchen: o)),
          ),
        _ => const SizedBox.shrink(),
      };
}

/// The house rules of [config] that differ from the defaults, as one line
/// for the room and the game ("5 Leben · ohne Mäxchen doppelt"); null when
/// the game has none in a room or plays by the default rules (then the room
/// shows no rules line at all: KLD-121/KLD-118 network decisions
/// 2026-11-12).
String? roomRulesSummary(AppLocalizations l10n, GameConfig config) => switch (config.gameId) {
      'maumau' => mauMauRulesSummary(l10n, config.mauMau),
      'maexchen' => maexchenOptionsSummary(l10n, config),
      _ => null,
    };

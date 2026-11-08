import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

import '../../app/theme.dart';
import '../../profile/player_name_controller.dart';
import '../../profile/seat_names.dart';
import '../ltr.dart';

/// How a game for 2–4 players on one device names its seats (KLD-088,
/// KLD-119): the typed name, else the regional default name (seat 0 / 1 as
/// in the two-player games, "Anna" / "Ben"; seats 2 / 3 `playerDefaultNameC`
/// / `D`). Every seat also has a colour and its number ([SeatToken]), so a
/// seat is never told apart by colour alone.
@immutable
class SeatLabels {
  /// Typed names per seat (null = the default name).
  final List<String?> names;
  const SeatLabels([this.names = const []]);

  static const SeatLabels defaults = SeatLabels();

  String? nameOf(int seat) {
    final n = seat < names.length ? names[seat] : null;
    return n == null || n.isEmpty ? null : n;
  }

  /// The name shown for [seat].
  String name(AppLocalizations l10n, int seat) => nameOf(seat) ?? defaultSeatName(l10n, seat);

  /// [seat] inside a sentence (bidi-isolated where needed); with "(3)" when
  /// another seat of [count] has the same name.
  String label(BuildContext context, AppLocalizations l10n, int seat, {int count = 4}) {
    final n = bidiName(context, name(l10n, seat));
    final same = [
      for (var s = 0; s < count; s++)
        if (s != seat && name(l10n, s).toLowerCase() == name(l10n, seat).toLowerCase()) s
    ];
    return same.isEmpty ? n : l10n.playerLabel(n, '${seat + 1}');
  }

  @override
  bool operator ==(Object other) => other is SeatLabels && listEquals(other.names, names);

  @override
  int get hashCode => Object.hashAll(names);
}

/// The regional default name of [seat]: `playerDefaultNameA` … `D`.
String defaultSeatName(AppLocalizations l10n, int seat) => switch (seat) {
      0 => l10n.playerDefaultNameA,
      1 => l10n.playerDefaultNameB,
      2 => l10n.playerDefaultNameC,
      _ => l10n.playerDefaultNameD,
    };

/// Provides [SeatLabels] below it; without one, [SeatLabelsScope.of] builds
/// them from the app's name stores ([PlayerNameScope] for seats 0 / 1,
/// [ExtraSeatNames] for seats 2 / 3), see [SeatNamesBuilder].
class SeatLabelsScope extends InheritedWidget {
  final SeatLabels labels;
  const SeatLabelsScope({super.key, required this.labels, required super.child});

  static SeatLabels of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SeatLabelsScope>()?.labels ?? SeatLabels.defaults;

  @override
  bool updateShouldNotify(SeatLabelsScope old) => old.labels != labels;
}

/// Puts the app's current hot-seat names into a [SeatLabelsScope] and keeps
/// it up to date while the players edit them.
class SeatNamesBuilder extends StatelessWidget {
  final Widget child;
  const SeatNamesBuilder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final two = PlayerNameScope.maybeOf(context)?.hotSeat;
    final extra = ExtraSeatNames.shared();
    return ListenableBuilder(
      listenable: Listenable.merge([?two, extra]),
      builder: (context, child) {
        final names = two?.value;
        return SeatLabelsScope(
          labels: SeatLabels([names?.x, names?.o, extra.nameOf(2), extra.nameOf(3)]),
          child: child!,
        );
      },
      child: child,
    );
  }
}

/// The colour of [seat] (KLD-119): blue, orange, green, purple (after the
/// Okabe–Ito set, apart for most colour-blind players too), lighter on the
/// dark table. Always shown with the seat number ([SeatToken]).
Color seatColor(BuildContext context, int seat) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  const light = [Color(0xFF1F6FB2), Color(0xFFD9822B), Color(0xFF2E8B57), Color(0xFFA23B72)];
  const night = [Color(0xFF6FA8DC), Color(0xFFF0A35E), Color(0xFF6CC08B), Color(0xFFD77FB0)];
  return (dark ? night : light)[seat % 4];
}

/// A seat's token: a disc in [seatColor] with the seat number 1–4.
class SeatToken extends StatelessWidget {
  final int seat;
  final double size;

  /// A seat that left: greyed out.
  final bool out;
  const SeatToken({super.key, required this.seat, this.size = 22, this.out = false});

  @override
  Widget build(BuildContext context) {
    final fill = out ? Theme.of(context).colorScheme.outline : seatColor(context, seat);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: Colors.black26, width: size * 0.08),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Text(
          '${seat + 1}',
          textDirection: TextDirection.ltr,
          style: TextStyle(color: inkOn(fill), fontSize: size * 0.5, fontWeight: FontWeight.w700, height: 1),
        ),
      ),
    );
  }
}

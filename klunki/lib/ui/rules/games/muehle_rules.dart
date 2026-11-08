import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../games/muehle/muehle_geometry.dart';
import '../../games/muehle/muehle_painter.dart';
import '../rules_model.dart';

/// Mühle (KLD-123): a small board with a closed mill.
GameRules muehleRules(BuildContext context, AppLocalizations l10n, GameConfig config) => GameRules(
      goal: ruleLines(l10n.rulesMuehleGoal),
      turn: ruleLines(l10n.rulesMuehleTurn),
      special: [
        RuleItem(l10n.rulesMuehleMill, lead: const _Mill()),
        ...ruleLines(l10n.rulesMuehleSpecial),
      ],
    );

class _Mill extends StatelessWidget {
  const _Mill();

  /// The top row of the outer square.
  static const List<int> _mill = [0, 1, 2];

  @override
  Widget build(BuildContext context) {
    final colors = KlunkiPalette.of(context).muehle;
    return SizedBox.square(
      dimension: 44,
      child: CustomPaint(
        painter: MuehleBoardPainter(colors: colors, millLines: const [_mill], flash: 1),
        foregroundPainter: _Stones(colors),
      ),
    );
  }
}

class _Stones extends CustomPainter {
  final MuehlePalette colors;
  const _Stones(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.075;
    for (final p in _Mill._mill) {
      final c = MuehleGeometry.center(p, size.width);
      canvas.drawCircle(c, r, Paint()..color = colors.dark);
      canvas.drawCircle(c, r, Paint()
        ..color = colors.darkEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }
    // One of the other player's stones, to be taken.
    final o = MuehleGeometry.center(13, size.width);
    canvas.drawCircle(o, r, Paint()..color = colors.light);
    canvas.drawCircle(o, r, Paint()
      ..color = colors.remove
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_Stones old) => old.colors != colors;
}

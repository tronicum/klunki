import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../game/game_controller.dart';
import '../../transport/game_transport.dart';
import '../game_visuals.dart' show tokenSidesOf;
import '../shell/game_screen.dart';
import 'chess/chess_board.dart';
import 'chess/chess_pieces.dart';

/// Chess screen (KLD-059 step 2): the 8×8 board with tap-to-move (and
/// drag-and-drop), promotion picker, check and last-move highlights, the SAN
/// move list and the captured pieces. See [ChessBoard].
///
/// Network play (step 3): the host chooses its colour (step 4a: White, Black
/// or random; `GameConfig.chessWhite`); each device shows its own side at
/// the bottom, and says "Du spielst Weiß/Schwarz" until the first move. The player to move can offer a draw (the
/// board's handshake button); the other one accepts or declines in a dialog.
///
/// The players are "Weiß" / "Schwarz" instead of X / O everywhere in the
/// shell (status line, result and resign dialog, history): the screen puts
/// the side names into the [PlayerLabels] it passes on. Open information, so
/// hot-seat needs no handover cover.
///
/// Contract (keep it): the public class name `ChessScreen` and the constructor
/// `const ChessScreen({super.key, required this.controller})`. The screen is
/// built by `ui/shell/screen_registry.dart` and renders a [GameScreen].
class ChessScreen extends StatelessWidget {
  final GameController controller;

  const ChessScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
    final game = controller.game as ChessGame;
    return PlayerLabelsScope(
      labels: labels.withMarkNames(
        {for (final p in Player.values) p: chessSideName(l10n, game.colorOf(p))},
        tokens: tokenSidesOf(controller.config),
      ),
      child: GameScreen(
        controller: controller,
        // History sheet: "Weiß: e4" (the shell prefixes the player).
        describeMove: (l10n, m) => describeChessMove(m, l10n),
        boardBuilder: (context, controller) => ChessBoard(controller: controller),
      ),
    );
  }
}

/// SAN of an accepted chess move ("Nf3", "O-O", "exd6", "e8=Q#"); the draw
/// offer moves (KLD-059 step 3) in words when [l10n] is given.
String describeChessMove(AcceptedMove m, [AppLocalizations? l10n]) {
  if (l10n != null) {
    switch (m.move['action']) {
      case ChessGame.offerDraw:
        return l10n.chessMoveDrawOffer;
      case ChessGame.declineDraw:
        return l10n.chessMoveDrawDecline;
      case ChessGame.acceptDraw:
        return l10n.chessMoveDrawAccept;
    }
  }
  final payload = m.event.payload;
  final san = payload is Map ? payload['san'] : null;
  return san is String ? san : '${m.move['from']}–${m.move['to']}';
}

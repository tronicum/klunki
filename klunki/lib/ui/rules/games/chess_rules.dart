import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../games/chess/chess_pieces.dart';
import '../rules_model.dart';

/// Schach (KLD-123): how every piece moves (with its picture), check and
/// mate, castling, en passant, promotion and the kinds of draw the engine
/// knows. No house rules.
GameRules chessRules(BuildContext context, AppLocalizations l10n, GameConfig config) {
  RuleItem piece(ChessPieceType t, String text) => RuleItem(
        '${chessPieceName(l10n, t)}: $text',
        key: Key('rules-chess-${t.name}'),
        lead: ChessPieceIcon(piece: ChessPiece(ChessColor.white, t), size: 32),
      );
  return GameRules(
    goal: ruleLines(l10n.rulesChessGoal),
    turn: [
      ...ruleLines(l10n.rulesChessTurn),
      RuleItem.heading(l10n.rulesChessPieces),
      piece(ChessPieceType.king, l10n.rulesChessKing),
      piece(ChessPieceType.queen, l10n.rulesChessQueen),
      piece(ChessPieceType.rook, l10n.rulesChessRook),
      piece(ChessPieceType.bishop, l10n.rulesChessBishop),
      piece(ChessPieceType.knight, l10n.rulesChessKnight),
      piece(ChessPieceType.pawn, l10n.rulesChessPawn),
    ],
    special: [
      ...ruleLines(l10n.rulesChessSpecial),
      RuleItem.heading(l10n.rulesChessDrawTitle),
      ...ruleLines(l10n.rulesChessDraw),
    ],
  );
}

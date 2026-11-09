import 'games/chess_rules.dart';
import 'games/connect4_rules.dart';
import 'games/dicesheet_rules.dart';
import 'games/gostrategy_rules.dart';
import 'games/maexchen_rules.dart';
import 'games/maumau_rules.dart';
import 'games/muehle_rules.dart';
import 'games/property_rules.dart';
import 'games/quartett_rules.dart';
import 'games/schiffe_rules.dart';
import 'games/wordtiles_rules.dart';
import 'rules_model.dart';

export 'rules_model.dart' show RulesBuilder;

/// `GameSpec.id` → its rules page (KLD-123). A new game adds one file in
/// `games/` with a [RulesBuilder] and one line here; the "Regeln" button in
/// the game screen, the menu link and the "Neu hier?" line appear for every
/// game listed.
final Map<String, RulesBuilder> gameRules = {
  'connect4': connect4Rules,
  'muehle': muehleRules,
  'quartett-trumpf': quartettTrumpfRules,
  'quartett-sets': quartettSetsRules,
  'schiffe': schiffeRules,
  'gostrategy': goStrategyRules,
  'chess': chessRules,
  'wordtiles': wordTilesRules,
  'maumau': mauMauRules,
  'maexchen': maexchenRules,
  'dicesheet': diceSheetRules,
  'property': propertyRules,
};

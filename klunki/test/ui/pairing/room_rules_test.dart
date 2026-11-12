import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/ui/pairing/room_rules.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

/// KLD-118/KLD-121 network decisions 2026-11-12: the room's rules line names
/// only the house rules that differ from the defaults (a rule switched off
/// as "ohne …"); with the default rules there is no line at all.
void main() {
  group('roomRulesSummary', () {
    String? line(GameConfig c) => roomRulesSummary(deL10n, c);

    test('the default rules: no line, for every game with room rules', () {
      expect(line(const GameConfig('maumau')), isNull);
      expect(line(const GameConfig('maexchen')), isNull);
      expect(line(const GameConfig('maexchen', lives: 3, maexchenDouble: true)), isNull);
    });

    test('games without room rules: no line', () {
      expect(line(const GameConfig('connect4')), isNull);
      expect(line(const GameConfig('chess')), isNull);
    });

    test('Mäxchen: the lives, "Unbegrenzte Leben", "Mäxchen doppelt" off', () {
      expect(line(const GameConfig('maexchen', lives: 5)), '5 Leben');
      expect(line(const GameConfig('maexchen', maexchenDouble: false)), 'ohne Mäxchen doppelt');
      expect(line(const GameConfig('maexchen', lives: 5, maexchenDouble: false)), '5 Leben · ohne Mäxchen doppelt');
      expect(line(const GameConfig('maexchen', maexchenUnlimited: true)), 'Unbegrenzte Leben');
      // The lives do not count with "Unbegrenzte Leben".
      expect(line(const GameConfig('maexchen', lives: 5, maexchenUnlimited: true, maexchenDouble: false)),
          'Unbegrenzte Leben · ohne Mäxchen doppelt');
    });

    test('Mau-Mau: a rule switched on by name, one switched off as "ohne …"', () {
      String? mm(MauMauRules r) => line(GameConfig('maumau', mauMau: r));
      expect(mm(const MauMauRules(jackOnJack: true)), 'Bube auf Bube');
      expect(mm(const MauMauRules(eightSkips: false, jackOnJack: true)), 'ohne 8: aussetzen · Bube auf Bube');
      expect(mm(const MauMauRules(stackSevens: false)), 'ohne 7 auf 7');
      // Without "7: zwei Karten ziehen" "7 auf 7" does not matter.
      expect(mm(const MauMauRules(sevenDraws: false, stackSevens: false)), 'ohne 7: zwei Karten ziehen');
      expect(
          mm(const MauMauRules(
              sevenDraws: false, eightSkips: false, aceAgain: false, mauCall: false, mustPlay: false)),
          'ohne 7: zwei Karten ziehen · ohne 8: aussetzen · ohne Ass: noch mal · ohne „Mau!“ sagen · '
          'ohne Legen, wenn möglich');
    });

    test('in English too', () {
      expect(roomRulesSummary(enL10n, const GameConfig('maexchen', lives: 5, maexchenDouble: false)),
          '5 lives · without Double Mia');
    });
  });

  // KLD-121 network decisions: "Schütteln zum Würfeln" as a switch in the "⋮"
  // menu shows whether it is on.
  testWidgets('a menu switch shows its state as a check box', (tester) async {
    var on = true;
    late StateSetter set;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(actions: [
          StatefulBuilder(builder: (context, setState) {
            set = setState;
            return ShellMenu(entries: [
              ShellMenuEntry(
                key: const Key('switch'),
                icon: Icons.vibration,
                label: 'Schütteln zum Würfeln',
                checked: on,
                onSelected: () => set(() => on = !on),
              ),
              ShellMenuEntry(key: const Key('plain'), icon: Icons.refresh, label: 'Neues Spiel', onSelected: () {}),
            ]);
          }),
        ]),
      ),
    ));
    Future<void> open() async {
      await tester.tap(find.byKey(const Key('shell-menu')));
      await tester.pumpAndSettle();
    }

    await open();
    expect(find.descendant(of: find.byKey(const Key('switch')), matching: find.byIcon(Icons.check_box)), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('plain')), matching: find.byIcon(Icons.check_box)), findsNothing);
    expect(
        find.descendant(of: find.byKey(const Key('plain')), matching: find.byIcon(Icons.check_box_outline_blank)),
        findsNothing);
    await tester.tap(find.byKey(const Key('switch')));
    await tester.pumpAndSettle();
    expect(on, isFalse);
    await open();
    expect(find.descendant(of: find.byKey(const Key('switch')), matching: find.byIcon(Icons.check_box_outline_blank)),
        findsOneWidget);
  });
}

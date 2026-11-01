// KLD-067: whose turn it is shows through colour (status pill, turn edge,
// hot-seat legend), with distinct "my turn" / "waiting" states in network
// games, a pulse + haptic when the turn comes back, and reduced motion
// respected. Text and tokens stay (colour is never the only signal).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/game_visuals.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import 'shell_test_utils.dart';

const _palette = KlunkiPalette.classicLight;

Future<GameController> _pump(WidgetTester tester, String id, {PlayerLabels? labels}) async {
  final c = GameController.hotSeat(GameConfig(id, seed: 1));
  addTearDown(c.dispose);
  Widget screen = buildGameScreen(c);
  if (labels != null) screen = PlayerLabelsScope(labels: labels, child: screen);
  await tester.pumpWidget(localizedApp(screen));
  await tester.pump();
  return c;
}

BoxDecoration _pill(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byKey(const Key('shell-turn'))).decoration! as BoxDecoration;

Color? _edge(WidgetTester tester) =>
    (tester.widget<AnimatedContainer>(find.byKey(const Key('shell-turn-edge'))).decoration as BoxDecoration?)?.color;

Duration _pillDuration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byKey(const Key('shell-turn'))).duration;

double _scale(WidgetTester tester) => tester
    .widget<ScaleTransition>(
        find.ancestor(of: find.byKey(const Key('shell-turn')), matching: find.byType(ScaleTransition)).first)
    .scale
    .value;

Color _statusColor(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('shell-status'))).style!.color!;

/// Records HapticFeedback calls.
List<String> _recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}

void main() {
  final red = _palette.connect4.red, yellow = _palette.connect4.yellow;

  group('hot-seat', () {
    testWidgets('the pill and the edge take the colour of the player to move', (tester) async {
      await _pump(tester, 'connect4');
      expect(_pill(tester).color, red);
      expect(_edge(tester), red);
      expect(_statusColor(tester), inkOn(red));
      expect(find.text('Anna ist am Zug'), findsOneWidget, reason: 'the text stays');
      expect(find.byKey(const Key('shell-waiting')), findsNothing);

      await playMove(tester);
      await tester.pumpAndSettle();
      expect(_pill(tester).color, yellow);
      expect(_edge(tester), yellow);
      expect(_statusColor(tester), inkOn(yellow));
      expect(find.text('Ben ist am Zug'), findsOneWidget);
    });

    testWidgets('the legend shows both players with their colours, the one to move in front', (tester) async {
      await _pump(tester, 'connect4', labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}));
      expect(find.byKey(const Key('shell-players')), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
      double opacity(String mark) => tester.widget<AnimatedOpacity>(find.byKey(Key('shell-player-$mark'))).opacity;
      expect(opacity('X'), 1);
      expect(opacity('O'), lessThan(1));
      await playMove(tester);
      expect(opacity('X'), lessThan(1));
      expect(opacity('O'), 1);
      final tokens = tester.widgetList<PlayerToken>(
          find.descendant(of: find.byKey(const Key('shell-players')), matching: find.byType(PlayerToken)));
      expect([for (final t in tokens) t.player], [Player.a, Player.b]);
    });

    testWidgets('games without piece colours: accent for Anna, second player colour for Ben', (tester) async {
      await _pump(tester, 'schiffe');
      // Schiffe starts with placement by X.
      expect(_pill(tester).color, _palette.accent('schiffe').color);
      expect(playerColor(_palette, 'schiffe', Player.b), _palette.secondPlayer);
      expect(playerColor(_palette, 'muehle', Player.b), _palette.muehle.dark);
    });
  });

  group('tokens (KLD-107): number "1" / "2" or the game piece, never X / O', () {
    List<String> tokenTexts(WidgetTester tester) => [
          for (final t in tester.widgetList<Text>(find.descendant(
              of: find.byKey(const Key('shell-players')),
              matching: find.descendant(of: find.byType(PlayerToken), matching: find.byType(Text)))))
            t.data!,
        ];

    for (final id in ['schiffe', 'quartett-trumpf', 'quartett-sets', 'gostrategy', 'wordtiles']) {
      testWidgets('$id: discs with "1" and "2"', (tester) async {
        await _pump(tester, id);
        expect(tokenTexts(tester), ['1', '2']);
        final pill = find.descendant(of: find.byKey(const Key('shell-turn')), matching: find.byType(PlayerToken));
        expect(tester.widget<Text>(find.descendant(of: pill, matching: find.byType(Text))).data, '1');
      });
    }

    for (final id in ['connect4', 'muehle', 'chess']) {
      testWidgets('$id: the game piece, no letter', (tester) async {
        await _pump(tester, id);
        expect(find.descendant(of: find.byKey(const Key('shell-players')), matching: find.byType(PlayerToken)),
            findsNWidgets(2));
        expect(tokenTexts(tester), isEmpty);
      });
    }
  });

  group('network', () {
    const mine = PlayerLabels(local: Player.a, names: {Player.a: 'Anna', Player.b: 'Ben'});

    testWidgets('"my turn" is filled and bold, "waiting" is muted with an hourglass', (tester) async {
      await _pump(tester, 'connect4', labels: mine);
      expect(find.text('Du bist am Zug'), findsOneWidget);
      expect(_pill(tester).color, red);
      expect(_pill(tester).boxShadow, isNotEmpty, reason: 'glow');
      expect(_edge(tester), red);
      expect(find.byKey(const Key('shell-waiting')), findsNothing);
      expect(find.byKey(const Key('shell-players')), findsNothing, reason: 'the network bar shows the players');

      await playMove(tester);
      await tester.pumpAndSettle();
      expect(find.text('Warte auf Ben…'), findsOneWidget);
      expect(find.byKey(const Key('shell-waiting')), findsOneWidget);
      final pill = _pill(tester);
      expect(pill.color, isNot(yellow), reason: 'not filled while waiting');
      expect(pill.boxShadow, isNull);
      expect((pill.border! as Border).top.color.a, lessThan(1));
      // Muted: the opponent's colour, faded.
      expect(_edge(tester), yellow.withValues(alpha: 0.35));
      expect(_statusColor(tester), isNot(inkOn(yellow)));
      // The token still says whose turn it is.
      final token = tester.widget<PlayerToken>(
          find.descendant(of: find.byKey(const Key('shell-turn')), matching: find.byType(PlayerToken)));
      expect(token.player, Player.b);
    });

    testWidgets('the turn coming back pulses once and taps (haptic)', (tester) async {
      final haptics = _recordHaptics(tester);
      await _pump(tester, 'connect4', labels: mine);
      expect(haptics, isEmpty, reason: 'nothing on the first frame');
      await playMove(tester); // now waiting for Ben
      await tester.pumpAndSettle();
      expect(haptics, isEmpty);
      expect(_scale(tester), 1);

      await playMove(tester); // Ben moved: my turn again
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      await tester.pump(const Duration(milliseconds: 150));
      expect(_scale(tester), greaterThan(1));
      await tester.pumpAndSettle();
      expect(_scale(tester), 1);
      expect(_pill(tester).color, red);
    });

    testWidgets('reduced motion: no pulse, no colour transition', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final haptics = _recordHaptics(tester);
      await _pump(tester, 'connect4', labels: mine);
      expect(_pillDuration(tester), Duration.zero);
      expect(tester.widget<AnimatedContainer>(find.byKey(const Key('shell-turn-edge'))).duration, Duration.zero);
      await playMove(tester);
      await playMove(tester);
      await tester.pump(const Duration(milliseconds: 150));
      expect(_scale(tester), 1, reason: 'no pulse');
      expect(_pill(tester).color, red);
      expect(haptics, hasLength(1), reason: 'the haptic tap is not motion');
    });
  });

  testWidgets('the status line stays a live region', (tester) async {
    await _pump(tester, 'connect4');
    final sem = tester.widget<Semantics>(
        find.ancestor(of: find.byKey(const Key('shell-status')), matching: find.byType(Semantics)).first);
    expect(sem.properties.liveRegion, isTrue);
  });
}

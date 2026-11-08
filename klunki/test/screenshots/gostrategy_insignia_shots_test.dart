// KLD-058: the GoStrategy rank insignia. An overview at the large-phone tile
// size, a sheet at all tile sizes used in the app (board on a small and a
// large phone, the compact and full fight card, a 2× zoom), light and dark,
// a mid-game board on both phones, the setup editor and a fight reveal.
// Skipped unless KLUNKI_SHOTS=<dir> is set; KLUNKI_SHOTS_SUFFIX is added to
// every file name (e.g. "-v5"):
//
//   KLUNKI_SHOTS=/tmp/insignia flutter test test/screenshots/gostrategy_insignia_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/games/gostrategy/gostrategy_pieces.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

final String? _out = Platform.environment['KLUNKI_SHOTS'];
final String _suffix = Platform.environment['KLUNKI_SHOTS_SUFFIX'] ?? '';
const _boundary = Key('shot-boundary');

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  await family('Roboto', [
    'assets/fonts/Roboto/Roboto-Regular.ttf',
    'assets/fonts/Roboto/Roboto-Medium.ttf',
    'assets/fonts/Roboto/Roboto-Bold.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
}

Future<void> _shot(WidgetTester tester, String name, {Duration settle = const Duration(milliseconds: 600)}) async {
  debugDisableShadows = false;
  await tester.pump(settle);
  await tester.pump();
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/$name$_suffix.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
}

void _view(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, Brightness b) => RepaintBoundary(
  key: _boundary,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: withAppFonts(b == Brightness.dark ? KlunkiTheme.dark : KlunkiTheme.light, web: false),
    locale: const Locale('de'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: PlayerLabelsScope(
      labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
      child: home,
    ),
  ),
);

/// Tile sizes: the board on a small phone (375 pt: about 26) and a large
/// phone (430 pt: about 34), 31 and 37 for comparison, the compact and the
/// full fight card (40, 64) and a 2× zoom.
const _sizes = [
  (26.0, 'Brett kleines Handy (375 pt)'),
  (31.0, ''),
  (34.0, 'Brett großes Handy (430 pt)'),
  (37.0, ''),
  (40.0, 'Kampfkarte kompakt'),
  (64.0, 'Kampfkarte'),
  (74.0, '2× Zoom'),
];

/// One row: all twelve pieces, a hidden enemy back and a seen own piece.
Widget _row(Player owner, double size) => Wrap(
  spacing: 6,
  runSpacing: 6,
  children: [
    for (final p in GoPiece.values) GoPieceTile(owner: owner, piece: p, size: size),
    SizedBox(width: size * 0.3),
    GoPieceTile(owner: owner == Player.a ? Player.b : Player.a, piece: null, size: size, moved: true),
    GoPieceTile(owner: owner, piece: GoPiece.captain, size: size, known: true),
  ],
);

Widget _rows(BuildContext context, double size) => Container(
  color: KlunkiPalette.of(context).gostrategy.land,
  padding: const EdgeInsets.all(4),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final owner in Player.values)
        Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: _row(owner, size)),
    ],
  ),
);

Widget _sheet({required bool all}) => Builder(
  builder: (context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marschall, General, Oberst, Major, Hauptmann, Leutnant, Feldwebel, Mineur, Späher, Spion, Bombe, Fahne · verdeckt · gesehen',
              style: theme.textTheme.bodySmall,
            ),
            for (final (size, label) in all ? _sizes : [(37.0, 'Brett großes Handy')]) ...[
              const SizedBox(height: 8),
              Text(
                label.isEmpty ? '${size.round()} px' : '${size.round()} px · $label',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              _rows(context, size),
            ],
          ],
        ),
      ),
    );
  },
);

void _handover(GameController c) {
  if (c.needsHandover) c.acknowledgeHandover();
}

/// A hot-seat game after both setups and [moves] moves (every third one an
/// attack when there is one, so pieces get seen).
GameController _midGame(int moves) {
  final c = GameController.hotSeat(const GameConfig('gostrategy', seed: 7));
  addTearDown(c.dispose);
  c.submit(GoStrategyGame.setupMove(GoStrategyGame.randomSetup(14)));
  _handover(c);
  c.submit(GoStrategyGame.setupMove(GoStrategyGame.randomSetup(15)));
  _handover(c);
  final g = c.game as GoStrategyGame;
  for (var i = 0; i < moves && !g.isOver; i++) {
    final legal = g.legalMoves;
    if (legal.isEmpty) break;
    final attacks = [
      for (final m in legal)
        if (m['action'] == 'move' && g.board[m['to'] as int].owner != null) m,
    ];
    c.submit(i % 3 == 0 && attacks.isNotEmpty ? attacks[i % attacks.length] : legal[(i * 7 + 3) % legal.length]);
    _handover(c);
  }
  return c;
}

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  group('kld058-insignia', () {
    for (final b in Brightness.values) {
      final tag = b == Brightness.dark ? 'dark' : 'light';
      testWidgets('overview $tag', skip: skip, (tester) async {
        _view(tester, const Size(760, 170));
        await tester.pumpWidget(_app(_sheet(all: false), b));
        await _shot(tester, 'kld058-insignia-overview-$tag');
      });
      testWidgets('sheet $tag', skip: skip, (tester) async {
        _view(tester, const Size(1180, 1000));
        await tester.pumpWidget(_app(_sheet(all: true), b));
        await _shot(tester, 'kld058-insignia-sheet-$tag');
      });
    }

    for (final (name, size) in [('phone-small', Size(375, 667)), ('phone-large', Size(430, 932))]) {
      testWidgets('board $name', skip: skip, (tester) async {
        _view(tester, size);
        final c = _midGame(40);
        await tester.pumpWidget(_app(buildGameScreen(c), Brightness.light));
        await tester.pump();
        await tester.pump(const Duration(seconds: 3)); // let a fight reveal pass
        await _shot(tester, 'kld058-insignia-board-$name');
      });
    }

    testWidgets('setup editor', skip: skip, (tester) async {
      _view(tester, const Size(430, 932));
      final c = GameController.hotSeat(const GameConfig('gostrategy', seed: 7));
      addTearDown(c.dispose);
      await tester.pumpWidget(_app(buildGameScreen(c), Brightness.light));
      await _shot(tester, 'kld058-insignia-setup');
    });

    testWidgets('fight reveal', skip: skip, (tester) async {
      _view(tester, const Size(430, 932));
      final c = _midGame(6);
      final g = c.game as GoStrategyGame;
      // Quiet moves until the player to move can attack.
      Map<String, dynamic>? attack;
      for (var i = 0; i < 400 && attack == null && !g.isOver; i++) {
        _handover(c);
        final legal = g.legalMoves;
        attack = legal.where((m) => m['action'] == 'move' && g.board[m['to'] as int].owner != null).firstOrNull;
        if (attack == null) c.submit(legal[(i * 7 + 3) % legal.length]);
      }
      _handover(c);
      await tester.pumpWidget(_app(buildGameScreen(c), Brightness.light));
      await tester.pump();
      c.submit(attack!);
      await tester.pump();
      _handover(c);
      await tester.pump();
      await tester.pump(); // the reveal starts on this frame
      await _shot(tester, 'kld058-insignia-fight', settle: const Duration(milliseconds: 900));
    });
  });
}

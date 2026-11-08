// KLD-058 insignia step 1: the variant sheet of the GoStrategy rank insignia
// (A shoulder board, B free on the tile, C like B with gold stars and bars,
// plus today's classic look for comparison) at the real tile sizes, with and
// without the corner number, both armies, light and dark; and a mid-game
// board with variant B. Skipped unless KLUNKI_SHOTS=<dir> is set:
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

Future<void> _shot(WidgetTester tester, String name) async {
  debugDisableShadows = false;
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
  final ro = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final ui.Image img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/$name-v3.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(data!.buffer.asUint8List());
  });
  debugDisableShadows = true;
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
    home: home,
  ),
);

/// Tile sizes: board on a small phone (375 pt: 37.5 × 0.86 × 0.86 ≈ 31) and
/// a large phone (430 pt ≈ 37), the compact and the full fight card (40, 64)
/// and a 2× zoom of the large-phone tile.
const _sizes = [
  (31.0, 'Brett kleines Handy'),
  (37.0, 'Brett großes Handy'),
  (40.0, 'Kampfkarte kompakt'),
  (64.0, 'Kampfkarte'),
  (74.0, '2× Zoom'),
];

const _lookNames = {
  GoPieceLook.classic: 'Heute (klassisch)',
  GoPieceLook.shoulderBoard: 'A: Schulterklappe',
  GoPieceLook.insignia: 'B: frei, Tintenfarbe',
  GoPieceLook.insigniaGold: 'C: frei, Sterne/Balken gold',
  GoPieceLook.insigniaBlack: 'B1: B mit dünnem schwarzem Rand',
  GoPieceLook.insigniaGrey: 'B2: B mit dünnem dunkelgrauem Rand',
  GoPieceLook.insigniaHalo: 'B3: B mit weichem dunklem Schein',
};

/// The looks on the sheets this round (KLD-058 v3: the maintainer chose B,
/// now B with and without an edge).
const _looks = [GoPieceLook.insignia, GoPieceLook.insigniaBlack, GoPieceLook.insigniaGrey, GoPieceLook.insigniaHalo];

/// One row: all twelve pieces, a hidden enemy back and a seen own piece.
Widget _row(GoPieceLook look, Player owner, double size, bool number) => Wrap(
  spacing: 6,
  runSpacing: 6,
  children: [
    for (final p in GoPiece.values) GoPieceTile(owner: owner, piece: p, size: size, look: look, rankNumber: number),
    SizedBox(width: size * 0.3),
    GoPieceTile(owner: owner == Player.a ? Player.b : Player.a, piece: null, size: size, moved: true, look: look),
    GoPieceTile(owner: owner, piece: GoPiece.captain, size: size, known: true, look: look, rankNumber: number),
  ],
);

Widget _sheet(GoPieceLook look, Brightness b) => Builder(
  builder: (context) {
    final theme = Theme.of(context);
    final land = KlunkiPalette.of(context).gostrategy.land;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_lookNames[look]} · ${b == Brightness.dark ? 'dunkel' : 'hell'}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Marschall, General, Oberst, Major, Hauptmann, Leutnant, Feldwebel, Mineur, Späher, Spion, Bombe, Fahne · verdeckt · gesehen',
              style: theme.textTheme.bodySmall,
            ),
            for (final (size, label) in _sizes) ...[
              const SizedBox(height: 8),
              Text('${size.round()} px · $label', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              // Board land under the tiles, as in the game.
              Container(
                color: land,
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final number in look == GoPieceLook.classic ? [true] : [true, false])
                      for (final owner in Player.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: _row(look, owner, size, number),
                        ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  },
);

/// All looks side by side at the large-phone board size, both armies.
Widget _overview(Brightness b) => Builder(
  builder: (context) {
    final theme = Theme.of(context);
    final land = KlunkiPalette.of(context).gostrategy.land;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final look in _looks) ...[
              Text(_lookNames[look]!, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Container(
                color: land,
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    for (final owner in Player.values)
                      Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: _row(look, owner, 37, true)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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

void main() {
  final skip = _out == null;
  setUpAll(() async {
    if (_out != null) await _loadFonts();
  });

  group('kld058-insignia', () {
    for (final b in Brightness.values) {
      final tag = b == Brightness.dark ? 'dark' : 'light';
      for (final look in _looks) {
        testWidgets('sheet ${look.name} $tag', skip: skip, (tester) async {
          tester.view.physicalSize = const Size(1180, 1340) * 2;
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(_app(_sheet(look, b), b));
          await _shot(tester, 'kld058-insignia-sheet-${look.name}-$tag');
        });
      }
      testWidgets('overview $tag', skip: skip, (tester) async {
        tester.view.physicalSize = const Size(760, 520) * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(_overview(b), b));
        await _shot(tester, 'kld058-insignia-overview-$tag');
      });
    }

    // A mid-game board with variants B and A (some fights, so a few own
    // pieces are seen), on a large and a small phone.
    for (final (variant, look) in [
      ('B', GoPieceLook.insignia),
      ('B1', GoPieceLook.insigniaBlack),
      ('B2', GoPieceLook.insigniaGrey),
      ('B3', GoPieceLook.insigniaHalo),
    ]) {
      for (final (name, size) in [('phone-small', Size(375, 667))]) {
        for (final b in [Brightness.light]) {
          final tag = b == Brightness.dark ? 'dark' : 'light';
          testWidgets('board $variant $name $tag', skip: skip, (tester) async {
            tester.view.physicalSize = size * 2;
            tester.view.devicePixelRatio = 2;
            addTearDown(tester.view.reset);
            final c = GameController.hotSeat(const GameConfig('gostrategy', seed: 7));
            addTearDown(c.dispose);
            c.submit(GoStrategyGame.setupMove(GoStrategyGame.randomSetup(14)));
            _handover(c);
            c.submit(GoStrategyGame.setupMove(GoStrategyGame.randomSetup(15)));
            _handover(c);
            final g = c.game as GoStrategyGame;
            for (var i = 0; i < 40 && !g.isOver; i++) {
              final moves = g.legalMoves;
              if (moves.isEmpty) break;
              // Every third move an attack when there is one, so pieces get seen.
              final attacks = [
                for (final m in moves)
                  if (m['action'] == 'move' && g.board[m['to'] as int].owner != null) m,
              ];
              c.submit(
                i % 3 == 0 && attacks.isNotEmpty ? attacks[i % attacks.length] : moves[(i * 7 + 3) % moves.length],
              );
              _handover(c);
            }
            await tester.pumpWidget(
              _app(
                GoPieceLookScope(
                  look: look,
                  child: PlayerLabelsScope(
                    labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
                    child: buildGameScreen(c),
                  ),
                ),
                b,
              ),
            );
            await tester.pump();
            _handover(c);
            await tester.pump(const Duration(seconds: 3)); // let a fight reveal pass
            await _shot(tester, 'kld058-insignia-board-$variant-$name-$tag');
          });
        }
      }
    }
  });
}

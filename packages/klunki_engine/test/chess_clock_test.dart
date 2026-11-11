import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-126: the chess clock (pure, time passed in) and the clock moves.
void main() {
  Map<String, dynamic> mv(String from, String to) => {'action': 'move', 'from': from, 'to': to};
  const five = ChessTimeControl(5 * 60000);
  const fifteenTen = ChessTimeControl(15 * 60000, 10000);

  group('ChessTimeControl', () {
    test('id "<base s>+<inc s>" round trip; presets 5, 10, 15+10, 30 minutes', () {
      expect(ChessTimeControl.presets.map((c) => c.id), ['300+0', '600+0', '900+10', '1800+0']);
      for (final c in ChessTimeControl.presets) {
        expect(ChessTimeControl.tryParse(c.id), c);
      }
      expect(ChessTimeControl.tryParse('3+0'), const ChessTimeControl(3000));
      for (final bad in [null, 5, '', '300', '300+', '+5', '0+0', '-1+0', '300+601', '99999+0', '1.5+0', '300+0 ']) {
        expect(ChessTimeControl.tryParse(bad), isNull, reason: '$bad');
      }
    });
  });

  group('ChessClock', () {
    test('counts down only the running player; a move adds the increment and switches', () {
      final c = ChessClock(fifteenTen);
      expect(c.ticking, isFalse);
      expect(c.remainingOf(Player.a, 5000), 900000);
      c.start(Player.a, 1000);
      expect(c.remainingOf(Player.a, 4000), 897000);
      expect(c.remainingOf(Player.b, 4000), 900000);
      expect(c.moveMade(Player.a, 4000), 3000);
      expect(c.remainingOf(Player.a, 9000), 907000); // 900 - 3 + 10
      expect(c.remainingOf(Player.b, 9000), 895000);
      expect(c.running, Player.b);
      expect(c.untilFlag(9000), 895000);
    });

    test('charge replaces the measured time (network lag rule)', () {
      final c = ChessClock(five)..start(Player.a, 0);
      expect(c.moveMade(Player.a, 2000, charge: 1200), 1200);
      expect(c.remainingOf(Player.a, 2000), 300000 - 1200);
    });

    test('flag: the running player at or below zero', () {
      final c = ChessClock(const ChessTimeControl(3000))..start(Player.a, 0);
      expect(c.flagged(2999), isNull);
      expect(c.flagged(3000), Player.a);
      c.moveMade(Player.a, 1000);
      expect(c.flagged(4000), Player.b);
      expect(c.flagged(3999), isNull);
    });

    test('pause and hold stop both clocks, independently', () {
      final c = ChessClock(five)..start(Player.a, 0);
      c.setPaused(true, 1000);
      expect(c.remainingOf(Player.a, 60000), 299000);
      expect(c.untilFlag(60000), isNull);
      c.setHeld(true, 61000);
      c.setPaused(false, 62000);
      expect(c.remainingOf(Player.a, 70000), 299000, reason: 'still held');
      c.setHeld(false, 70000);
      expect(c.remainingOf(Player.a, 71000), 298000);
      expect(c.snapshot(71000), const ChessClockSnapshot(a: 298000, b: 300000, running: Player.a, spent: 2000));
      expect(c.turnElapsed(71000), 2000);
      c.setHeld(true, 71000);
      expect(c.snapshot(80000).paused, isTrue);
    });

    test('stop freezes the values; snapshot JSON round trip', () {
      final c = ChessClock(five)..start(Player.a, 0);
      c.moveMade(Player.a, 1000);
      c.stop(5000);
      expect(c.running, isNull);
      final s = c.snapshot(99999);
      expect(s, const ChessClockSnapshot(a: 299000, b: 296000));
      expect(ChessClockSnapshot.tryParse(s.toJson()), s);
      expect(s.toJson(), {'a': 299000, 'b': 296000, 'run': null, 'paused': false, 'spent': 0});
      for (final bad in [null, 3, {'a': 1, 'b': 2}, {'a': 1, 'b': 2, 'run': 'c', 'paused': false}]) {
        expect(ChessClockSnapshot.tryParse(bad), isNull, reason: '$bad');
      }
    });

    test('fromSnapshot continues where the snapshot was (undo, a guest mirror)', () {
      final c = ChessClock.fromSnapshot(five, const ChessClockSnapshot(a: 1000, b: 2000, running: Player.b), 500);
      expect(c.remainingOf(Player.b, 1500), 1000);
      expect(c.flagged(2500), Player.b);
      // The turn so far counts: 700 ms before the snapshot, 300 after.
      final m = ChessClock.fromSnapshot(
          fifteenTen, const ChessClockSnapshot(a: 5000, b: 9000, running: Player.a, spent: 700), 0);
      expect(m.turnElapsed(300), 1000);
      expect(m.moveMade(Player.a, 300), 1000);
      expect(m.remainingOf(Player.a, 300), 5000 - 300 + 10000);
    });

    test('a turn across a pause costs the time before and after it', () {
      final c = ChessClock(five)..start(Player.a, 0);
      c.setPaused(true, 1000);
      c.setPaused(false, 50000);
      expect(c.turnElapsed(51000), 2000);
      expect(c.moveMade(Player.a, 51000, charge: 1500), 1500);
      expect(c.remainingOf(Player.a, 51000), 298500);
      expect(ChessClock(five).moveMade(Player.a, 100), 0, reason: 'not started');
    });
  });

  group('chess with a clock (rules 4)', () {
    ChessGame clocked({Player white = Player.a}) => ChessGame(white: white, timeControl: five);

    test('GameConfig.chessClock: JSON "clock", absent = none; createGame passes it on', () {
      const cfg = GameConfig('chess', chessClock: fifteenTen);
      expect(cfg.toJson(), {'game': 'chess', 'seed': 0, 'clock': '900+10'});
      expect(const GameConfig('chess').toJson().containsKey('clock'), isFalse);
      expect(GameConfig.fromJson(cfg.toJson()), cfg);
      expect(GameConfig.fromJson({'game': 'chess', 'clock': 'x'}).chessClock, isNull);
      expect(cfg.copyWith(seed: 3).chessClock, fifteenTen);
      expect(cfg == const GameConfig('chess'), isFalse);
      expect((createGame(cfg) as ChessGame).timeControl, fifteenTen);
      expect(specById('chess')!.rulesVersion, 4);
    });

    test('timeout: only with a clock, only for the player to move; the other wins', () {
      expect(ChessGame().applyMove(ChessGame.timeoutMove(Player.a)), isNull, reason: 'no clock');
      final g = clocked();
      expect(g.applyMove(ChessGame.timeoutMove(Player.b)), isNull, reason: 'not to move');
      expect(g.playerOf(ChessGame.timeoutMove(Player.b)), Player.b);
      final e = g.applyMove(ChessGame.timeoutMove(Player.a))!;
      expect(e.winner, Player.b);
      expect(e.payload, {'timeout': 'a'});
      expect(g.result.code, GameEndReason.chessTimeout);
      expect(g.result.params, {'player': 0});
      expect(g.applyMove(mv('e2', 'e4')), isNull);
      expect(g.history, isEmpty, reason: 'not a board move');
    });

    test('timeout against a lone king is a draw (no mating material)', () {
      // Black (B) has only the king; White (A, to move) flags.
      final g = ChessGame.fromFen('7k/8/8/8/8/8/P7/K7 w - - 0 1', timeControl: five);
      final e = g.applyMove(ChessGame.timeoutMove(Player.a))!;
      expect(e.draw, isTrue);
      expect(g.result.code, GameEndReason.chessTimeoutDraw);
      // A lone king that flags loses to a pawn.
      final h = ChessGame.fromFen('7k/8/8/8/8/8/P7/K7 b - - 0 1', timeControl: five);
      h.applyMove(ChessGame.timeoutMove(Player.b));
      expect(h.result.winner, Player.a);
      // White's colours follow the players (B plays White).
      final k = ChessGame.fromFen('7k/8/8/8/8/8/P7/K7 b - - 0 1', white: Player.b, timeControl: five);
      k.applyMove(ChessGame.timeoutMove(Player.a)); // A = Black, to move, lone king
      expect(k.result.winner, Player.b);
    });

    test('pause by agreement: request, agree, nothing moves, resume by agreement', () {
      final g = clocked();
      expect(g.applyMove(ChessGame.clockMove(ChessGame.clockResume, Player.a)), isNull, reason: 'not paused');
      expect(g.applyMove(ChessGame.clockMove(ChessGame.clockPause, Player.b))!.payload, {'pauseRequest': 'b'});
      expect(g.clockRequest, (by: Player.b, resume: false));
      expect(g.applyMove(ChessGame.clockMove(ChessGame.clockPause, Player.a)), isNull, reason: 'one request');
      expect(g.applyMove(ChessGame.clockMove(ChessGame.clockAgree, Player.b)), isNull, reason: 'own request');
      // Play goes on while a request is open.
      expect(g.applyMove(mv('e2', 'e4')), isNotNull);
      expect(g.applyMove(ChessGame.clockMove(ChessGame.clockAgree, Player.a))!.payload, {'clockPaused': true});
      expect(g.clockPaused, isTrue);
      expect(g.applyMove(mv('e7', 'e5')), isNull);
      expect(g.applyMove(ChessGame.offerDrawMove(Player.b)), isNull);
      expect(g.applyMove(ChessGame.timeoutMove(Player.b)), isNull);
      expect(g.applyMove(ChessGame.clockMove(ChessGame.clockResume, Player.a))!.payload, {'resumeRequest': 'a'});
      expect(g.applyMove(ChessGame.clockMove(ChessGame.clockRefuse, Player.b))!.payload, {'clockRefused': 'b'});
      expect(g.clockPaused, isTrue);
      g.applyMove(ChessGame.clockMove(ChessGame.clockResume, Player.b));
      expect(g.applyMove(ChessGame.clockMove(ChessGame.clockAgree, Player.a))!.payload, {'clockPaused': false});
      expect(g.applyMove(mv('e7', 'e5')), isNotNull);
      expect(g.sanHistory, ['e4', 'e5']);
      // Without a clock there is no pause.
      expect(ChessGame().applyMove(ChessGame.clockMove(ChessGame.clockPause, Player.a)), isNull);
    });

    test('a resign ends a paused game; replay restores pause and requests', () {
      final log = [
        mv('e2', 'e4'),
        ChessGame.clockMove(ChessGame.clockPause, Player.a),
        ChessGame.clockMove(ChessGame.clockAgree, Player.b),
      ];
      const cfg = GameConfig('chess', chessClock: five);
      final g = replay(cfg, log)! as ChessGame;
      expect(g.clockPaused, isTrue);
      expect(replay(const GameConfig('chess'), log), isNull, reason: 'no clock, no pause');
      expect(g.applyMove(Game.resignMove(Player.b))!.winner, Player.a);
      final timedOut = replay(cfg, [mv('e2', 'e4'), ChessGame.timeoutMove(Player.b)])!;
      expect(timedOut.result.code, GameEndReason.chessTimeout);
    });
  });
}

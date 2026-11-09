import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:test/test.dart';

import 'support.dart';

/// KLD-121: Mäxchen over the network (engine level; the app offers it on one
/// device only for now). The guest never sees the host's dice before a doubt
/// and verifies the whole game after the reveal, also with non-default
/// lives and house rule.
void main() {
  test('5 lives, "Mäxchen doppelt" off: the guest sees no foreign dice and verifies the game', () async {
    const config = GameConfig('maexchen', seed: 21, lives: 5, maexchenDouble: false);
    final host = await startHost(config);
    final guest = await joinHost(host.port);
    expect(guest.config, const GameConfig('maexchen', lives: 5, maexchenDouble: false), reason: 'seed stays secret');
    final rng = Random(4);
    var steps = 0;
    while (!host.game.isOver) {
      expect(++steps, lessThan(3000));
      final h = host.game as MaexchenGame, g = guest.game as MaexchenGame;
      // Only the roller's own view holds the dice.
      expect(g.dice, h.roller == Player.b ? h.dice : isNull);
      expect(g.lives, h.lives);
      if (h.currentPlayer == host.me) {
        final legal = h.legalMoves;
        expect(host.submitLocal(legal[rng.nextInt(legal.length)]), isNull);
        final n = host.moves.length;
        await until(() => guest.moves.length == n);
      } else {
        final legal = g.legalMoves;
        expect(await guest.submit(legal[rng.nextInt(legal.length)]), isNull);
      }
    }
    expect((host.game as MaexchenGame).startLives, 5);
    await until(() => guest.verification != Verification.pending);
    expect(guest.verificationError, isNull);
    expect(guest.verification, Verification.verified);
    expect(guest.game.result.winner, host.game.result.winner);
    await guest.close();
    await host.close();
  });

  test('"Unbegrenzte Leben": the tally reaches the guest, the guest ends the game and verifies it', () async {
    const config = GameConfig('maexchen', seed: 8, maexchenUnlimited: true);
    final host = await startHost(config);
    final guest = await joinHost(host.port);
    expect(guest.config.maexchenUnlimited, isTrue);
    final rng = Random(2);
    for (var steps = 0; steps < 120; steps++) {
      final h = host.game as MaexchenGame, g = guest.game as MaexchenGame;
      expect(g.lost, h.lost);
      expect(g.unlimitedLives, isTrue);
      if (h.currentPlayer == host.me) {
        final legal = h.legalMoves;
        expect(host.submitLocal(legal[rng.nextInt(legal.length)]), isNull);
        final n = host.moves.length;
        await until(() => guest.moves.length == n);
      } else {
        final legal = g.legalMoves;
        expect(await guest.submit(legal[rng.nextInt(legal.length)]), isNull);
      }
    }
    expect(host.game.isOver, isFalse, reason: 'nobody drops out');
    // The player to move ends the game.
    if ((host.game as MaexchenGame).currentPlayer == host.me) {
      expect(host.submitLocal(MaexchenGame.endMove), isNull);
    } else {
      expect(await guest.submit(MaexchenGame.endMove), isNull);
    }
    await until(() => guest.game.isOver);
    expect(host.game.result.code, GameEndReason.maexchenEnded);
    await until(() => guest.verification != Verification.pending);
    expect(guest.verificationError, isNull);
    expect(guest.verification, Verification.verified);
    expect(guest.game.result.winner, host.game.result.winner);
    await guest.close();
    await host.close();
  });
}

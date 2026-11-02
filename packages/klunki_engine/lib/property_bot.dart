/// Simple bots for Baulöwe (KLD-060): they play many full games in the tests
/// and drive `auto` in the CLI. Not a strong player; a starting point for a
/// computer opponent later.
library;

import 'dart:math';

import 'property.dart';

/// Picks a move for [PropertyGame.actor].
///
/// [greedy] false: a random legal move, plus now and then a random trade
/// offer. Every management cycle loses money (houses sell for half, lifting
/// a mortgage costs 10 % more), so random play still ends.
///
/// [greedy] true: buys what it can afford with a reserve, bids up to the
/// price, builds evenly with spare cash, offers money for the last street a
/// group lacks, accepts trades that give it at least as much value, raises
/// money in a debt by selling houses first, then mortgaging, and declares
/// bankruptcy only when nothing is left.
class PropertyBot {
  final Random rng;
  final bool greedy;
  PropertyBot(this.rng, {this.greedy = true});

  /// Reserve the greedy bot keeps when buying and building.
  static const int reserve = 150;

  Map<String, dynamic> choose(PropertyGame g) {
    final legal = g.legalMoves;
    if (legal.isEmpty) throw StateError('no move: the game is over');
    if (!greedy) {
      if ((g.phase == PropertyPhase.end || g.phase == PropertyPhase.roll) && rng.nextInt(20) == 0) {
        final offer = _randomOffer(g);
        if (offer != null) return offer;
      }
      return legal[rng.nextInt(legal.length)];
    }
    final a = g.actor!;
    final cash = g.seats[a].cash;
    Map<String, dynamic>? first(String action) => legal.where((m) => m['action'] == action).firstOrNull;

    switch (g.phase) {
      case PropertyPhase.debt:
        return first('sell') ?? first('mortgage') ?? first('bankrupt')!;
      case PropertyPhase.auction:
        final au = g.auction!;
        final price = g.theme.squares[au.square].price;
        if (au.minBid <= price && cash - au.minBid >= reserve) return {'action': 'bid', 'amount': au.minBid};
        return {'action': 'pass'};
      case PropertyPhase.trade:
        final t = g.trade!;
        return _value(g, t.give) >= _value(g, t.get) ? {'action': 'tradeAccept'} : {'action': 'tradeDecline'};
      case PropertyPhase.buy:
        final price = g.theme.squares[g.seats[a].pos].price;
        return cash - price >= reserve ? {'action': 'buy'} : {'action': 'decline'};
      case PropertyPhase.roll || PropertyPhase.end:
        final s = g.seats[a];
        if (g.phase == PropertyPhase.roll && s.inPause) {
          if (first('useCard') != null) return first('useCard')!;
          if (cash >= 400 && first('payBail') != null) return first('payBail')!;
        }
        for (final m in legal) {
          final sq = g.theme.squares[m['square'] as int? ?? 0];
          if (m['action'] == 'unmortgage' && cash - sq.unmortgageCost >= 3 * reserve) return m;
          if (m['action'] == 'build' && cash - sq.houseCost >= 2 * reserve) return m;
        }
        if (rng.nextInt(4) == 0) {
          final offer = _groupOffer(g);
          if (offer != null) return offer;
        }
        return first('roll') ?? first('endTurn')!;
      case PropertyPhase.over:
        throw StateError('over');
    }
  }

  /// Value of [side] for trade decisions: money plus property prices
  /// (mortgaged: half) plus 50 per free card.
  static int _value(PropertyGame g, PropertyTradeSide side) {
    var v = side.money + 50 * side.cards;
    for (final i in side.squares) {
      v += g.isMortgaged(i) ? g.theme.squares[i].mortgageValue : g.theme.squares[i].price;
    }
    return v;
  }

  /// Money for the one street another seat holds of a group the actor
  /// otherwise owns completely; null if there is none or it is not legal.
  Map<String, dynamic>? _groupOffer(PropertyGame g) {
    final a = g.currentSeat;
    for (final group in g.theme.groups) {
      final others = [for (final i in group) if (g.ownerOf(i) != a) i];
      if (others.length != 1) continue;
      final i = others.single, owner = g.ownerOf(i);
      if (owner == null) continue;
      final money = g.theme.squares[i].price * 3 ~/ 2;
      final get = PropertyTradeSide(squares: [i]), give = PropertyTradeSide(money: money);
      if (g.seats[a].cash - money < reserve || g.tradeProblem(owner, give, get) != null) continue;
      return {'action': 'tradeOffer', 'to': owner, 'give': give.toJson(), 'get': get.toJson()};
    }
    return null;
  }

  /// A random swap: a random own square and/or money for a random square of
  /// another seat.
  Map<String, dynamic>? _randomOffer(PropertyGame g) {
    final a = g.currentSeat;
    final others = [for (final s in g.activeSeats) if (s != a) s];
    final to = others[rng.nextInt(others.length)];
    final theirs = g.ownedBy(to), mine = g.ownedBy(a);
    if (theirs.isEmpty) return null;
    final get = PropertyTradeSide(squares: [theirs[rng.nextInt(theirs.length)]]);
    final give = PropertyTradeSide(
        money: rng.nextInt(min(g.seats[a].cash, 300) + 1), squares: [if (mine.isNotEmpty) mine[rng.nextInt(mine.length)]]);
    if (g.tradeProblem(to, give, get) != null) return null;
    return {'action': 'tradeOffer', 'to': to, 'give': give.toJson(), 'get': get.toJson()};
  }
}

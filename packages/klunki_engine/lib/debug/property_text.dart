import 'dart:math';

import '../property.dart';
import '../property_bot.dart';

/// Text adapter and small line console for Baulöwe (KLD-060). It does not
/// extend [TextGame]: that one is built on the two-player `Game` interface,
/// this game has 2–6 seats. Seats are shown as `P1` … `P6`.
///
/// Commands: `roll`, `buy`, `decline`, `bid <n>`, `pass`, `build <sq>`,
/// `sell <sq>`, `mortgage <sq>`, `unmortgage <sq>`, `bail`, `card`, `end`,
/// `bankrupt`, `accept`, `reject`, `offer <seat> give <money> [sq,…] get
/// <money> [sq,…]`, `resign <seat>`; console only: `show`, `moves`,
/// `auto [n]`, `help`.
class PropertyText {
  final PropertyGame game;
  final Random _rng;
  late final PropertyBot _bot = PropertyBot(_rng);

  PropertyText({PropertyGame? game, int players = 3, int seed = 1, PropertyTheme? theme})
      : game = game ?? PropertyGame(playerCount: players, seed: seed, theme: theme),
        _rng = Random(seed);

  static const String title = 'Baulöwe';

  /// English working title.
  static const String englishTitle = 'Housing Corp';

  static const String help = 'roll | buy | decline | bid <n> | pass | build/sell/mortgage/unmortgage <square> | '
      'bail | card | end | bankrupt | accept | reject | offer <seat> give <money> [sq,sq] get <money> [sq,sq] | '
      'resign <seat> | show | moves | auto [n] | help';

  static String seatName(int? s) => s == null ? 'nobody' : 'P${s + 1}';

  String squareName(int i) => '$i ${game.theme.squares[i].name}';

  String get _pause => game.theme.squares[PropertyGame.pauseSquare].name;

  /// Seats, positions, owned squares and what the game waits for.
  String render() {
    final b = StringBuffer();
    for (var s = 0; s < game.playerCount; s++) {
      final seat = game.seats[s];
      final mark = s == game.currentSeat ? '>' : ' ';
      if (seat.out) {
        b.writeln('$mark${seatName(s)}  out');
        continue;
      }
      final owned = [
        for (final i in game.ownedBy(s))
          '$i${game.housesOn(i) == 5 ? 'H' : game.housesOn(i) > 0 ? '+${game.housesOn(i)}' : ''}'
              '${game.isMortgaged(i) ? 'm' : ''}'
      ];
      b.writeln('$mark${seatName(s)}  ${seat.cash} ${game.theme.currency}  on ${squareName(seat.pos)}'
          '${seat.inPause ? ' (in: $_pause)' : ''}'
          '${seat.freeCards.isEmpty ? '' : '  free cards: ${seat.freeCards.length}'}'
          '${owned.isEmpty ? '' : '  owns ${owned.join(' ')}'}');
    }
    if (game.pot > 0) b.writeln('Pot: ${game.pot} ${game.theme.currency}');
    b.write(status());
    return b.toString();
  }

  String status() {
    final r = game.result;
    if (r.isOver) {
      return r.winner != null
          ? '${seatName(r.winner)} wins (${r.reason})'
          : 'Draw between ${r.leaders.map(seatName).join(', ')} (${r.reason})';
    }
    final a = seatName(game.actor);
    return switch (game.phase) {
      PropertyPhase.roll => '$a to roll',
      PropertyPhase.buy => '$a may buy ${squareName(game.seats[game.actor!].pos)} '
          'for ${game.theme.squares[game.seats[game.actor!].pos].price}',
      PropertyPhase.auction => 'Auction for ${squareName(game.auction!.square)}: high ${game.auction!.high}'
          '${game.auction!.highSeat == null ? '' : ' by ${seatName(game.auction!.highSeat)}'}, $a to bid',
      PropertyPhase.trade => '$a answers the offer from ${seatName(game.trade!.from)}',
      PropertyPhase.debt => '$a owes ${game.debts.first.amount} and has to raise money',
      PropertyPhase.end => '$a may end the turn',
      PropertyPhase.over => '',
    };
  }

  /// [input] as a move map, or null if it is no move command.
  Map<String, dynamic>? parse(String input) {
    final w = input.trim().toLowerCase().split(RegExp(r'\s+'));
    int? n(int i) => w.length > i ? int.tryParse(w[i]) : null;
    Map<String, dynamic>? sq(String action) => n(1) == null ? null : {'action': action, 'square': n(1)};
    return switch (w.first) {
      'roll' => {'action': 'roll'},
      'buy' => {'action': 'buy'},
      'decline' => {'action': 'decline'},
      'bid' => n(1) == null ? null : {'action': 'bid', 'amount': n(1)},
      'pass' => {'action': 'pass'},
      'build' || 'sell' || 'mortgage' || 'unmortgage' => sq(w.first),
      'bail' => {'action': 'payBail'},
      'card' => {'action': 'useCard'},
      'end' => {'action': 'endTurn'},
      'bankrupt' => {'action': 'bankrupt'},
      'accept' => {'action': 'tradeAccept'},
      'reject' => {'action': 'tradeDecline'},
      'resign' => n(1) == null ? null : {'action': 'resign', 'seat': n(1)! - 1},
      'offer' => _parseOffer(w),
      _ => null,
    };
  }

  /// `offer <seat> give <money> [sq,sq] get <money> [sq,sq]`.
  static Map<String, dynamic>? _parseOffer(List<String> w) {
    final to = w.length > 1 ? int.tryParse(w[1]) : null;
    final gi = w.indexOf('give'), ge = w.indexOf('get');
    if (to == null || gi != 2 || ge < gi) return null;
    Map<String, dynamic>? side(List<String> parts) {
      if (parts.isEmpty || parts.length > 2) return null;
      final money = int.tryParse(parts[0]);
      final squares = parts.length == 2 ? parts[1].split(',').map(int.tryParse).toList() : <int?>[];
      if (money == null || squares.contains(null)) return null;
      return {if (money > 0) 'money': money, if (squares.isNotEmpty) 'squares': squares};
    }

    final give = side(w.sublist(gi + 1, ge)), get = side(w.sublist(ge + 1));
    if (give == null || get == null) return null;
    return {'action': 'tradeOffer', 'to': to - 1, 'give': give, 'get': get};
  }

  /// Inverse of [parse].
  String format(Map<String, dynamic> move) {
    String side(Object? json) {
      final m = (json as Map?) ?? const {};
      final sq = (m['squares'] as List?) ?? const [];
      return '${m['money'] ?? 0}${sq.isEmpty ? '' : ' ${sq.join(',')}'}';
    }

    return switch (move['action']) {
      'payBail' => 'bail',
      'useCard' => 'card',
      'endTurn' => 'end',
      'tradeAccept' => 'accept',
      'tradeDecline' => 'reject',
      'bid' => 'bid ${move['amount']}',
      'resign' => 'resign ${(move['seat'] as int) + 1}',
      'build' || 'sell' || 'mortgage' || 'unmortgage' => '${move['action']} ${move['square']}',
      'tradeOffer' => 'offer ${(move['to'] as int) + 1} give ${side(move['give'])} get ${side(move['get'])}',
      final a => '$a',
    };
  }

  /// One plain sentence per event of [event].
  String narrate(PropertyEvent event) => [for (final e in event.events) _sentence(e)].join(' ');

  String _sentence(Map<String, dynamic> e) {
    final who = seatName(e['seat'] as int?);
    return switch (e['type']) {
      'rolled' => 'Rolled ${(e['dice'] as List).join('+')}.',
      'moved' => 'Moves to ${squareName(e['to'] as int)}.',
      'salary' => '$who passes Start: +${e['amount']}.',
      'card' => 'Card: "${game.theme.card(e['id'])!.text}"',
      'collected' => '$who gets ${e['amount']}.',
      'pot' => '$who takes the pot: ${e['amount']}.',
      'paid' => '${seatName(e['debtor'] as int)} pays ${e['amount']} ${e['reason']} '
          'to ${e['creditor'] == null ? 'the bank' : seatName(e['creditor'] as int)}.',
      'bought' => '$who buys ${squareName(e['square'] as int)} for ${e['price']}.',
      'auction' => 'Auction for ${squareName(e['square'] as int)}.',
      'bid' => '$who bids ${e['amount']}.',
      'passed' => '$who passes.',
      'unsold' => 'Nobody bid: ${squareName(e['square'] as int)} stays with the bank.',
      'built' => '$who builds ${_building(e)} on ${squareName(e['square'] as int)}.',
      'sold' => '$who sells a house on ${squareName(e['square'] as int)} for ${e['amount']}.',
      'mortgaged' => '$who mortgages ${squareName(e['square'] as int)} for ${e['amount']}.',
      'unmortgaged' => '$who lifts the mortgage on ${squareName(e['square'] as int)} for ${e['amount']}.',
      'toPause' => '$who goes to $_pause.',
      'threeDoubles' => 'Third doubles in a row!',
      'leftPause' => 'Leaves $_pause (${e['by']}).',
      'stayInPause' => 'No doubles: stays in $_pause (try ${e['tries']}).',
      'tradeOffered' => '${seatName(e['from'] as int)} makes ${seatName(e['to'] as int)} an offer.',
      'tradeDeclined' => '${seatName(e['to'] as int)} declines the offer.',
      'traded' => '${seatName(e['from'] as int)} and ${seatName(e['to'] as int)} trade.',
      'bankrupt' => '$who is bankrupt.',
      'resigned' => '$who resigns.',
      'turn' => '$who\'s turn.',
      'over' => 'Game over: ${status()}.',
      final t => '[$t]',
    };
  }

  /// "a Haus (2)" or "a Hotel": the group's building names from the theme.
  String _building(Map<String, dynamic> e) {
    final g = game.theme.colourGroups[game.theme.squares[e['square'] as int].group];
    final n = e['houses'] as int;
    return n == 5 ? 'a ${g.big}' : 'a ${g.small} ($n)';
  }

  /// One console line: a move command or `show` / `moves` / `auto [n]` /
  /// `help`. Returns what to print.
  String handle(String line) {
    final w = line.trim().split(RegExp(r'\s+'));
    switch (w.first.toLowerCase()) {
      case '':
      case 'show':
        return render();
      case 'help':
        return help;
      case 'moves':
        return game.legalMoves.map(format).join(' | ');
      case 'auto':
        final n = w.length > 1 ? int.tryParse(w[1]) ?? 1 : 1;
        final out = <String>[];
        for (var i = 0; i < n && !game.isOver; i++) {
          final m = _bot.choose(game);
          final a = seatName(game.seatOf(m));
          out.add('$a: ${format(m)}  ${narrate(game.applyMove(m)!)}');
        }
        return [...out, render()].join('\n');
    }
    final move = parse(line);
    if (move == null) return 'Unknown command. $help';
    final mover = game.seatOf(move);
    final ev = game.applyMove(move);
    if (ev == null) return 'Not allowed now. ${status()}';
    return '${seatName(mover)}: ${narrate(ev)}\n${render()}';
  }
}

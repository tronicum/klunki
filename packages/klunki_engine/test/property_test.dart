import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// Baulöwe (KLD-060 step 1): board data, rules, bots, invariants.
void main() {
  Map<String, dynamic> mv(String action, [Map<String, dynamic> more = const {}]) => {'action': action, ...more};

  /// Applies [moves] (actions or maps) and expects every one to be accepted.
  void play(PropertyGame g, List<Object> moves) {
    for (final m in moves) {
      final move = m is String ? mv(m) : m as Map<String, dynamic>;
      expect(g.applyMove(move), isNotNull, reason: '$move in ${g.toJson()}');
    }
  }

  /// Applies [move] and expects it to be refused without a state change.
  void refused(PropertyGame g, Map<String, dynamic> move) {
    final before = jsonEncode(g.toJson());
    final n = g.history.length;
    expect(g.applyMove(move), isNull, reason: '$move');
    expect(jsonEncode(g.toJson()), before, reason: '$move');
    expect(g.history.length, n);
  }

  final board = PropertyTheme.berlin.squares;
  final groups = PropertyTheme.berlin.groups;

  int total(PropertyGame g) => g.seats.fold(0, (s, p) => s + p.cash) + g.bankBalance + g.pot;

  group('board', () {
    test('40 squares in classic layout positions, own names', () {
      expect(board, hasLength(40));
      for (var i = 0; i < 40; i++) {
        expect(board[i].index, i);
      }
      List<int> of(PropertyKind k) => [for (final s in board) if (s.kind == k) s.index];
      expect(of(PropertyKind.start), [0]);
      expect(of(PropertyKind.pause), [10]);
      expect(of(PropertyKind.free), [20]);
      expect(of(PropertyKind.goToPause), [30]);
      expect(of(PropertyKind.station), [5, 15, 25, 35]);
      expect(of(PropertyKind.utility), [12, 28]);
      expect(of(PropertyKind.tax), [4, 38]);
      expect(of(PropertyKind.surprise), [7, 22, 36]);
      expect(of(PropertyKind.neighbourhood), [2, 17, 33]);
      expect(of(PropertyKind.street), hasLength(22));
      expect(groups.map((g) => g.length), [2, 3, 3, 3, 3, 3, 3, 2]);
      final names = [for (final s in board) if (s.isOwnable) s.name];
      expect(names.toSet(), hasLength(names.length));
    });

    test('prices and rents grow along the board', () {
      var lastPrice = 0;
      for (final g in groups) {
        for (final i in g) {
          final s = board[i];
          expect(s.price, greaterThanOrEqualTo(lastPrice));
          lastPrice = s.price;
          expect(s.rents, hasLength(6));
          for (var k = 1; k < 6; k++) {
            expect(s.rents[k], greaterThan(s.rents[k - 1]));
          }
          expect(s.houseCost, greaterThan(0));
        }
      }
      expect(board[5].unmortgageCost, 110);
      expect(board[1].mortgageValue, 30);
    });

    test('two decks of 16 cards with unique ids and valid targets', () {
      for (final t in PropertyTheme.builtIn) {
        for (final d in PropertyDeck.values) {
          expect(t.cards.where((c) => c.deck == d), hasLength(16));
          expect(t.cards.where((c) => c.deck == d && c.kind == PropertyCardKind.freeCard), hasLength(1));
        }
        expect(t.cards.map((c) => c.id).toSet(), hasLength(32));
      }
    });
  });

  group('themes', () {
    test('the built-in themes are valid, distinct and round-trip through JSON', () {
      expect(PropertyTheme.byId(null), same(PropertyTheme.berlin));
      expect(PropertyTheme.byId('fantasie')!.title, 'Fantasiestadt');
      expect(PropertyTheme.byId('nope'), isNull);
      final hashes = <String>{};
      for (final t in PropertyTheme.builtIn) {
        expect(t.validate(), isEmpty, reason: t.id);
        final back = PropertyTheme.fromJson(jsonDecode(jsonEncode(t.toJson())));
        expect(back.validate(), isEmpty);
        expect(jsonEncode(back.toJson()), jsonEncode(t.toJson()));
        expect(back.contentHash, t.contentHash);
        hashes.add(t.contentHash);
        for (final s in t.squares) {
          expect(s.kind, propertyLayout[s.index]);
          expect(s.group, propertyLayoutGroups[s.index]);
        }
      }
      expect(hashes, hasLength(PropertyTheme.builtIn.length));
    });

    test('Berlin: own street selection, Ring stations, building names per group', () {
      final t = PropertyTheme.berlin;
      final names = [for (final s in t.squares) s.name];
      // The original game's classic German street names stay out.
      for (final banned in [
        'Badstraße', 'Turmstraße', 'Chausseestraße', 'Elisenstraße', 'Poststraße', 'Seestraße', 'Hafenstraße',
        'Neue Straße', 'Münchner Straße', 'Wiener Straße', 'Berliner Straße', 'Theaterstraße', 'Museumstraße',
        'Opernplatz', 'Lessingstraße', 'Schillerstraße', 'Goethestraße', 'Rathausplatz', 'Hauptstraße',
        'Bahnhofstraße', 'Parkstraße', 'Schlossallee', 'Südbahnhof', 'Westbahnhof', 'Nordbahnhof', //
      ]) {
        expect(names, isNot(contains(banned)));
      }
      expect([for (final i in [5, 15, 25, 35]) names[i]], ['Südkreuz', 'Westkreuz', 'Hauptbahnhof', 'Ostkreuz']);
      expect([for (final i in t.groups[4]) names[i]], ['Revaler Straße', 'Alt-Stralau', 'Am Wriezener Bahnhof']);
      expect(t.colourGroups[4].big, 'Club');
      expect([for (final i in t.groups[0]) names[i]], ['Skalitzer Straße', 'Schlesische Straße']);
      expect([t.colourGroups[0].small, t.colourGroups[0].big], ['Späti', 'Späti-Palast']);
      expect([for (final i in t.groups[1]) names[i]], ['Krossener Straße', 'Wühlischstraße', 'Simon-Dach-Straße']);
      expect([t.colourGroups[1].small, t.colourGroups[1].big], ['Bar', 'Kiezkneipe']);
      expect([for (final i in t.groups[3]) names[i]], ['Arkonaplatz', 'Straße des 17. Juni', 'Mauerpark']);
      expect(t.colourGroups.where((g) => g.small == 'Haus').map((g) => g.name), ['Prachtstraßen']);
      // Revision 3: the short names for the board (KLD-060).
      expect(t.revision, 3);
      expect(t.squares[37].shortName, 'Kurfürstend.', reason: 'the most expensive group (maintainer)');
      expect(t.squares[34].shortName, 'Museums-Insel', reason: 'breaks after its own hyphen');
      expect(t.squares[21].shortName, 'Revaler Straße', reason: 'fits in full');
      expect(t.squares[19].shortName, 'Mauerpark', reason: 'no short form: the name');
      expect(t.pauseAt, 'steht im Stau auf der A100');
      expect(t.pauseTo, 'in den Stau auf der A100');
      expect(PropertyTheme.fromJson(t.toJson()).pauseTo, t.pauseTo, reason: 'round trip');
      for (final s in t.squares) {
        if (s.short case final short?) {
          expect(short.replaceAll('-', '').length, lessThanOrEqualTo(s.name.replaceAll('-', '').length), reason: s.name);
        }
      }
      expect(t.colourGroups[5].small, 'Kindercafé');
      expect(t.colourGroups.map((g) => g.note), everyElement(isNotEmpty));
      final ownable = [for (final s in t.squares) if (s.isOwnable) s.name];
      expect(ownable.toSet(), hasLength(ownable.length));
    });

    test('validate finds broken themes; the game refuses them', () {
      Map<String, dynamic> json() => jsonDecode(jsonEncode(PropertyTheme.berlin.toJson())) as Map<String, dynamic>;
      List<String> problems(void Function(Map<String, dynamic> j) edit) {
        final j = json();
        edit(j);
        return PropertyTheme.fromJson(j).validate();
      }

      Map<String, dynamic> sq(Map<String, dynamic> j, int i) => (j['squares'] as List)[i] as Map<String, dynamic>;
      List cards(Map<String, dynamic> j) => (j['decks'] as Map)['surprise']['cards'] as List;
      expect(problems((_) {}), isEmpty);
      expect(problems((j) => (j['squares'] as List).removeLast()), isNotEmpty);
      expect(problems((j) => sq(j, 1)['kind'] = 'tax'), isNotEmpty);
      expect(problems((j) => sq(j, 1)['rents'] = [5, 4, 30, 90, 160, 250]), isNotEmpty);
      expect(problems((j) => sq(j, 1)['price'] = 0), isNotEmpty);
      expect(problems((j) => sq(j, 0)['price'] = 10), isNotEmpty);
      expect(problems((j) => sq(j, 1)['name'] = ''), isNotEmpty);
      expect(problems((j) => sq(j, 1)['short'] = ''), isNotEmpty);
      expect(problems((j) => sq(j, 1)['short'] = 'Skalitzer Straße, lang'), isNotEmpty);
      expect(problems((j) => sq(j, 19)['short'] = 'Mauerp.'), isEmpty);
      expect(() => PropertyTheme.fromJson(json()..update('squares', (l) => [for (final (i, e) in (l as List).indexed) i == 1 ? {...e as Map, 'short': 3} : e])),
          throwsFormatException);
      expect(problems((j) => sq(j, 1)['name'] = 'x' * 31), isNotEmpty);
      expect(problems((j) => (j['groups'] as List)[0]['bigIcon'] = 'Haus!'), isNotEmpty);
      expect(problems((j) => (j['groups'] as List).removeLast()), isNotEmpty);
      expect(problems((j) => cards(j)[0]['value'] = 40), isNotEmpty);
      expect(problems((j) => cards(j)[1]['id'] = 's01'), isNotEmpty);
      expect(problems((j) => cards(j)[2]['text'] = 'x' * 201), isNotEmpty);
      expect(problems((j) => cards(j).removeRange(0, 10)), isNotEmpty);
      expect(problems((j) => j['id'] = 'Berlin City'), isNotEmpty);
      for (final bad in <void Function(Map<String, dynamic>)>[
        (j) => j['format'] = 2,
        (j) => sq(j, 1)['kind'] = 'castle',
        (j) => sq(j, 1)['price'] = '60',
        (j) => cards(j)[0]['kind'] = 'teleport',
        (j) => j['squares'] = 'all',
      ]) {
        final j = json();
        bad(j);
        expect(() => PropertyTheme.fromJson(j), throwsFormatException);
      }
      final j = json();
      sq(j, 1)['price'] = 0;
      expect(() => PropertyGame(theme: PropertyTheme.fromJson(j)), throwsArgumentError);
    });

    test('a game with another theme', () {
      final g = PropertyGame(theme: PropertyTheme.byId('fantasie'), dice: [1, 2]);
      play(g, ['roll', 'buy']);
      expect(g.theme.squares[g.seats[0].pos].name, 'Pfützengasse');
      expect(g.toJson()['theme'], 'fantasie');
    });
  });

  group('setup', () {
    test('2–6 players, positive round limit', () {
      for (final n in [1, 7, 0]) {
        expect(() => PropertyGame(playerCount: n), throwsArgumentError);
      }
      expect(() => PropertyGame(maxRounds: 0), throwsArgumentError);
      expect(PropertyGame().maxRounds, isNull); // default: until one is left
      final g = PropertyGame(playerCount: 6, seed: 3);
      expect(g.seats.map((s) => s.cash), List.filled(6, 1500));
      expect(g.phase, PropertyPhase.roll);
      expect(g.actor, 0);
      expect(g.legalMoves, [mv('roll')]);
    });

    test('same seed, same game; the view hides seed and deck order', () {
      List<int> rolls(int seed) {
        final g = PropertyGame(seed: seed, playerCount: 3);
        final bot = PropertyBot(Random(1));
        final out = <int>[];
        for (var i = 0; i < 200 && !g.isOver; i++) {
          final ev = g.applyMove(bot.choose(g))!;
          for (final e in ev.events) {
            if (e['type'] == 'rolled') out.addAll((e['dice'] as List).cast<int>());
          }
        }
        return out;
      }

      expect(rolls(5), rolls(5));
      expect(rolls(5), isNot(rolls(6)));
      final json = PropertyGame(seed: 12345).toJson();
      expect(jsonEncode(json), isNot(contains('12345')));
      expect(json.containsKey('seed'), isFalse);
      expect(json['decks'], {'surprise': 16, 'neighbourhood': 16});
    });
  });

  group('moving and buying', () {
    test('roll, buy, end turn', () {
      final g = PropertyGame(dice: [1, 2]);
      play(g, ['roll']);
      expect(g.seats[0].pos, 3);
      expect(g.phase, PropertyPhase.buy);
      expect(g.legalMoves, containsAll([mv('buy'), mv('decline')]));
      refused(g, mv('endTurn'));
      play(g, ['buy']);
      expect(g.ownerOf(3), 0);
      expect(g.seats[0].cash, 1430);
      expect(g.phase, PropertyPhase.end);
      play(g, ['endTurn']);
      expect(g.currentSeat, 1);
      expect(g.phase, PropertyPhase.roll);
    });

    test('passing start pays the salary', () {
      final g = PropertyGame(dice: [4, 6])..debugSetCash(0, 1500, pos: 35);
      play(g, ['roll']);
      expect(g.seats[0].pos, 5);
      expect(g.seats[0].cash, 1700);
    });

    test('doubles roll again; the third doubles go to the pause', () {
      final g = PropertyGame(dice: [2, 2, 3, 3, 4, 4]);
      play(g, ['roll']);
      expect(g.seats[0].pos, 4);
      expect(g.seats[0].cash, 1300); // tax
      expect(g.phase, PropertyPhase.roll);
      play(g, ['roll']);
      expect(g.seats[0].pos, 10);
      expect(g.seats[0].inPause, isFalse); // only visiting
      expect(g.phase, PropertyPhase.roll);
      play(g, ['roll']);
      expect(g.seats[0].pos, 10);
      expect(g.seats[0].inPause, isTrue);
      expect(g.phase, PropertyPhase.end);
    });

    test('the go-to-pause square', () {
      final g = PropertyGame(dice: [1, 2])..debugSetCash(0, 1500, pos: 27);
      play(g, ['roll']);
      expect(g.seats[0].pos, 10);
      expect(g.seats[0].inPause, isTrue);
      expect(g.seats[0].cash, 1500); // no salary
    });
  });

  group('pause', () {
    PropertyGame inPause(List<int> dice) {
      final g = PropertyGame(dice: [1, 2, 4, 6, ...dice])..debugSetCash(0, 1500, pos: 27);
      play(g, ['roll', 'endTurn', 'roll', 'endTurn']); // P2 visits square 10
      expect(g.seats[0].inPause, isTrue);
      return g;
    }

    test('three failed tries: pay the bail and move', () {
      final g = inPause([1, 2, 4, 6, 1, 2, 3, 4, 1, 3]);
      play(g, ['roll']);
      expect(g.seats[0].pauseTries, 1);
      expect(g.phase, PropertyPhase.end);
      play(g, ['endTurn', 'roll', 'endTurn', 'roll']); // P2 to 20, P1 try 2
      expect(g.seats[0].pauseTries, 2);
      play(g, ['endTurn', 'roll', 'decline', 'pass', 'pass']); // P2 to 27: unsold
      expect(g.ownerOf(27), isNull);
      play(g, ['endTurn', 'roll']);
      expect(g.seats[0].inPause, isFalse);
      expect(g.seats[0].pos, 14);
      expect(g.seats[0].cash, 1450);
      expect(g.phase, PropertyPhase.buy);
    });

    test('doubles leave the pause without another roll', () {
      final g = inPause([3, 3]);
      play(g, ['roll', 'buy']);
      expect(g.seats[0].pos, 16);
      expect(g.phase, PropertyPhase.end);
    });

    test('paying the bail, then a normal roll', () {
      final g = inPause([1, 2]);
      refused(g, mv('useCard'));
      play(g, ['payBail']);
      expect(g.seats[0].cash, 1450);
      expect(g.phase, PropertyPhase.roll);
      refused(g, mv('payBail'));
      play(g, ['roll']);
      expect(g.seats[0].pos, 13);
    });

    test('a free card is kept, used and goes back under its deck', () {
      final g = PropertyGame(dice: [1, 1, 1, 1, 4, 6], deckOrder: {
        PropertyDeck.neighbourhood: ['n05', 'n06']
      });
      play(g, ['roll']);
      expect(g.seats[0].freeCards, ['n05']);
      expect(g.toJson()['decks']['neighbourhood'], 15);
      g.debugSetCash(0, 1500, pos: 15);
      play(g, ['roll']); // to 17: "Ab in die Auszeit!"
      expect(g.seats[0].inPause, isTrue);
      play(g, ['endTurn', 'roll', 'endTurn']);
      expect(g.legalMoves, anyElement(equals(mv('useCard'))));
      play(g, ['useCard']);
      expect(g.seats[0].inPause, isFalse);
      expect(g.seats[0].freeCards, isEmpty);
      expect(g.toJson()['decks']['neighbourhood'], 16);
    });
  });

  group('rent', () {
    test('streets: base, whole group double, houses, hotel; mortgaged: none', () {
      final g = PropertyGame(dice: [1, 2]);
      g.debugSetSquare(3, 1);
      final base = board[3].rents[0];
      expect(g.rentFor(3), base);
      g.debugSetSquare(1, 1);
      expect(g.rentFor(3), base * 2);
      g.debugSetSquare(1, 1, mortgaged: true);
      expect(g.rentFor(3), base * 2);
      expect(g.rentFor(1), 0);
      for (var h = 1; h <= 5; h++) {
        g.debugSetSquare(3, 1, houses: h);
        expect(g.rentFor(3), board[3].rents[h]);
      }
      g.debugSetSquare(3, 1, houses: 2);
      play(g, ['roll']);
      expect(g.seats[0].cash, 1500 - board[3].rents[2]);
      expect(g.seats[1].cash, 1500 + board[3].rents[2]);
      expect(g.phase, PropertyPhase.end);
    });

    test('stations by count, utilities by dice', () {
      final g = PropertyGame(dice: [6, 6]);
      for (final (i, n) in [(5, 25), (15, 50), (25, 100), (35, 200)]) {
        g.debugSetSquare(i, 1);
        expect(g.rentFor(5), n);
      }
      g.debugSetSquare(12, 1);
      play(g, ['roll']);
      expect(g.seats[0].cash, 1500 - 48);
      expect(g.rentFor(12), 48);
      g.debugSetSquare(28, 1);
      expect(g.rentFor(12), 120);
      expect(g.rentFor(12, diceTotal: 3), 30);
    });
  });

  group('building and mortgages', () {
    test('even building and selling, hotel at 5, group rules', () {
      final g = PropertyGame();
      g.debugSetSquare(1, 0);
      expect(g.canBuild(0, 1), isFalse); // group incomplete
      refused(g, mv('build', {'square': 1}));
      g.debugSetSquare(3, 0);
      play(g, [mv('build', {'square': 1})]);
      expect(g.seats[0].cash, 1450);
      refused(g, mv('build', {'square': 1})); // uneven
      play(g, [mv('build', {'square': 3}), mv('build', {'square': 1})]);
      refused(g, mv('sell', {'square': 3})); // uneven selling
      refused(g, mv('mortgage', {'square': 3})); // houses in the group
      play(g, [mv('sell', {'square': 1})]);
      expect(g.seats[0].cash, 1500 - 150 + 25);
      for (var k = 0; k < 4; k++) {
        play(g, [mv('build', {'square': 1}), mv('build', {'square': 3})]);
      }
      expect([g.housesOn(1), g.housesOn(3)], [5, 5]);
      refused(g, mv('build', {'square': 1}));
      refused(g, mv('build', {'square': 1, 'seat': 1}));
      for (final bad in [-1, 40, '3', null]) {
        refused(g, mv('build', {'square': bad}));
      }
    });

    test('no building with a mortgage in the group; lifting costs 10 % more', () {
      final g = PropertyGame();
      g
        ..debugSetSquare(1, 0)
        ..debugSetSquare(3, 0)
        ..debugSetSquare(5, 0);
      play(g, [mv('mortgage', {'square': 1})]);
      expect(g.seats[0].cash, 1530);
      refused(g, mv('build', {'square': 3}));
      refused(g, mv('mortgage', {'square': 1}));
      play(g, [mv('mortgage', {'square': 5}), mv('unmortgage', {'square': 5})]);
      expect(g.seats[0].cash, 1530 + 100 - 110);
      refused(g, mv('unmortgage', {'square': 5}));
    });

    test('management only for the player whose turn it is', () {
      final g = PropertyGame();
      g
        ..debugSetSquare(1, 1)
        ..debugSetSquare(3, 1);
      refused(g, mv('build', {'square': 1}));
      refused(g, mv('build', {'square': 1, 'seat': 1}));
      refused(g, mv('mortgage', {'square': 1, 'seat': 1}));
      expect(g.canBuild(1, 1), isFalse);
    });
  });

  group('auction', () {
    test('open bids in seat order after the decliner; the last bidder buys', () {
      final g = PropertyGame(playerCount: 3, dice: [1, 2]);
      play(g, ['roll', 'decline']);
      expect(g.phase, PropertyPhase.auction);
      expect(g.auction!.bidders, [1, 2, 0]);
      expect(g.actor, 1);
      refused(g, mv('bid', {'amount': 9}));
      refused(g, mv('bid', {'amount': 1501}));
      refused(g, mv('bid', {'amount': '20'}));
      refused(g, mv('buy'));
      play(g, [mv('bid', {'amount': 10})]);
      refused(g, mv('bid', {'amount': 10}));
      play(g, [mv('bid', {'amount': 50}), 'pass']);
      expect(g.actor, 1);
      play(g, ['pass']);
      expect(g.ownerOf(3), 2);
      expect(g.seats[2].cash, 1450);
      expect(g.phase, PropertyPhase.end);
      expect(g.actor, 0);
    });

    test('everyone passes: the bank keeps it; a lone bidder may still bid', () {
      final g = PropertyGame(dice: [1, 2, 1, 2]);
      play(g, ['roll', 'decline', 'pass', 'pass']);
      expect(g.ownerOf(3), isNull);
      expect(g.phase, PropertyPhase.end);
      play(g, ['endTurn', 'roll', 'decline', 'pass']);
      expect(g.actor, 1);
      play(g, [mv('bid', {'amount': 10})]);
      expect(g.ownerOf(3), 1);
      expect(g.seats[1].cash, 1490);
    });
  });

  group('debts and bankruptcy', () {
    test('raising money pays the debt automatically', () {
      final g = PropertyGame(dice: [1, 2]);
      g
        ..debugSetSquare(1, 1, houses: 1)
        ..debugSetSquare(3, 1, houses: 1)
        ..debugSetSquare(39, 0)
        ..debugSetCash(0, 10);
      play(g, ['roll']);
      final rent = board[3].rents[1];
      expect(g.phase, PropertyPhase.debt);
      expect(g.debts.single.amount, rent);
      expect(g.legalMoves, [mv('mortgage', {'square': 39})]);
      refused(g, mv('bankrupt')); // mortgaging can still pay
      refused(g, mv('endTurn'));
      refused(g, mv('unmortgage', {'square': 39}));
      play(g, [mv('mortgage', {'square': 39})]);
      expect(g.debts, isEmpty);
      expect(g.seats[0].cash, 10 + 200 - rent);
      expect(g.phase, PropertyPhase.end);
    });

    test('bankrupt to a player: houses sold, everything else goes to the creditor', () {
      final g = PropertyGame(playerCount: 3, dice: [1, 2]);
      g
        ..debugSetSquare(1, 1, houses: 5)
        ..debugSetSquare(3, 1, houses: 5)
        ..debugSetSquare(6, 0)
        ..debugSetSquare(8, 0)
        ..debugSetSquare(9, 0, houses: 0)
        ..debugSetSquare(39, 0, mortgaged: true)
        ..debugSetCash(0, 100);
      play(g, ['roll']);
      expect(g.phase, PropertyPhase.debt);
      play(g, ['bankrupt']);
      expect(g.seats[0].out, isTrue);
      expect(g.seats[1].cash, 1600);
      expect([6, 8, 9, 39].map(g.ownerOf), [1, 1, 1, 1]);
      expect(g.isMortgaged(39), isTrue);
      expect(g.currentSeat, 1);
      expect(g.isOver, isFalse);
      expect(total(g), 3 * 1500);
    });

    test('someone else owes money in my turn (birthday card)', () {
      final g = PropertyGame(playerCount: 3, dice: [1, 1], deckOrder: {
        PropertyDeck.neighbourhood: ['n02']
      });
      g
        ..debugSetCash(1, 5)
        ..debugSetSquare(19, 1, mortgaged: true);
      play(g, ['roll']);
      expect(g.phase, PropertyPhase.debt);
      expect(g.actor, 1);
      expect(g.debts.map((d) => d.debtor), [1, 2]);
      refused(g, mv('roll'));
      refused(g, mv('bankrupt', {'seat': 0}));
      play(g, [mv('bankrupt', {'seat': 1})]);
      expect(g.ownerOf(19), 0);
      expect(g.seats[0].cash, 1500 + 5 + 10);
      expect(g.seats[2].cash, 1490);
      expect(g.phase, PropertyPhase.roll); // doubles
      expect(g.currentSeat, 0);
    });

    test('bankrupt to the bank: properties return unmortgaged; last one wins', () {
      final g = PropertyGame(dice: [2, 2]);
      g
        ..debugSetSquare(39, 0, mortgaged: true)
        ..debugSetCash(0, 0);
      play(g, ['roll']); // tax 200
      play(g, ['bankrupt']);
      expect(g.ownerOf(39), isNull);
      expect(g.isMortgaged(39), isFalse);
      expect(g.isOver, isTrue);
      expect(g.propertyResult.winner, 1);
      expect(g.propertyResult.code, 'property.lastSolvent');
      expect(g.phase, PropertyPhase.over);
      expect(g.legalMoves, isEmpty);
      refused(g, mv('roll'));
    });
  });

  group('bankruptcy only when unavoidable', () {
    test('sell and mortgage first; bankrupt only when even that cannot pay', () {
      final g = PropertyGame(dice: [1, 3, 1, 3, 1, 3]);
      g
        ..debugSetSquare(1, 0, houses: 1)
        ..debugSetSquare(3, 0, houses: 1)
        ..debugSetCash(0, 100);
      expect(g.raisable(0), 100 + 25 + 25 + 30 + 35);
      play(g, ['roll']); // tax 200
      expect(g.phase, PropertyPhase.debt);
      expect(g.canDeclareBankruptcy, isFalse);
      refused(g, mv('bankrupt'));
      expect(g.legalMoves.map((m) => m['action']), isNot(contains('bankrupt')));
      play(g, [
        mv('sell', {'square': 1}),
        mv('sell', {'square': 3}),
        mv('mortgage', {'square': 1}),
        mv('mortgage', {'square': 3}),
      ]);
      expect(g.debts, isEmpty);
      expect(g.seats[0].cash, 15);
      play(g, ['endTurn', 'roll', 'endTurn']);
      g.debugSetCash(0, 0, pos: 0);
      play(g, ['roll']); // tax 200 with nothing left to raise
      expect(g.canDeclareBankruptcy, isTrue);
      expect(g.legalMoves, [mv('bankrupt')]);
      play(g, ['bankrupt']);
      expect(g.propertyResult.winner, 1);
    });
  });

  group('free square house rules', () {
    test('default: nothing happens', () {
      final g = PropertyGame(dice: [4, 6])..debugSetCash(0, 1500, pos: 10);
      expect(g.freeSquare, PropertyFreeSquare.none);
      play(g, ['roll']);
      expect(g.seats[0].pos, 20);
      expect(g.seats[0].cash, 1500);
      expect(g.pot, 0);
      expect(g.toJson().containsKey('pot'), isFalse);
    });

    test('pot: taxes and card fines go in, landing takes it; rent does not', () {
      final g = PropertyGame(freeSquare: PropertyFreeSquare.pot, dice: [1, 3, 3, 4, 4, 6], deckOrder: {
        PropertyDeck.surprise: ['s15']
      });
      play(g, ['roll', 'endTurn']); // P1: tax 200
      expect(g.pot, 200);
      expect(g.bankBalance, 0);
      play(g, ['roll']); // P2 to 7: card fine 20
      expect(g.pot, 220);
      play(g, ['endTurn']);
      g.debugSetCash(0, g.seats[0].cash, pos: 10);
      play(g, ['roll']); // P1 to 20
      expect(g.seats[0].cash, 1300 + 220);
      expect(g.pot, 0);
      expect(total(g), 3000);
      expect(g.toJson()['pot'], 0);
    });

    test('pot with a seed: starts with it and is refilled', () {
      final g = PropertyGame(freeSquare: PropertyFreeSquare.potWithSeed, dice: [1, 3, 4, 6]);
      expect(g.pot, 500);
      expect(g.bankBalance, -500);
      expect(total(g), 3000);
      play(g, ['roll', 'endTurn']);
      g.debugSetCash(1, 1500, pos: 10);
      play(g, ['roll']);
      expect(g.seats[1].cash, 1500 + 700);
      expect(g.pot, 500);
      expect(total(g), 3000);
    });

    test('fixed bonus from the bank; amounts are checked', () {
      for (final (amount, expected) in [(null, 200), (400, 400)]) {
        final g = PropertyGame(freeSquare: PropertyFreeSquare.fixedBonus, freeSquareAmount: amount, dice: [4, 6])
          ..debugSetCash(0, 1500, pos: 10);
        play(g, ['roll']);
        expect(g.seats[0].cash, 1500 + expected);
        expect(g.pot, 0);
      }
      expect(() => PropertyGame(freeSquare: PropertyFreeSquare.fixedBonus, freeSquareAmount: -1), throwsArgumentError);
      expect(() => PropertyGame(freeSquareAmount: 5001), throwsArgumentError);
      expect(PropertyFreeSquare.byName('potWithSeed'), PropertyFreeSquare.potWithSeed);
    });
  });

  group('more house rules', () {
    test('double salary only when landing exactly on Start', () {
      for (final (on, steps, cash) in [(false, [2, 3], 1700), (true, [2, 3], 1900), (true, [4, 6], 1700)]) {
        final g = PropertyGame(doubleStart: on, dice: steps)..debugSetCash(0, 1500, pos: 35);
        play(g, ['roll']);
        expect(g.seats[0].cash, cash, reason: 'doubleStart $on, dice $steps');
        expect(total(g), 3000);
      }
    });

    test('no rent while the owner sits in the pause', () {
      for (final on in [false, true]) {
        final g = PropertyGame(noRentInPause: on, dice: [1, 2, 1, 2])
          ..debugSetSquare(3, 0)
          ..debugSetCash(0, 1500, pos: 27);
        play(g, ['roll', 'endTurn']); // owner P1 to the pause
        expect(g.seats[0].inPause, isTrue);
        play(g, ['roll']); // P2 lands on P1's street
        final rent = board[3].rents[0];
        expect(g.seats[1].cash, on ? 1500 : 1500 - rent);
        expect(g.rentFor(3), on ? 0 : rent);
      }
    });

    test("a bankrupt's properties are auctioned (not on a resign)", () {
      final g = PropertyGame(playerCount: 3, bankruptAuction: true, dice: [1, 3])
        ..debugSetSquare(37, 0, mortgaged: true)
        ..debugSetSquare(39, 0, mortgaged: true)
        ..debugSetCash(0, 0);
      play(g, ['roll', 'bankrupt']); // tax 200, nothing to raise
      expect(g.currentSeat, 1);
      expect(g.phase, PropertyPhase.auction);
      expect(g.auction!.square, 37);
      expect(g.auction!.landing, isFalse);
      expect(g.auction!.bidders, [1, 2]);
      expect(g.toJson()['pendingAuctions'], [39]);
      play(g, [mv('bid', {'amount': 100}), 'pass']);
      expect(g.ownerOf(37), 1);
      expect(g.isMortgaged(37), isFalse);
      expect(g.auction!.square, 39);
      play(g, ['pass', mv('bid', {'amount': 10})]);
      expect(g.ownerOf(39), 2);
      expect(g.phase, PropertyPhase.roll);
      expect(g.actor, 1);
      expect(total(g), 3 * 1500);

      final r = PropertyGame(playerCount: 3, bankruptAuction: true)..debugSetSquare(39, 2);
      play(r, [mv('resign', {'seat': 2})]);
      expect(r.ownerOf(39), isNull);
      expect(r.phase, PropertyPhase.roll);
    });

    test('without the toggle a bankrupt\'s properties just go back to the bank', () {
      final g = PropertyGame(playerCount: 3, dice: [1, 3])
        ..debugSetSquare(39, 0, mortgaged: true)
        ..debugSetCash(0, 0);
      play(g, ['roll', 'bankrupt']);
      expect(g.ownerOf(39), isNull);
      expect(g.phase, PropertyPhase.roll);
    });
  });

  group('cards', () {
    test('advance to start, back 3, repairs, pay each', () {
      final g = PropertyGame(playerCount: 3, dice: [3, 4, 1, 2], deckOrder: {
        PropertyDeck.surprise: ['s01', 's13']
      });
      play(g, ['roll']);
      expect(g.seats[0].pos, 0);
      expect(g.seats[0].cash, 1700);
      play(g, ['endTurn']);
      g.debugSetCash(1, 1500, pos: 4);
      play(g, ['roll']); // to 7: pay everyone 25
      expect(g.seats.map((s) => s.cash), [1725, 1450, 1525]);
      final h = PropertyGame(dice: [3, 4], deckOrder: {
        PropertyDeck.surprise: ['s07']
      });
      play(h, ['roll']);
      expect(h.seats[0].pos, 4);
      expect(h.seats[0].cash, 1300);
      final r = PropertyGame(dice: [3, 4], deckOrder: {
        PropertyDeck.surprise: ['s14']
      });
      r
        ..debugSetSquare(1, 0, houses: 5)
        ..debugSetSquare(3, 0, houses: 2);
      play(r, ['roll']);
      expect(r.seats[0].cash, 1500 - 100 - 50);
    });

    test('nearest station and a to-pause card', () {
      final g = PropertyGame(dice: [3, 4, 1, 2], deckOrder: {
        PropertyDeck.surprise: ['s05', 's08']
      });
      play(g, ['roll']);
      expect(g.seats[0].pos, 15);
      expect(g.phase, PropertyPhase.buy);
      play(g, ['decline', 'pass', 'pass', 'endTurn']);
      g.debugSetCash(1, 1500, pos: 19);
      play(g, ['roll']);
      expect(g.seats[1].inPause, isTrue);
      expect(g.seats[1].pos, 10);
    });
  });

  group('trades', () {
    test('offer, accept, decline; at most 3 offers a turn', () {
      final g = PropertyGame(playerCount: 3);
      g
        ..debugSetSquare(1, 0)
        ..debugSetSquare(3, 1);
      final offer = mv('tradeOffer', {
        'to': 1,
        'give': {'money': 50, 'squares': [1]},
        'get': {'squares': [3]},
      });
      play(g, [offer]);
      expect(g.phase, PropertyPhase.trade);
      expect(g.actor, 1);
      refused(g, mv('roll'));
      refused(g, mv('tradeAccept', {'seat': 0}));
      expect(g.tradeOffersLeft, 2);
      play(g, ['tradeAccept']);
      expect([g.ownerOf(1), g.ownerOf(3)], [1, 0]);
      expect([g.seats[0].cash, g.seats[1].cash], [1450, 1550]);
      expect(g.phase, PropertyPhase.roll);
      final back = mv('tradeOffer', {
        'to': 1,
        'get': {'squares': [1]},
      });
      play(g, [back, 'tradeDecline']);
      expect(g.ownerOf(1), 1);
      play(g, [back, 'tradeDecline']);
      refused(g, back); // fourth offer this turn
      expect(g.tradeOffersLeft, 0);
      play(g, ['roll']);
    });

    test('invalid offers are refused', () {
      final g = PropertyGame(playerCount: 3);
      g
        ..debugSetSquare(1, 0)
        ..debugSetSquare(3, 0, houses: 0)
        ..debugSetSquare(6, 1)
        ..debugSetSquare(8, 1, houses: 1)
        ..debugSetSquare(9, 1, houses: 1);
      for (final bad in <Map<String, dynamic>>[
        {'to': 0, 'give': {'money': 1}},
        {'to': 1},
        {'to': 3, 'give': {'money': 1}},
        {'to': 1, 'give': {'money': 1501}},
        {'to': 1, 'get': {'money': 1501}},
        {'to': 1, 'give': {'squares': [6]}},
        {'to': 1, 'get': {'squares': [1]}},
        {'to': 1, 'get': {'squares': [6]}}, // houses in its group
        {'to': 1, 'give': {'cards': 1}},
        {'to': 1, 'give': {'money': -5}},
        {'to': 1, 'give': {'squares': [1, 1]}},
        {'to': 1, 'give': 'all'},
        {'to': '1', 'give': {'money': 1}},
      ]) {
        refused(g, mv('tradeOffer', bad));
      }
      // Per street, for the trade screen.
      expect(g.tradeSquareProblem(0, 1), isNull);
      expect(g.tradeSquareProblem(1, 6), startsWith('sell the houses'));
      expect(g.tradeSquareProblem(1, 1), contains('not theirs'));
      expect(g.tradeSquareProblem(1, 40), contains('not theirs'));
    });
  });

  group('resign and round limit', () {
    test('resigning in and out of turn', () {
      final g = PropertyGame(playerCount: 3, dice: [1, 2]);
      g.debugSetSquare(39, 2);
      play(g, [mv('resign', {'seat': 2})]);
      expect(g.seats[2].out, isTrue);
      expect(g.ownerOf(39), isNull);
      refused(g, mv('resign', {'seat': 2}));
      refused(g, mv('resign', {'seat': 5}));
      play(g, ['roll', 'decline']);
      expect(g.auction!.bidders, [1, 0]);
      play(g, [mv('resign', {'seat': 0})]);
      expect(g.auction, isNull);
      expect(g.isOver, isTrue);
      expect(g.propertyResult.winner, 1);
      expect(total(g), 3 * 1500);
    });

    test('the current player resigns: the next one moves', () {
      final g = PropertyGame(playerCount: 3, dice: [1, 2]);
      play(g, ['roll', mv('resign', {'seat': 0})]);
      expect(g.currentSeat, 1);
      expect(g.phase, PropertyPhase.roll);
      play(g, [mv('resign', {'seat': 1})]);
      expect(g.propertyResult.winner, 2);
    });

    test('a bidder resigns during an auction', () {
      final g = PropertyGame(playerCount: 4, dice: [1, 2]);
      play(g, ['roll', 'decline', mv('bid', {'amount': 40}), mv('resign', {'seat': 1})]);
      expect(g.auction!.bidders, [2, 3, 0]);
      expect(g.auction!.high, 0);
      expect(g.actor, 2);
      play(g, ['pass', 'pass', 'pass']);
      expect(g.ownerOf(3), isNull);
    });

    test('the round limit: the richest wins, a tie is a draw', () {
      final g = PropertyGame(maxRounds: 1, dice: [1, 2, 1, 3]);
      play(g, ['roll', 'buy', 'endTurn', 'roll', 'endTurn']);
      expect(g.isOver, isTrue);
      expect(g.propertyResult.code, 'property.roundLimit');
      expect(g.propertyResult.winner, 0);
      expect(g.netWorth(0), 1500);
      expect(g.netWorth(1), 1300);
      final t = PropertyGame(maxRounds: 1, dice: [4, 6, 4, 6]);
      play(t, ['roll', 'endTurn', 'roll', 'endTurn']);
      expect(t.propertyResult.draw, isTrue);
      expect(t.propertyResult.leaders, [0, 1]);
    });
  });

  group('bots play whole games', () {
    void checkInvariants(PropertyGame g) {
      expect(total(g), g.playerCount * PropertyGame.startCash);
      for (var s = 0; s < g.playerCount; s++) {
        final seat = g.seats[s];
        expect(seat.cash, greaterThanOrEqualTo(0));
        if (seat.out) {
          expect(seat.cash, 0);
          expect(g.ownedBy(s), isEmpty);
        }
      }
      for (var i = 0; i < 40; i++) {
        if (g.housesOn(i) == 0) continue;
        final sq = board[i];
        expect(sq.kind, PropertyKind.street);
        final owner = g.ownerOf(i);
        expect(groups[sq.group].every((j) => g.ownerOf(j) == owner && !g.isMortgaged(j)), isTrue);
        final hs = groups[sq.group].map(g.housesOn);
        expect(hs.reduce(max) - hs.reduce(min), lessThanOrEqualTo(1));
      }
    }

    /// Moves that must be refused right now: every action the legal list
    /// does not offer, wrong seats and bad parameters.
    void checkRefusals(PropertyGame g) {
      final legal = g.legalMoves;
      final actions = legal.map((m) => m['action']).toSet();
      for (final a in ['roll', 'buy', 'decline', 'pass', 'payBail', 'useCard', 'endTurn', 'tradeAccept',
          'tradeDecline', 'bankrupt', 'nonsense']) {
        if (!actions.contains(a)) refused(g, mv(a));
      }
      for (final a in ['build', 'sell', 'mortgage', 'unmortgage']) {
        for (final i in [-1, 40, ...List.generate(40, (i) => i)]) {
          final m = mv(a, {'square': i});
          if (!legal.any((l) => l['action'] == a && l['square'] == i)) refused(g, m);
        }
      }
      final actor = g.actor!;
      refused(g, {...legal.first, 'seat': (actor + 1) % g.playerCount});
      if (g.phase == PropertyPhase.auction) {
        refused(g, mv('bid', {'amount': g.auction!.minBid - 1}));
        refused(g, mv('bid', {'amount': g.seats[actor].cash + 1}));
      }
    }

    test('greedy and random bots, 2–6 players: invariants hold, games end, replays match', () {
      var finishedEarly = 0, bankruptAuctions = 0, pots = 0;
      for (var players = 2; players <= 6; players++) {
        for (var seed = 0; seed < 16; seed++) {
          final greedy = seed.isEven;
          final free = PropertyFreeSquare.values[seed ~/ 2 % PropertyFreeSquare.values.length];
          final toggles = seed % 3 == 0;
          final g = PropertyGame(
              playerCount: players,
              seed: seed,
              maxRounds: 60,
              freeSquare: free,
              doubleStart: toggles,
              noRentInPause: toggles,
              bankruptAuction: toggles);
          final bot = PropertyBot(Random(seed * 31 + players), greedy: greedy);
          var moves = 0;
          while (!g.isOver) {
            if (moves % 37 == 0) checkRefusals(g);
            final m = bot.choose(g);
            final ev = g.applyMove(m);
            expect(ev, isNotNull, reason: '$m in ${g.toJson()}');
            for (final e in ev!.events) {
              if (e['type'] == 'auction' && e['bankrupt'] == true) bankruptAuctions++;
              if (e['type'] == 'pot' && (e['amount'] as int) > 0) pots++;
            }
            checkInvariants(g);
            expect(++moves, lessThan(100000));
          }
          if (g.propertyResult.code == 'property.lastSolvent') finishedEarly++;
          expect(g.rounds, lessThanOrEqualTo(60));
          final r = PropertyGame.replay(players, seed, g.history,
              maxRounds: 60,
              freeSquare: free,
              doubleStart: toggles,
              noRentInPause: toggles,
              bankruptAuction: toggles)!;
          expect(jsonEncode(r.toJson()), jsonEncode(g.toJson()));
        }
      }
      // Monopolies and houses do happen: some games end before the limit.
      expect(finishedEarly, greaterThan(0));
      // The toggles are really exercised.
      expect(bankruptAuctions, greaterThan(0));
      expect(pots, greaterThan(0));
    });

    test('greedy bots without a round limit usually play to the last one', () {
      var ended = 0;
      for (var seed = 0; seed < 10; seed++) {
        final g = PropertyGame(playerCount: 4, seed: seed);
        final bot = PropertyBot(Random(seed));
        for (var i = 0; i < 60000 && !g.isOver; i++) {
          g.applyMove(bot.choose(g));
        }
        if (g.isOver) ended++;
      }
      expect(ended, greaterThanOrEqualTo(7));
    });

    test('every listed legal move is accepted', () {
      final g = PropertyGame(playerCount: 4, seed: 9, maxRounds: 30);
      final bot = PropertyBot(Random(2));
      var step = 0;
      while (!g.isOver) {
        if (step++ % 11 == 0) {
          for (final m in g.legalMoves) {
            final copy = PropertyGame.replay(4, 9, g.history, maxRounds: 30)!;
            expect(copy.applyMove(m), isNotNull, reason: '$m');
          }
        }
        g.applyMove(bot.choose(g));
      }
    });
  });

  group('text adapter', () {
    test('parse and format round-trip', () {
      final t = PropertyText();
      for (final m in <Map<String, dynamic>>[
        mv('roll'), mv('buy'), mv('decline'), mv('bid', {'amount': 120}), mv('pass'),
        mv('build', {'square': 39}), mv('sell', {'square': 1}), mv('mortgage', {'square': 5}),
        mv('unmortgage', {'square': 5}), mv('payBail'), mv('useCard'), mv('endTurn'), mv('bankrupt'),
        mv('tradeAccept'), mv('tradeDecline'), mv('resign', {'seat': 2}),
        mv('tradeOffer', {
          'to': 1,
          'give': {'money': 100, 'squares': [1, 3]},
          'get': {'squares': [39]},
        }),
      ]) {
        expect(t.parse(t.format(m)), m);
      }
      expect(t.parse('fly'), isNull);
    });

    test('a narrated auto game', () {
      final t = PropertyText(players: 4, seed: 3);
      final out = t.handle('auto 300');
      expect(out, contains('Rolled'));
      expect(t.handle('help'), contains('offer'));
      expect(t.handle('fly'), startsWith('Unknown command'));
      expect(t.render(), contains('P4'));
    });
  });
}

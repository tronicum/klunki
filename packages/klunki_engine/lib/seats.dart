/// Games for more than two players (KLD-088): seats `0 … playerCount-1`
/// next to the two-player [Game] interface.
///
/// `Player {a, b}`, [GameResult.winner], the resign move and the network
/// session assume two players. Widening them would touch every game, the
/// protocol and the app at once, so an n-player game implements [SeatGame]
/// *in addition*: seat 0 is [Player.a], seat 1 [Player.b], seats 2+ exist
/// only here. A two-player game keeps working through [Game] alone; with
/// more seats the app and (later) the network use the seat API. See
/// `docs/tasks/KLD-088-more-players.md`.
library;

/// The seat-based view of a game with 2 or more players.
abstract interface class SeatGame {
  /// Number of seats, fixed for the whole game.
  int get playerCount;

  /// The seat expected to move now (the player to move, or the one who must
  /// answer something first); null once the game is over.
  int? get actorSeat;

  /// The seat that makes [move] (a resign or an answer names its seat).
  int seatOfMove(Map<String, dynamic> move);

  /// Whether [seat] has left the game (resigned); it is skipped in the turn
  /// order and ranks behind every seat still in.
  bool isSeatOut(int seat);

  /// The outcome per seat ([SeatResult.isOver] false while running).
  SeatResult get seatResult;
}

/// The outcome of a [SeatGame]: a place per seat (1 = best; ties share a
/// place, the next place is skipped: 1, 1, 3, 4).
class SeatResult {
  final bool isOver;

  /// Place per seat; empty while running.
  final List<int> places;

  /// Machine-readable reason (`<game>.<reason>`, as [GameEndReason.code]);
  /// null while running.
  final String? code;

  /// Numbers for [code] (e.g. `turns`).
  final Map<String, int> params;

  /// English reason for the CLI and logs.
  final String reason;

  const SeatResult({this.isOver = false, this.places = const [], this.code, this.params = const {}, this.reason = ''});

  /// The seats in first place (more than one: a shared win).
  List<int> get winners => [for (var s = 0; s < places.length; s++) if (places[s] == 1) s];

  /// The single winner, or null (running, or a shared first place).
  int? get winner {
    final w = winners;
    return w.length == 1 ? w.single : null;
  }

  /// The seats from first to last place (seat order within a tie).
  List<int> get ranking => [for (var s = 0; s < places.length; s++) s]..sort((x, y) {
      final d = places[x] - places[y];
      return d != 0 ? d : x - y;
    });

  /// Places for [scores] (higher is better); seats in [out] rank behind all
  /// others, the seat that left last best among them (`out` in the order the
  /// seats left).
  static List<int> placesFor(List<int> scores, {List<int> out = const []}) {
    final n = scores.length;
    final places = List.filled(n, 0);
    final inSeats = [for (var s = 0; s < n; s++) if (!out.contains(s)) s];
    for (final s in inSeats) {
      places[s] = 1 + inSeats.where((o) => scores[o] > scores[s]).length;
    }
    for (var i = 0; i < out.length; i++) {
      places[out[i]] = n - i;
    }
    return places;
  }

  Map<String, dynamic> toJson() => {
        'over': isOver,
        if (places.isNotEmpty) 'places': List.of(places),
        if (code != null) 'code': code,
        if (params.isNotEmpty) 'params': Map.of(params),
      };
}

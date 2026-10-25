import 'package:test/test.dart';
import 'package:klunki_engine/klunki_engine.dart';

void main() {
  test('quartett engine starts with alternating turns', () {
    final g = QuartettGame();
    expect(g.currentPlayer, Player.a);
    final e = g.applyMove({'action': 'start'});
    expect(e, isNotNull);
    expect(g.currentPlayer, Player.b);
    expect(g.history.length, greaterThan(1));
  });
}

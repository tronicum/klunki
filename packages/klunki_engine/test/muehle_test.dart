import 'package:test/test.dart';
import 'package:klunki_engine/klunki_engine.dart';

void main() {
  test('mühle engine starts with alternating turns', () {
    final g = MuehleGame();
    expect(g.currentPlayer, Player.a);
    final e = g.applyMove({'action': 'start'});
    expect(e, isNotNull);
    expect(g.currentPlayer, Player.b);
  });
}

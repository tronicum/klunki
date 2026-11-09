// KLD-119: the automatic defaults of Ausgewürfelt's learning aids. The
// Anfängermodus (the recommended box glows) is on for the first game on a
// device, the tips (the bubble) for the first 5; an explicit choice wins.
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/profile/beginner_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<BeginnerSettings> _fresh() async {
  BeginnerSettings.debugReset(loaded: true);
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return BeginnerSettings.shared();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Anfängermodus: on in game 1, off from game 2', () async {
    final s = BeginnerSettings.memory();
    expect(s.enabled, isTrue);
    await s.countGame();
    expect(s.gamesPlayed, 1);
    expect(s.enabled, isFalse);
  });

  test('tips: on in games 1 to 5, off from game 6', () async {
    final s = BeginnerSettings.memory();
    for (var game = 1; game <= 5; game++) {
      expect(s.tips, isTrue, reason: 'game $game');
      await s.countGame();
    }
    expect(s.tips, isFalse, reason: 'game 6');
    expect(BeginnerSettings.memory(games: 4).tips, isTrue);
    expect(BeginnerSettings.memory(games: 5).tips, isFalse);
  });

  test('a listener hears when a default flips with a game', () async {
    final s = BeginnerSettings.memory(games: 4);
    var calls = 0;
    s.addListener(() => calls++);
    await s.countGame(); // tips go off (the Anfängermodus was off already)
    expect(calls, 1);
    await s.countGame(); // nothing changes
    expect(calls, 1);
  });

  test('an explicit choice wins over the automatic default', () async {
    final s = BeginnerSettings.memory();
    await s.setEnabled(false);
    await s.setTips(false);
    expect((s.enabled, s.tips), (false, false), reason: 'off in game 1 though the default is on');
    final later = BeginnerSettings.memory(games: 10);
    await later.setEnabled(true);
    await later.setTips(true);
    for (var i = 0; i < 3; i++) {
      await later.countGame();
    }
    expect((later.enabled, later.tips), (true, true), reason: 'on after 13 games though the default is off');
  });

  test('stored: the count and the choices survive a restart; no choice stored without one', () async {
    var s = await _fresh();
    expect((s.enabled, s.tips, s.gamesPlayed), (true, true, 0));
    await s.countGame();
    await s.countGame();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(BeginnerSettings.prefsKeyGames), 2);
    expect(prefs.getBool(BeginnerSettings.prefsKey), isNull);
    expect(prefs.getBool(BeginnerSettings.prefsKeyTips), isNull);

    s = await _fresh();
    expect((s.enabled, s.tips, s.gamesPlayed), (false, true, 2));
    await s.setEnabled(true);
    for (var i = 0; i < 3; i++) {
      await s.countGame();
    }
    s = await _fresh();
    expect((s.enabled, s.tips, s.gamesPlayed), (true, false, 5), reason: 'the chosen Anfängermodus stays on');
  });

  test('a game counted and a choice made before storage loaded are kept', () async {
    SharedPreferences.setMockInitialValues({BeginnerSettings.prefsKeyGames: 3, BeginnerSettings.prefsKeyTips: true});
    BeginnerSettings.debugReset(loaded: true);
    final s = BeginnerSettings.shared();
    await s.setTips(false);
    await s.countGame();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect((s.tips, s.gamesPlayed), (false, 4));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(BeginnerSettings.prefsKeyGames), 4);
    expect(prefs.getBool(BeginnerSettings.prefsKeyTips), isFalse);
  });
}

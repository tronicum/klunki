// KLD-056: persistence and cleaning of the player name and the hot-seat names.
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerNameController', () {
    test('no saved name: not chosen yet, the suggestion is the default', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await PlayerNameController.load(suggestion: () => '  Stefans   iPhone ');
      expect(c.value, isNull);
      expect(c.hasName, isFalse);
      expect(c.suggested, 'Stefans iPhone');
      expect(c.name, 'Stefans iPhone');
    });

    test('an empty suggestion falls back to "Klunki"', () {
      final c = PlayerNameController.memory(suggestion: () => '\u202E ');
      expect(c.name, 'Klunki');
    });

    test('persistence round trip under "playerName"', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await PlayerNameController.load(suggestion: () => 'x');
      expect(await c.setName('  Anna  '), isTrue);
      expect(c.value, 'Anna');
      expect((await SharedPreferences.getInstance()).getString(PlayerNameController.prefsKey), 'Anna');
      expect(PlayerNameController.prefsKey, 'playerName');
      final again = await PlayerNameController.load(suggestion: () => 'x');
      expect(again.value, 'Anna');
      expect(again.hasName, isTrue);
    });

    test('cleans control and bidi characters, collapses whitespace, cuts at 20', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await PlayerNameController.load();
      await c.setName('\u202EAn\u0000na\n\t Lena\u2066');
      expect(c.value, 'Anna Lena');
      await c.setName('b' * 40);
      expect(c.value, 'b' * 20);
      await c.setName('علی');
      expect(c.value, 'علی');
    });

    test('empty input is refused and changes nothing', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await PlayerNameController.load();
      await c.setName('Anna');
      for (final raw in ['', '   ', '\u0000\u0007', '\u202E\u2069\u200F']) {
        expect(await c.setName(raw), isFalse, reason: raw);
      }
      expect(c.value, 'Anna');
      expect((await SharedPreferences.getInstance()).getString(PlayerNameController.prefsKey), 'Anna');
    });

    test('a stored value is cleaned on load; garbage counts as no name', () async {
      SharedPreferences.setMockInitialValues({PlayerNameController.prefsKey: ' Ben\u202E '});
      expect((await PlayerNameController.load()).value, 'Ben');
      SharedPreferences.setMockInitialValues({PlayerNameController.prefsKey: '\u0000 '});
      expect((await PlayerNameController.load()).hasName, isFalse);
    });
  });

  group('HotSeatNamesController', () {
    test('no saved pair: no names', () async {
      SharedPreferences.setMockInitialValues({});
      expect((await HotSeatNamesController.load()).value, HotSeatNames.none);
    });

    test('the last pair is persisted, cleaned, and empty names are cleared', () async {
      SharedPreferences.setMockInitialValues({});
      final c = await HotSeatNamesController.load();
      await c.setNames(' Anna ', 'Ben\u202E');
      expect(c.value, const HotSeatNames(x: 'Anna', o: 'Ben'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(HotSeatNamesController.prefsKeyX), 'Anna');
      expect(prefs.getString(HotSeatNamesController.prefsKeyO), 'Ben');
      expect((await HotSeatNamesController.load()).value, const HotSeatNames(x: 'Anna', o: 'Ben'));

      await c.setNames('Anna', '  ');
      expect(c.value, const HotSeatNames(x: 'Anna'));
      expect(prefs.containsKey(HotSeatNamesController.prefsKeyO), isFalse);
      expect((await HotSeatNamesController.load()).value, const HotSeatNames(x: 'Anna'));
    });
  });
}

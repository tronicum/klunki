import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no saved value means system (null)', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await LocaleController.load();
    expect(c.value, isNull);
  });

  test('persistence round trip, incl. script code and back to system', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await LocaleController.load();

    await c.setLocale(const Locale('fr'));
    expect((await SharedPreferences.getInstance()).getString(LocaleController.prefsKey), 'fr');
    expect((await LocaleController.load()).value, const Locale('fr'));

    const zh = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    await c.setLocale(zh);
    expect((await SharedPreferences.getInstance()).getString(LocaleController.prefsKey), 'zh-Hans');
    expect((await LocaleController.load()).value, zh);

    await c.setLocale(null);
    expect((await SharedPreferences.getInstance()).containsKey(LocaleController.prefsKey), isFalse);
    expect((await LocaleController.load()).value, isNull);
  });

  test('loads a seeded value', () async {
    SharedPreferences.setMockInitialValues({LocaleController.prefsKey: 'ar'});
    expect((await LocaleController.load()).value, const Locale('ar'));
  });

  test('?lang= in the page URL overrides the saved choice without persisting', () async {
    SharedPreferences.setMockInitialValues({LocaleController.prefsKey: 'de'});
    final c = await LocaleController.load(pageUrl: Uri.parse('http://localhost:8080/?lang=zh-Hans'));
    expect(c.value, const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
    expect((await SharedPreferences.getInstance()).getString(LocaleController.prefsKey), 'de');
  });

  test('without ?lang= (or empty) the saved choice is used', () async {
    SharedPreferences.setMockInitialValues({LocaleController.prefsKey: 'fa'});
    expect((await LocaleController.load(pageUrl: Uri.parse('http://localhost:8080/'))).value,
        const Locale('fa'));
    expect((await LocaleController.load(pageUrl: Uri.parse('http://localhost:8080/?lang='))).value,
        const Locale('fa'));
    // Not on the web (VM tests): Uri.base is not consulted.
    expect((await LocaleController.load()).value, const Locale('fa'));
  });

  test('parseTag', () {
    expect(LocaleController.parseTag(null), isNull);
    expect(LocaleController.parseTag(''), isNull);
    expect(LocaleController.parseTag('pt_BR'), const Locale('pt', 'BR'));
  });
}

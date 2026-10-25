import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LocaleController> pumpApp(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final controller = await LocaleController.load();
    await tester.pumpWidget(KlunkiApp(localeController: controller));
    await tester.pumpAndSettle();
    return controller;
  }

  String appTitle(WidgetTester tester) => tester.widget<Title>(find.byType(Title)).title;

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('language-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('picker lists System + endonyms with the current choice checked', (tester) async {
    await pumpApp(tester, prefs: {LocaleController.prefsKey: 'de'});
    await openPicker(tester);

    expect(find.text('Sprache wählen'), findsOneWidget);
    for (final name in ['System', 'Deutsch', 'English', 'Français', 'Español', '简体中文', 'العربية', 'فارسی']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(
      find.descendant(of: find.byKey(const Key('language-de')), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('picking a language switches and persists the locale', (tester) async {
    final controller = await pumpApp(tester, prefs: {LocaleController.prefsKey: 'de'});
    expect(appTitle(tester), 'Klunki');
    expect(find.byTooltip('Sprache'), findsOneWidget);

    await openPicker(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(controller.value, const Locale('en'));
    expect((await SharedPreferences.getInstance()).getString(LocaleController.prefsKey), 'en');
    expect(Localizations.localeOf(tester.element(find.byType(Scaffold).first)), const Locale('en'));
    // The app title is a brand and stays the same; the localized texts change.
    expect(appTitle(tester), 'Klunki');
    expect(find.byTooltip('Language'), findsOneWidget);
    expect(find.byTooltip('Sprache'), findsNothing);

    await openPicker(tester);
    expect(find.text('Choose language'), findsOneWidget);
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('语言'), findsOneWidget);
  });

  testWidgets('Arabic yields right-to-left text direction', (tester) async {
    await pumpApp(tester);
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(ctx), TextDirection.ltr);

    await openPicker(tester);
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(Directionality.of(tester.element(find.byType(Scaffold).first)), TextDirection.rtl);
    expect(find.byTooltip('اللغة'), findsOneWidget);
  });

  testWidgets('Persian yields right-to-left text direction', (tester) async {
    await pumpApp(tester, prefs: {LocaleController.prefsKey: 'fa'});
    expect(Directionality.of(tester.element(find.byType(Scaffold).first)), TextDirection.rtl);
  });
}

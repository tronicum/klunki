import 'package:flutter/material.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/l10n/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final localeController = await LocaleController.load();
  runApp(KlunkiApp(localeController: localeController));
}

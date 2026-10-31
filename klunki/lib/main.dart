import 'package:flutter/material.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/app/third_party_licenses.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/player_name_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  registerNativeLicenses();
  final localeController = await LocaleController.load();
  final playerNameController = await PlayerNameController.load();
  final hotSeatNames = await HotSeatNamesController.load();
  runApp(
    KlunkiApp(
      localeController: localeController,
      playerNameController: playerNameController,
      hotSeatNames: hotSeatNames,
    ),
  );
}

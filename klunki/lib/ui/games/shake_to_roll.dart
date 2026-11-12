import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

import '../../platform/shake.dart';
import '../../profile/seen_tips.dart';
import '../../profile/shake_settings.dart';
import '../shell/game_screen.dart' show ShellMenuEntry;

/// "Schütteln zum Würfeln" for a dice game (KLD-121 follow-up; Mäxchen now,
/// the five-dice game next): calls [onShake] when the phone is shaken like a
/// dice cup, besides the game's own roll button.
///
/// The sensor runs only while [enabled] (the game allows a roll now: the
/// player's turn, no handover cover), the setting is on, the app is in the
/// foreground and the game's route is on top (no dialog over it). One
/// shaking calls [onShake] once; it can fire again only after [enabled] was
/// false in between (the roll was made).
///
/// [builder] gets `shakeReady`: shaking works right now, so the screen can
/// say "…oder schüttle das Handy".
/// "Schütteln zum Würfeln" as a switch in the game's "⋮" menu (key
/// `shake-menu`): a network game has no start dialog on the guest, so both
/// devices switch the device setting ([ShakeSettings], the same stored
/// value as the start dialogs' switch) here (KLD-121 network decisions
/// 2026-11-12). Null on a device without a motion sensor. The screen
/// rebuilds its menu when [ShakeSettings.shared] changes.
ShellMenuEntry? shakeMenuEntry(AppLocalizations l10n) {
  if (!Motion.maybeAvailable) return null;
  final settings = ShakeSettings.shared();
  return ShellMenuEntry(
    key: const Key('shake-menu'),
    icon: Icons.vibration,
    label: l10n.shakeToRollSetting,
    checked: settings.enabled,
    onSelected: () {
      final on = !settings.enabled;
      if (on) Motion.askPermission();
      settings.setEnabled(on);
    },
  );
}

class ShakeToRoll extends StatefulWidget {
  final bool enabled;
  final VoidCallback onShake;
  final Widget Function(BuildContext context, bool shakeReady) builder;

  const ShakeToRoll({super.key, required this.enabled, required this.onShake, required this.builder});

  /// Call from the roll button's tap (synchronously): the web on iOS asks for
  /// motion access only inside a user tap. Nothing when the setting is off.
  static void askPermissionFromTap() {
    if (ShakeSettings.shared().enabled) Motion.askPermission();
  }

  /// The roll button's tap (KLD-123): rolls with [roll], and first, once,
  /// where the browser will ask for motion access (the web on iOS, shaking
  /// on), the consent card ([ShakeConsentCard]) that explains the prompt.
  /// "Ja" asks the browser inside its own tap, "Nein" turns shaking off;
  /// either way the dice are rolled afterwards. Elsewhere this is
  /// [askPermissionFromTap] plus [roll].
  static void rollFromTap(BuildContext context, VoidCallback roll) {
    if (ShakeSettings.shared().enabled && Motion.permissionPending && !SeenTips.shared.has(SeenTips.shakeConsent)) {
      showShakeConsent(context).then((_) => roll());
      return;
    }
    askPermissionFromTap();
    roll();
  }

  @override
  State<ShakeToRoll> createState() => _ShakeToRollState();
}

class _ShakeToRollState extends State<ShakeToRoll> with WidgetsBindingObserver {
  final ShakeDetector _detector = ShakeDetector();
  final ShakeSettings _settings = ShakeSettings.shared();
  StreamSubscription<AccelSample>? _sub;
  bool _fired = false;
  bool _routeCurrent = true;
  AppLifecycleState? _lifecycle = WidgetsBinding.instance.lifecycleState;

  bool get _foreground => _lifecycle == null || _lifecycle == AppLifecycleState.resumed;

  bool get _shouldListen =>
      widget.enabled && !_fired && _settings.enabled && _foreground && _routeCurrent && !Motion.unavailable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_syncAndRebuild);
    Motion.working.addListener(_rebuild);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    _sync();
  }

  @override
  void didUpdateWidget(ShakeToRoll old) {
    super.didUpdateWidget(old);
    if (!widget.enabled) _fired = false;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _syncAndRebuild();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_syncAndRebuild);
    Motion.working.removeListener(_rebuild);
    _stop();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// Starts or stops the sensor (called while building: no setState).
  void _sync() {
    if (_shouldListen) {
      _start();
    } else {
      _stop();
    }
  }

  void _syncAndRebuild() {
    if (!mounted) return;
    _sync();
    setState(() {});
  }

  void _start() {
    if (_sub != null) return;
    _detector.reset();
    _sub = Motion.samples().listen(
      _onSample,
      onError: (Object _) {
        Motion.unavailable = true;
        _stop();
        _rebuild();
      },
      onDone: () => _sub = null,
      cancelOnError: true,
    );
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
  }

  void _onSample(AccelSample s) {
    if (!Motion.working.value) Motion.working.value = true;
    if (!_detector.add(s) || !_shouldListen) return;
    _fired = true;
    _stop();
    widget.onShake();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _sub != null && Motion.working.value;
    return widget.builder(context, ready);
  }
}

/// Shows the shake consent card ([ShakeConsentCard]); completes when it is
/// answered.
Future<void> showShakeConsent(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ShakeConsentCard(),
    );

/// "Würfeln durch Schütteln?" (KLD-123): the web on iOS shows a fixed
/// motion permission prompt of its own; this card says first what it is
/// for. "Ja, Schütteln erlauben" asks the browser synchronously in this tap
/// (Safari allows the prompt only from a user tap), "Nein, nur tippen"
/// turns "Schütteln zum Würfeln" off. Answered once per device
/// ([SeenTips.shakeConsent]). Never in the apps (no prompt there).
///
/// Keys: `shake-consent`, `shake-consent-yes`, `shake-consent-no`.
class ShakeConsentCard extends StatelessWidget {
  const ShakeConsentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    return AlertDialog(
      key: const Key('shake-consent'),
      icon: const Icon(Icons.vibration),
      title: Text(l10n.shakeConsentTitle),
      content: Text(l10n.shakeConsentBody),
      actions: [
        TextButton(
          key: const Key('shake-consent-no'),
          onPressed: () {
            SeenTips.shared.markFirst(SeenTips.shakeConsent);
            ShakeSettings.shared().setEnabled(false);
            nav.pop();
          },
          child: Text(l10n.shakeConsentNo),
        ),
        FilledButton(
          key: const Key('shake-consent-yes'),
          onPressed: () {
            SeenTips.shared.markFirst(SeenTips.shakeConsent);
            // In this tap: the browser shows its prompt only from one.
            Motion.askPermission();
            nav.pop();
          },
          child: Text(l10n.shakeConsentYes),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../platform/shake.dart';
import '../../profile/shake_settings.dart';

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

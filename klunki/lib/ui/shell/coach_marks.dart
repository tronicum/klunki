import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

import '../../app/theme.dart';

/// One step of a [CoachMarks] tour: a short [text], pointing at the widget
/// behind [target] (a ring around it, the rest dimmed), or centred when
/// [target] is null or not on screen.
@immutable
class CoachStep {
  final GlobalKey? target;
  final String text;
  final IconData? icon;
  const CoachStep({required this.text, this.target, this.icon});
}

/// Shows a short "how to play" tour over the current screen (KLD-118):
/// one step after the other, "Weiter" / "Los geht's", "Überspringen" on
/// every step but the last. Completes when it is closed (done, skipped or
/// the back button). Reusable for any game: give each step a [GlobalKey]
/// of a real element of the board.
///
/// Callers decide when it may appear (once per device with `SeenTips`, never
/// over a handover cover, never showing a hand to the wrong player).
///
/// [accent] colours the buttons and the ring (a game's colour); without it
/// the app's primary colour.
///
/// Keys (with [keyPrefix] `coach`): `coach`, `coach-step-<1..n>`,
/// `coach-next`, `coach-done`, `coach-skip`.
Future<void> showCoachMarks(
  BuildContext context, {
  required List<CoachStep> steps,
  String keyPrefix = 'coach',
  GameAccent? accent,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, _, _) => CoachMarks(steps: steps, keyPrefix: keyPrefix, accent: accent),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}

class CoachMarks extends StatefulWidget {
  final List<CoachStep> steps;
  final String keyPrefix;
  final GameAccent? accent;

  /// The step to start with (0-based; screenshots).
  final int initialStep;

  const CoachMarks({super.key, required this.steps, this.keyPrefix = 'coach', this.accent, this.initialStep = 0});

  @override
  State<CoachMarks> createState() => _CoachMarksState();
}

class _CoachMarksState extends State<CoachMarks> {
  late int _step = widget.initialStep;

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  /// Scrolls the step's target into view, then measures it again.
  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = widget.steps[_step].target?.currentContext;
      if (ctx == null || !ctx.mounted) return;
      await Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 200));
      if (mounted) setState(() {});
    });
  }

  void _next() {
    if (_step + 1 >= widget.steps.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step++);
    _reveal();
  }

  /// The target's rectangle in this overlay's coordinates, or null.
  Rect? _targetRect(RenderBox? overlay) {
    final ro = widget.steps[_step].target?.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize || overlay == null || !overlay.hasSize) return null;
    final topLeft = overlay.globalToLocal(ro.localToGlobal(Offset.zero));
    final r = topLeft & ro.size;
    final screen = Offset.zero & overlay.size;
    if (!r.overlaps(screen)) return null;
    return r.intersect(screen).inflate(8);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final step = widget.steps[_step];
    final last = _step + 1 == widget.steps.length;
    final p = widget.keyPrefix;
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    final hole = _targetRect(overlay is RenderBox ? overlay : null);
    final scheme = theme.colorScheme;
    final a = widget.accent;
    final color = a?.color ?? scheme.primary;
    final onColor = a?.onColor ?? scheme.onPrimary;
    final mark = a?.onSurface(theme.brightness) ?? scheme.primary;
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final pad = MediaQuery.paddingOf(context);
        final bubble = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            key: Key('$p-step-${_step + 1}'),
            color: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: mark, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (step.icon != null) ...[Icon(step.icon, color: mark, size: 28), const SizedBox(width: 12)],
                        Expanded(child: Text(step.text, style: theme.textTheme.titleMedium)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < widget.steps.length; i++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsetsDirectional.only(end: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _step ? mark : scheme.outlineVariant,
                          ),
                        ),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            if (!last)
                              TextButton(
                                key: Key('$p-skip'),
                                style: TextButton.styleFrom(foregroundColor: mark),
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(l10n.coachSkip),
                              ),
                            FilledButton(
                              key: Key(last ? '$p-done' : '$p-next'),
                              style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: onColor),
                              onPressed: _next,
                              child: Text(last ? l10n.coachDone : l10n.coachNext),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        // The bubble goes on the side of the target with more room; with
        // no target, in the middle.
        Widget placed;
        if (hole == null) {
          placed = Center(child: bubble);
        } else {
          final below = size.height - hole.bottom;
          final above = hole.top;
          placed = below >= above
              ? Positioned(
                  left: 16,
                  right: 16,
                  top: math.min(hole.bottom + 12, size.height - pad.bottom - 160),
                  child: Center(child: bubble),
                )
              : Positioned(
                  left: 16,
                  right: 16,
                  bottom: math.min(size.height - hole.top + 12, size.height - pad.top - 160),
                  child: Center(child: bubble),
                );
        }
        return Stack(
          key: Key(p),
          children: [
            // Dims the screen, cuts out the target; swallows taps.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: CustomPaint(painter: _ScrimPainter(hole, mark)),
              ),
            ),
            if (hole == null)
              Positioned.fill(
                child: Padding(padding: const EdgeInsets.all(16), child: placed),
              )
            else
              placed,
          ],
        );
      },
    );
  }
}

class _ScrimPainter extends CustomPainter {
  final Rect? hole;
  final Color ring;
  _ScrimPainter(this.hole, this.ring);

  @override
  void paint(Canvas canvas, Size size) {
    final all = Path()..addRect(Offset.zero & size);
    final h = hole;
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.62);
    if (h == null) {
      canvas.drawPath(all, scrim);
      return;
    }
    final rr = RRect.fromRectAndRadius(h, const Radius.circular(16));
    canvas.drawPath(Path.combine(PathOperation.difference, all, Path()..addRRect(rr)), scrim);
    canvas.drawRRect(
      rr,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole || old.ring != ring;
}

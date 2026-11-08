import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Pinch zoom for a square game board, shared by Wortgewandt (KLD-094 step 8)
/// and GoStrategy (KLD-058).
///
/// The board sits in an [InteractiveViewer] (`minScale` 1, `maxScale` 4)
/// with this controller: two fingers zoom and move it, one finger that does
/// not start on a draggable piece moves a zoomed board, the mouse wheel and
/// a trackpad pinch zoom in a browser, taps on squares work at any zoom.
/// [zoomTo] and [zoomOut] animate (instant with reduced motion) for a zoom
/// button or an automatic zoom.
class BoardZoom extends TransformationController {
  BoardZoom({required TickerProvider vsync}) {
    _anim = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 260))..addListener(_tick);
  }

  late final AnimationController _anim;
  Matrix4Tween? _tween;

  /// The board's side (unzoomed, logical pixels) as last laid out
  /// ([layout]); [save] and [restore] keep a view across a size change.
  double _side = 0;

  /// The board's side as last laid out (0 before the first layout).
  double get side => _side;

  /// The board is zoomed in.
  bool get zoomed => value.getMaxScaleOnAxis() > 1.01;

  double get scale => value.getMaxScaleOnAxis();

  void _tick() {
    final t = _tween;
    if (t != null) value = t.evaluate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  /// Moves to [target], animated unless [instant]; [done] runs at the end.
  void animateTo(Matrix4 target, {required bool instant, VoidCallback? done}) {
    if (instant) {
      _anim.stop();
      value = target;
      done?.call();
      return;
    }
    _tween = Matrix4Tween(begin: value.clone(), end: target);
    _anim.forward(from: 0).whenComplete(() => done?.call());
  }

  /// The view at [scale] with board point [focus] (unzoomed board pixels)
  /// as near the centre of a [side] × [side] board as its edges allow.
  static Matrix4 focusOn(Offset focus, double scale, double side) {
    final dx = (side / 2 - focus.dx * scale).clamp(side - side * scale, 0.0);
    final dy = (side / 2 - focus.dy * scale).clamp(side - side * scale, 0.0);
    return Matrix4.translationValues(dx, dy, 0)..multiply(Matrix4.diagonal3Values(scale, scale, 1));
  }

  /// Zooms to [scale] around [focus] on a board of [side] ([focusOn]).
  void zoomTo(Offset focus, double scale, double side, {required bool instant, VoidCallback? done}) {
    if (side <= 0) return;
    animateTo(focusOn(focus, scale, side), instant: instant, done: done);
  }

  /// Back to the whole board (if zoomed).
  void zoomOut({required bool instant, VoidCallback? done}) {
    if (zoomed) animateTo(Matrix4.identity(), instant: instant, done: done);
  }

  /// The whole board at once, no animation.
  void reset() {
    _anim.stop();
    value = Matrix4.identity();
  }

  /// Tells the controller the board's side. When it changes (a turned
  /// phone, a resized window) a zoomed view keeps the same part of the
  /// board, adjusted after this frame.
  void layout(double side) {
    final old = _side;
    _side = side;
    if (old <= 0 || old == side || !zoomed) return;
    final kept = save(side: old);
    WidgetsBinding.instance.addPostFrameCallback((_) => restore(kept));
  }

  /// The current view with the translation in board sides (independent of
  /// the board's size), for [restore].
  Matrix4 save({double? side}) {
    final s = side ?? _side;
    final m = value.clone();
    if (s > 0) {
      final t = m.getTranslation();
      m.setTranslationRaw(t.x / s, t.y / s, 0);
    }
    return m;
  }

  /// Shows a view kept by [save] on the board as it is now laid out.
  void restore(Matrix4 saved) {
    _anim.stop();
    final m = saved.clone();
    if (_side > 0) {
      final t = m.getTranslation();
      final s = m.getMaxScaleOnAxis();
      // Clamped to the board (it may have changed its size meanwhile).
      final lo = _side - _side * s;
      m.setTranslationRaw((t.x * _side).clamp(min(lo, 0.0), 0.0), (t.y * _side).clamp(min(lo, 0.0), 0.0), 0);
    }
    value = m;
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }
}

/// A piece on a zoomable board that a finger or the mouse drags at once
/// ([BoardPieceDragRecognizer]); [onBoard] tells whether a global position
/// is on the board (only fingers there can pinch it).
class BoardPieceDraggable<T extends Object> extends Draggable<T> {
  const BoardPieceDraggable({
    super.key,
    required this.onBoard,
    required super.child,
    required super.feedback,
    super.data,
    super.childWhenDragging,
    super.dragAnchorStrategy,
    super.maxSimultaneousDrags,
  });

  /// Whether a global position is on the board ([BoardPieceDragRecognizer]).
  final bool Function(Offset global) onBoard;

  @override
  MultiDragGestureRecognizer createRecognizer(GestureMultiDragStartCallback onStart) =>
      BoardPieceDragRecognizer(onBoard)..onStart = onStart;
}

/// Drags a piece at once (KLD-094 step 8h): it wins over the board's pan
/// because it decides after the touch slop (18 px), the pan only after twice
/// that. But a pinch must still zoom when one finger starts on the piece: a
/// piece that has not lifted yet lets go as soon as another finger touches
/// down, and a finger that comes down while another one is down anywhere is
/// left to the board.
///
/// Only fingers and pens that come down on the board count (browser
/// playtest of step 8h: "if i touch another letter the first one can only be
/// removed by click not by drag"): a finger resting on the rack, the bench or
/// the screen's edge cannot pinch the board, and counted it left every drag
/// to the board while taps still worked. A mouse does not count either: it
/// cannot pinch, and a browser may never pass on its release (a right click
/// that opens the browser's menu), which blocked finger drags the same way.
class BoardPieceDragRecognizer extends MultiDragGestureRecognizer {
  BoardPieceDragRecognizer(this._onBoard) : super(debugOwner: null) {
    GestureBinding.instance.pointerRouter.addGlobalRoute(_watch);
  }

  final bool Function(Offset global) _onBoard;

  /// The fingers and pens down on the board (from the time this recognizer
  /// was made).
  final Set<int> _down = {};
  final Map<int, _PieceDragState> _pending = {};

  static bool _finger(PointerEvent event) => event.kind != PointerDeviceKind.mouse;

  void _watch(PointerEvent event) {
    if (event is PointerDownEvent) {
      if (!_finger(event) || !_onBoard(event.position)) return;
      _down.add(event.pointer);
      for (final state in [..._pending.values]) {
        if (state.finger && state.pointer != event.pointer) state.letGo();
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _down.remove(event.pointer);
    }
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    // [_watch] sees this pointer's down only after the hit test targets.
    if (_finger(event) && _down.any((p) => p != event.pointer)) return;
    super.addAllowedPointer(event);
  }

  @override
  MultiDragPointerState createNewPointerState(PointerDownEvent event) =>
      _pending[event.pointer] = _PieceDragState(this, event);

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_watch);
    super.dispose();
  }

  @override
  String get debugDescription => 'board piece drag';
}

class _PieceDragState extends MultiDragPointerState {
  _PieceDragState(this._owner, PointerDownEvent event)
    : pointer = event.pointer,
      finger = BoardPieceDragRecognizer._finger(event),
      super(event.position, event.kind, _owner.gestureSettings);

  final BoardPieceDragRecognizer _owner;
  final int pointer;
  final bool finger;
  bool _decided = false;

  /// Another finger touched down before the piece lifted: leave it to the
  /// board (a pinch).
  void letGo() {
    _decide();
    resolve(GestureDisposition.rejected);
  }

  void _decide() {
    _decided = true;
    if (identical(_owner._pending[pointer], this)) _owner._pending.remove(pointer);
  }

  @override
  void checkForResolutionAfterMove() {
    if (_decided) return;
    if (pendingDelta!.distance > computeHitSlop(kind, gestureSettings)) {
      _decide();
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void accepted(GestureMultiDragStartCallback starter) {
    _decide();
    starter(initialPosition);
  }

  @override
  void rejected() {
    _decide();
    super.rejected();
  }

  @override
  void dispose() {
    _decide();
    super.dispose();
  }
}

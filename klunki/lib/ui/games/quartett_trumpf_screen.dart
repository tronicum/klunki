import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_engine/klunki_engine.dart' as qe show Card;

import '../../game/game_controller.dart';
import '../../transport/game_transport.dart';
import '../../app/theme.dart';
import '../shell/game_screen.dart';
import 'quartett_card.dart';
import 'quartett_deck_picker.dart' show quartettScreenTitle;

/// Quartett (Trumpf) / Auto-Quartett screen.
///
/// Contract (keep it): the public class name `QuartettTrumpfScreen` and the
/// constructor `const QuartettTrumpfScreen({super.key, required this.controller})`.
/// The screen is built by `ui/shell/screen_registry.dart` and renders a
/// [GameScreen].
///
/// Wording (KLD-092): one comparison is a round ("Runde", not "Stich"); a tie
/// is a tie-break ("Gleichstand – Stechen!"), the next card decides. Internal
/// names keep "trick".
///
/// Flow of one trick (hot-seat):
/// 1. The player to move sees only their own top card (stats tappable) and
///    the opponent's face-down stack.
/// 2. Tapping a stat shows the trick reveal (both cards, chosen stat
///    highlighted, winner text). While it is shown the shell's status line
///    names the next picker ("Ben wählt als Nächstes", KLD-092) instead of the
///    live "Anna ist am Zug". The move is *not* submitted yet: the reveal
///    is computed on a replayed copy of the engine, so the shell's handover
///    cover (which appears as soon as a move passes the turn) cannot hide it.
/// 3. "Weiter – Anna wählt" submits the pick. If the turn passed (the other
///    player won the trick), the shell's [HandoverCover] appears and says
///    why ("Ben hat die Runde gewonnen", `qt-handover-reason`); otherwise (the
///    picker won, or a tie) there is no cover: nothing has to be passed and
///    the reveal already said "Anna wählt noch einmal" (KLD-091, reverses the
///    old KLD-029 plan).
///
/// Every trick result names who picks next (`qt-next-picker`, KLD-091):
/// "Ben wählt als Nächstes" when the other player won, "Anna wählt noch einmal"
/// when the picker won, and after a tie "Karten in den Topf (jetzt 2), Anna wählt
/// noch einmal" under the headline "Gleichstand – Stechen!".
///
/// Network (KLD-086): "Weiter" is local only, never a message, and the game
/// never waits for it. A pick is submitted at once (no preview) and every
/// accepted pick is revealed from its event payload. The next picker (trick
/// winner, or the same player after a tie) keeps the reveal until "Weiter".
/// The waiting player sees it for at least [quartettRevealGrace] (a tap skips
/// it); a trick the opponent picks meanwhile is queued and shown next, in
/// order. After the grace the table shows the own new top card and
/// "Anna wählt …".
///
/// The waiting player's grace shows a countdown (`qt-grace`); a trick picked
/// meanwhile is announced ("Anna hat gewählt: PS", `qt-queued-notice`).
///
/// "Vorige Runde" (`qt-last-trick`, next to the stack counts, in every mode)
/// opens a local overlay (`qt-last-trick-overlay`) with the most recent trick
/// the player has seen. While it is open nothing new is revealed and the
/// grace pauses; tricks arriving meanwhile are queued and shown after it
/// closes. The board keeps the last [quartettTrickHistoryLength] tricks.
///
/// Network status line (KLD-091): while the reveal on screen is not the
/// newest trick (more are queued behind it), the shell's status line follows
/// the reveal ("Ben (O) wählt als Nächstes" / "Du wählst als Nächstes (O)")
/// with a badge "noch 2 Runden" (`shell-status-badge`) instead of the live
/// "Du bist am Zug"; it goes back to the live status once the queue is
/// empty, see [GameShell.setStatusOverride].
///
/// Game end (KLD-089): the shell's result dialog waits until the device has
/// shown every trick (the final reveal is left with "Weiter" or, for the
/// waiting player, when its grace runs out), see [GameShell.holdResult].
///
/// Keys: `qt-stat-<statId>` (stat rows of the active card), `qt-reveal`,
/// `qt-reveal-picked`, `qt-reveal-text`, `qt-next-picker`, `qt-continue`,
/// `qt-handover-reason`, `qt-grace`, `qt-grace-seconds`, `qt-queued-notice`,
/// `qt-last-trick`, `qt-last-trick-overlay`, `qt-last-trick-close`.
class QuartettTrumpfScreen extends StatelessWidget {
  final GameController controller;

  const QuartettTrumpfScreen({super.key, required this.controller});

  /// History text for a pick: "wählt Leistung" (the shell prefixes the
  /// player). No card names, so the history never leaks a card.
  static String describeMove(AppLocalizations l10n, AcceptedMove m) {
    return l10n.quartettTrumpfMovePick(localizedStatLabel(l10n, '${m.move['stat']}'));
  }

  /// Hot-seat cover (KLD-091): why the device goes to the player on turn,
  /// "O hat die Runde gewonnen" (the cover only appears when the turn
  /// passed, i.e. the other player won the trick). Nothing for any other
  /// cover (e.g. after an undo).
  Widget _handoverReason(BuildContext context) {
    final moves = controller.moves;
    final game = controller.game;
    if (moves.isEmpty || game is! QuartettGame) return const SizedBox.shrink();
    final payload = moves.last.event.payload;
    final winner = payload is Map ? payload['trickWinner'] : null;
    final next = game.currentPlayer;
    if (winner != next.name) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.quartettTrumpfHandoverReason(PlayerLabelsScope.of(context).label(context, l10n, next)),
      key: const Key('qt-handover-reason'),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      describeMove: describeMove,
      title: quartettScreenTitle(context, controller),
      handoverDetail: _handoverReason,
      boardBuilder: (context, controller) => _QuartettTrumpfBoard(controller: controller),
    );
  }
}

/// Network (KLD-086): how long the waiting player (the one who does not pick
/// next) sees a trick result at least before it gives way on its own to the
/// next queued trick or to the table. A countdown shows it; a tap on
/// "Weiter" skips it.
const quartettRevealGrace = Duration(seconds: 5);

/// How many tricks the board keeps for "Vorige Runde" (newest last). Only
/// the last one is shown for now; a longer list would allow a history view.
const quartettTrickHistoryLength = 1;

/// One trick as shown in the reveal.
class _Trick {
  final Player picker;
  final QuartettStat stat;
  final qe.Card a, b;
  final num va, vb;
  final Player? winner;

  /// Pot size after the trick.
  final int pot;

  /// Stack sizes right after the trick (null: not known, e.g. several
  /// tricks arrived at once).
  final int? countA, countB;

  /// The pick still to submit on "Weiter" (null: already applied, e.g. a
  /// remote move).
  final Map<String, dynamic>? pending;

  const _Trick({
    required this.picker,
    required this.stat,
    required this.a,
    required this.b,
    required this.va,
    required this.vb,
    required this.winner,
    required this.pot,
    required this.pending,
    this.countA,
    this.countB,
  });

  static _Trick? fromPayload(QuartettDeck deck, Player picker, Object? payload, Map<String, dynamic>? pending) {
    if (payload is! Map) return null;
    final stat = deck.statById('${payload['stat']}');
    final cards = payload['cards'], values = payload['values'];
    if (stat == null || cards is! Map || values is! Map) return null;
    final a = deck.cardById('${cards['a']}'), b = deck.cardById('${cards['b']}');
    if (a == null || b == null) return null;
    final w = payload['trickWinner'];
    return _Trick(
      picker: picker,
      stat: stat,
      a: a,
      b: b,
      va: values['a'] as num,
      vb: values['b'] as num,
      winner: w == 'a' ? Player.a : (w == 'b' ? Player.b : null),
      pot: (payload['pot'] as num?)?.toInt() ?? 0,
      pending: pending,
    );
  }

  /// Who picks after this trick: the winner, or the same player after a tie.
  Player get nextPicker => winner ?? picker;

  /// This trick as applied, with the stack sizes of [game] (the state right
  /// after it), or without counts.
  _Trick applied([QuartettGame? game]) => _Trick(
        picker: picker,
        stat: stat,
        a: a,
        b: b,
        va: va,
        vb: vb,
        winner: winner,
        pot: pot,
        pending: null,
        countA: game?.stackSize(Player.a) ?? countA,
        countB: game?.stackSize(Player.b) ?? countB,
      );
}

class _QuartettTrumpfBoard extends StatefulWidget {
  final GameController controller;
  const _QuartettTrumpfBoard({required this.controller});

  @override
  State<_QuartettTrumpfBoard> createState() => _QuartettTrumpfBoardState();
}

class _QuartettTrumpfBoardState extends State<_QuartettTrumpfBoard> with SingleTickerProviderStateMixin {
  /// The trick result on screen (null: the table).
  _Trick? _reveal;

  /// Network: tricks that arrived while [_reveal] was still in its grace
  /// period (or "Vorige Runde" was open), shown in order afterwards.
  final List<_Trick> _queue = [];

  /// Network, waiting player: the grace period of [_reveal] (0 → 1).
  late final AnimationController _grace = AnimationController(vsync: this, duration: quartettRevealGrace)
    ..addStatusListener(_onGraceStatus);

  /// [_grace] runs for the current reveal (paused while peeking).
  bool _graceActive = false;

  /// Tricks the player has seen (applied ones only), newest last, at most
  /// [quartettTrickHistoryLength].
  final List<_Trick> _history = [];

  /// The "Vorige Runde" overlay is open: nothing new is revealed and the
  /// grace is paused until it closes.
  bool _peeking = false;

  /// Hot-seat: the previewed trick submitted on "Weiter".
  _Trick? _submittedTrick;

  late Object _transport;
  late int _seenMoves;
  bool _submitting = false;

  GameController get c => widget.controller;

  /// One local player (network): picks go out at once and "Weiter" never
  /// waits for the other device. Hot-seat keeps the preview flow.
  bool get _networked => c.transport.localPlayers.length == 1;

  @override
  void initState() {
    super.initState();
    _sync();
    c.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_QuartettTrumpfBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _clear();
      _sync();
    }
  }

  @override
  void dispose() {
    _grace.dispose();
    c.removeListener(_onChange);
    super.dispose();
  }

  void _sync() {
    _transport = c.transport;
    _seenMoves = c.moves.length;
  }

  /// Drops every reveal (restart, undo, new controller).
  void _clear() {
    _stopGrace();
    _reveal = null;
    _queue.clear();
    _history.clear();
    _submittedTrick = null;
    _submitting = false;
  }

  void _stopGrace() {
    _graceActive = false;
    _grace.stop();
    _grace.value = 0;
  }

  void _onGraceStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _graceActive && mounted) setState(_advance);
  }

  _Trick? _trickOf(AcceptedMove m) {
    final game = _game;
    return game == null ? null : _Trick.fromPayload(game.deck, m.player, m.event.payload, null);
  }

  void _record(_Trick t) {
    _history.add(t);
    while (_history.length > quartettTrickHistoryLength) {
      _history.removeAt(0);
    }
  }

  void _onChange() {
    if (!mounted) return;
    final moves = c.moves;
    if (!identical(_transport, c.transport) || moves.length < _seenMoves) {
      // Restart or undo: drop any reveal.
      _sync();
      setState(_clear);
      return;
    }
    if (moves.length > _seenMoves) {
      final game = _game;
      if (_networked) {
        // Every accepted pick (ours or the opponent's) is revealed from its
        // event; a trick that arrives during the grace period waits. Stack
        // sizes are known for the newest one only.
        _submitting = false;
        final fresh = [
          for (var i = _seenMoves; i < moves.length; i++)
            _trickOf(moves[i])?.applied(i == moves.length - 1 ? game : null),
        ].nonNulls.toList();
        _sync();
        setState(() => fresh.forEach(_enqueue));
        return;
      }
      if (_submitting) {
        // Our own previewed pick, already revealed.
        _submitting = false;
        final t = _submittedTrick;
        _submittedTrick = null;
        if (t != null) setState(() => _record(t.applied(game)));
      } else {
        // A move submitted without the preview (e.g. through the
        // controller): reveal it from its event.
        final next = _trickOf(moves.last)?.applied(game);
        _sync();
        setState(() => _show(next));
        return;
      }
    }
    _sync();
  }

  /// Shows [t] now, or queues it behind the reveal on screen or the open
  /// "Vorige Runde" overlay.
  void _enqueue(_Trick t) {
    if (_reveal == null && !_peeking) {
      _show(t);
    } else {
      _queue.add(t);
    }
  }

  /// Puts [t] on screen. On a network device the waiting player (not the
  /// next picker) gets [quartettRevealGrace] with a countdown; the next
  /// picker's reveal stays until "Weiter".
  void _show(_Trick? t) {
    _stopGrace();
    _reveal = t;
    if (t == null) return;
    if (t.pending == null) _record(t);
    if (_networked && t.nextPicker != c.transport.localPlayers.first) {
      _graceActive = true;
      if (!_peeking) _grace.forward(from: 0);
    }
  }

  /// Leaves the reveal on screen: the next queued trick, else the table.
  void _advance() => _show(_queue.isEmpty ? null : _queue.removeAt(0));

  QuartettGame? get _game {
    final g = c.game;
    return g is QuartettGame ? g : null;
  }

  /// Hot-seat: computes the trick for [stat] on a replayed copy of the
  /// engine; the real game is only changed on "Weiter". Network: submits at
  /// once (the host applies it immediately); the accepted event reveals it.
  void _pick(QuartettStat stat) {
    if (!c.canAct || _reveal != null || _submitting) return;
    final move = <String, dynamic>{'action': 'pick', 'stat': stat.id};
    final copy = _networked ? null : c.previewCopy();
    if (copy == null) {
      _submitting = true;
      c.submit(move).then((r) {
        if (!r.isAccepted) _submitting = false;
      });
      return;
    }
    final event = copy.applyMove(move);
    final trick = event == null || copy is! QuartettGame
        ? null
        : _Trick.fromPayload(copy.deck, c.game.currentPlayer, event.payload, move);
    if (trick != null) setState(() => _show(trick));
  }

  /// "Weiter": local only. Hot-seat submits the previewed pick; otherwise it
  /// just leaves the reveal (skipping the rest of a grace period).
  void _continue() {
    final trick = _reveal;
    if (trick == null) return;
    setState(_advance);
    final move = trick.pending;
    if (move == null) return;
    _submitting = true;
    _submittedTrick = trick;
    c.submit(move).then((r) {
      if (!r.isAccepted) _submitting = false;
    });
  }

  /// Opens the "Vorige Runde" overlay. Purely local: while it is open new
  /// tricks queue up and the grace pauses; closing it carries on.
  Future<void> _openLastTrick() async {
    if (_history.isEmpty || _peeking) return;
    final t = _history.last;
    setState(() => _peeking = true);
    _grace.stop();
    // The dialog route sits above the game's PlayerLabelsScope: pass it on.
    final labels = PlayerLabelsScope.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => PlayerLabelsScope(labels: labels, child: _LastTrickDialog(trick: t)),
    );
    if (!mounted) return;
    setState(() {
      _peeking = false;
      if (_reveal == null) {
        if (_queue.isNotEmpty) _advance();
      } else if (_graceActive) {
        _grace.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final l10n = AppLocalizations.of(context);
    if (game == null) return Center(child: Text(l10n.quartettNoGame));
    final shell = GameScreen.of(context);
    final reveal = _reveal;
    final choosing = reveal == null && c.canAct && game.topCard(game.currentPlayer) != null;
    final waiting = reveal == null && !game.isOver && _networked && !c.canAct;
    // KLD-089 (network): after the final trick the result dialog waits until
    // every trick this device still has to show (the one on screen and any
    // queued behind it) is through; otherwise the last tricks would only
    // play out under the modal dialog, unreadable and without a "Weiter".
    // Hot-seat previews the final trick before it is submitted, so its
    // result comes after the reveal anyway.
    shell.holdResult(_networked && game.isOver && (reveal != null || _queue.isNotEmpty));
    shell.setStatusOverride(_statusOverride(context));
    shell.setHint(choosing
        ? l10n.quartettTrumpfHintPick
        : waiting
            ? l10n.quartettTrumpfHintWaiting(PlayerLabelsScope.of(context).label(context, l10n, game.currentPlayer))
            : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _counts(context, game, reveal),
          const SizedBox(height: 8),
          if (reveal != null)
            _revealView(context, reveal)
          else if (!game.isOver)
            _tableView(context, game),
        ],
      ),
    );
  }

  /// The shell's status line follows the reveal instead of the live game
  /// (null: the live status):
  ///
  /// * KLD-091 (network): while older rounds are still on screen (more are
  ///   queued behind the reveal), with a badge "noch 2 Runden".
  /// * KLD-092 (hot-seat): while a previewed round result is on screen. The
  ///   pick is only applied on "Weiter", so the live status would still name
  ///   the picker ("Anna ist am Zug") while the result says "Ben wählt als
  ///   Nächstes". It uses the cue's words ("Ben wählt als Nächstes" / "Anna wählt
  ///   noch einmal"), with the player's name if set. (A result of a move
  ///   that is already applied needs no override: the live status agrees.)
  ShellStatus? _statusOverride(BuildContext context) {
    final reveal = _reveal;
    if (reveal == null) return null;
    if (_networked ? _queue.isEmpty : reveal.pending == null) return null;
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
    final next = reveal.nextPicker;
    final name = labels.label(context, l10n, next);
    return ShellStatus(
      text: !_networked
          ? (next == reveal.picker ? l10n.quartettTrumpfPicksAgain(name) : l10n.quartettTrumpfNextPicker(name))
          : labels.isLocal(next)
              ? l10n.quartettTrumpfYouPickNext(playerMark(next))
              : l10n.quartettTrumpfNextPicker(name),
      player: next,
      badge: _queue.isEmpty ? null : l10n.quartettTrumpfTricksBehind(_queue.length),
    );
  }

  /// Every change of the reveal or the queue goes through here, so the
  /// status line follows in the same frame (from `build` alone it would lag
  /// one frame behind the reveal).
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    GameScreen.of(context).setStatusOverride(_statusOverride(context));
  }

  /// Stack counts of both players plus the pot, and the "Vorige Runde"
  /// button. During a hot-seat reveal the counts are those before the trick
  /// (the pick is not applied yet); on a network device the current ones.
  Widget _counts(BuildContext context, QuartettGame game, _Trick? reveal) {
    Widget chip(String key, IconData icon, String text) => Chip(
          key: Key(key),
          avatar: Icon(icon, size: 18),
          label: Text(text),
          visualDensity: VisualDensity.compact,
        );
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip('qt-count-a', Icons.person, l10n.quartettPlayerCards(playerName(context, Player.a), game.stackSize(Player.a))),
        chip('qt-count-b', Icons.person_outline, l10n.quartettPlayerCards(playerName(context, Player.b), game.stackSize(Player.b))),
        if (game.potSize > 0) chip('qt-pot', Icons.savings_outlined, l10n.quartettTrumpfPot(game.potSize)),
        ActionChip(
          key: const Key('qt-last-trick'),
          avatar: const Icon(Icons.history, size: 18),
          label: Text(l10n.quartettTrumpfLastTrick),
          visualDensity: VisualDensity.compact,
          onPressed: _history.isEmpty ? null : _openLastTrick,
        ),
      ],
    );
  }

  /// Whose card this device shows: the single local player, or (hot-seat)
  /// the player to move.
  Player _viewer(QuartettGame g) {
    final local = c.transport.localPlayers;
    return local.length == 1 ? local.first : g.currentPlayer;
  }

  /// Own top card face-up (stats tappable), opponent's stack face-down.
  Widget _tableView(BuildContext context, QuartettGame game) {
    final me = _viewer(game);
    final opp = me == Player.a ? Player.b : Player.a;
    final top = game.topCard(me);
    if (top == null) return const SizedBox.shrink();
    final own = QuartettCard(
      key: const Key('qt-own-card'),
      card: top,
      statKeyPrefix: 'qt-stat-',
      onStatTap: _pick,
      enabled: c.canAct,
    );
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    Widget caption(String s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(s, style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
        );
    final oppStack = SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          caption(l10n.quartettTrumpfOpponentStack(playerName(context, opp))),
          QuartettCard.back(
            key: const Key('qt-opponent-stack'),
            deck: game.deck.id,
            label: playerMark(opp),
            count: game.stackSize(opp),
            dense: true,
          ),
        ],
      ),
    );
    final ownColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [caption(l10n.quartettTrumpfYourCard(playerName(context, me))), own],
    );
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth >= 520) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: ownColumn), const SizedBox(width: 16), oppStack],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [ownColumn, const SizedBox(height: 12), Center(child: oppStack)],
      );
    });
  }

  Widget _revealView(BuildContext context, _Trick t) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = _trickColor(context, t);
    final queued = _queue.isEmpty ? null : _queue.first;

    return Column(
      key: const Key('qt-reveal'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: LayoutBuilder(builder: (context, box) {
            return Row(
              children: [
                Expanded(child: _TrickSummary(trick: t)),
                const SizedBox(width: 12),
                // At most half the row: a long "Weiter – Anna wählt" (fr, fa)
                // wraps instead of overflowing.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth / 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FilledButton(
                        key: const Key('qt-continue'),
                        onPressed: _continue,
                        child: Text(
                          l10n.quartettTrumpfContinuePicker(playerName(context, t.nextPicker)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_graceActive) ...[
                        const SizedBox(height: 6),
                        _countdown(context),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        if (queued != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              key: const Key('qt-queued-notice'),
              children: [
                Icon(Icons.notifications_active_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.quartettTrumpfQueuedPick(playerName(context, queued.picker), localizedStatLabel(l10n, queued.stat.id)),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _TrickCards(trick: t),
      ],
    );
  }

  /// Ring plus seconds left of the grace period.
  Widget _countdown(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = quartettRevealGrace.inMilliseconds;
    return AnimatedBuilder(
      key: const Key('qt-grace'),
      animation: _grace,
      builder: (context, _) {
        final left = ((1 - _grace.value) * total / 1000).ceil().clamp(0, 999);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(value: 1 - _grace.value, strokeWidth: 2.5),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.quartettTrumpfGraceSeconds(left),
              key: const Key('qt-grace-seconds'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

Color _trickColor(BuildContext context, _Trick t) => quartettOutcomeColor(
    t.winner == null ? QuartettOutcome.tie : QuartettOutcome.win, KlunkiPalette.of(context).quartett);

/// "Anna wählt PS", who won (or the tie and the pot) and who picks next.
class _TrickSummary extends StatelessWidget {
  final _Trick trick;
  const _TrickSummary({required this.trick});

  @override
  Widget build(BuildContext context) {
    final t = trick;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final w = t.winner;
    final headline = w == null ? l10n.quartettTrumpfTie : l10n.quartettTrumpfWinsTrick(playerName(context, w));
    final picker = playerName(context, t.picker);
    // Who picks next (KLD-091): the winner, or the same player after a tie.
    final cue = w == null
        ? (t.pot > 0 ? l10n.quartettTrumpfPotAgain(t.pot, picker) : l10n.quartettTrumpfPicksAgain(picker))
        : w == t.picker
            ? l10n.quartettTrumpfPicksAgain(picker)
            : l10n.quartettTrumpfNextPicker(playerName(context, w));
    final color = _trickColor(context, t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.quartettTrumpfPicked(picker, localizedStatLabel(l10n, t.stat.id)),
            key: const Key('qt-reveal-picked'), style: theme.textTheme.bodyMedium),
        Text(
          headline,
          key: const Key('qt-reveal-text'),
          style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(
          cue,
          key: const Key('qt-next-picker'),
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Both cards of a trick, the picker's on the left, the chosen stat
/// highlighted in the outcome colours.
class _TrickCards extends StatelessWidget {
  final _Trick trick;
  const _TrickCards({required this.trick});

  @override
  Widget build(BuildContext context) {
    final t = trick;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final w = t.winner;
    final palette = KlunkiPalette.of(context).quartett;
    QuartettOutcome outcomeOf(Player p) =>
        w == null ? QuartettOutcome.tie : (w == p ? QuartettOutcome.win : QuartettOutcome.lose);

    Widget side(Player p, qe.Card card) {
      final o = outcomeOf(p);
      final word = switch (o) {
        QuartettOutcome.win => l10n.quartettTrumpfOutcomeWin,
        QuartettOutcome.lose => l10n.quartettTrumpfOutcomeLose,
        QuartettOutcome.tie => l10n.quartettTrumpfOutcomeTie,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.quartettTrumpfSideOutcome(playerName(context, p), word),
              key: Key('qt-reveal-${p.name}-outcome'),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: quartettOutcomeColor(o, palette), fontWeight: FontWeight.bold),
            ),
          ),
          QuartettCard(
            key: Key('qt-reveal-${p.name}'),
            card: card,
            highlightStat: t.stat.id,
            outcome: o,
            dense: true,
          ),
        ],
      );
    }

    final first = t.picker;
    final second = first == Player.a ? Player.b : Player.a;
    qe.Card cardOf(Player p) => p == Player.a ? t.a : t.b;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: side(first, cardOf(first))),
        const SizedBox(width: 8),
        Expanded(child: side(second, cardOf(second))),
      ],
    );
  }
}

/// "Vorige Runde": a peek at the most recent trick — both cards with the
/// chosen stat and values, who won (or the tie and the pot) and the stack
/// sizes right after it. Closes on a tap outside, the close button or Back.
class _LastTrickDialog extends StatelessWidget {
  final _Trick trick;
  const _LastTrickDialog({required this.trick});

  @override
  Widget build(BuildContext context) {
    final t = trick;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    String value(num v) => formatQuartettValue(t.stat, v,
        locale: Localizations.localeOf(context).languageCode, unit: localizedStatUnit(l10n, t.stat.id));
    final ca = t.countA, cb = t.countB;
    return Dialog(
      key: const Key('qt-last-trick-overlay'),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l10n.quartettTrumpfLastTrick, style: theme.textTheme.titleLarge)),
                  IconButton(
                    key: const Key('qt-last-trick-close'),
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              _TrickSummary(trick: t),
              const SizedBox(height: 4),
              Text(
                '${localizedStatLabel(l10n, t.stat.id)}: '
                '${playerName(context, Player.a)} ${value(t.va)} – ${playerName(context, Player.b)} ${value(t.vb)}',
                key: const Key('qt-last-trick-values'),
                style: theme.textTheme.bodyMedium,
              ),
              if (ca != null && cb != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [
                      l10n.quartettPlayerCards(playerName(context, Player.a), ca),
                      l10n.quartettPlayerCards(playerName(context, Player.b), cb),
                      if (t.pot > 0) l10n.quartettTrumpfPot(t.pot),
                    ].join(' · '),
                    key: const Key('qt-last-trick-counts'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              _TrickCards(trick: t),
            ],
          ),
        ),
      ),
    );
  }
}

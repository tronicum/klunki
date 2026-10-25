import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/debug.dart';

/// Text-based debug frontend: the same [DebugConsole] as the terminal CLI,
/// rendered in a monospace log with a command field. Lets us exercise the
/// engines on real Android / iOS / web builds before the game screens exist.
class DebugConsoleScreen extends StatefulWidget {
  const DebugConsoleScreen({super.key});

  @override
  State<DebugConsoleScreen> createState() => _DebugConsoleScreenState();
}

class _DebugConsoleScreenState extends State<DebugConsoleScreen> {
  final _console = DebugConsole();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  late final List<String> _log = [_console.screen, 'Type "help" for commands.'];

  void _submit(String line) {
    setState(() => _log
      ..add('> $line')
      ..add(_console.handle(line)));
    _input.clear();
    _focus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const mono = TextStyle(fontFamily: 'monospace', fontFamilyFallback: ['Menlo', 'Courier'], fontSize: 14);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debugConsoleTitle),
        actions: [
          IconButton(tooltip: l10n.debugUndo, icon: const Icon(Icons.undo), onPressed: () => _submit('undo')),
          PopupMenuButton<String>(
            key: const Key('debug-menu'),
            tooltip: l10n.debugMenu,
            onSelected: _submit,
            itemBuilder: (_) => [
              for (final id in DebugConsole.games.keys) PopupMenuItem(value: 'new $id', child: Text(l10n.debugNewGame(id))),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'moves', child: Text(l10n.debugLegalMoves)),
              PopupMenuItem(value: 'auto', child: Text(l10n.debugAutoPlay)),
              PopupMenuItem(value: 'demo', child: Text(l10n.debugDemo)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _log.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectableText(_log[i], style: mono),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                key: const Key('debug-input'),
                controller: _input,
                focusNode: _focus,
                autofocus: true,
                style: mono,
                decoration: const InputDecoration(prefixText: '> ', border: OutlineInputBorder(), isDense: true),
                onSubmitted: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

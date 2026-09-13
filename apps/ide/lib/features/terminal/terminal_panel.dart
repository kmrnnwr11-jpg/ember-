import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import 'terminals_controller.dart';

/// Terminal tabs + xterm view + special-key bar for touch devices.
class TerminalPanel extends StatelessWidget {
  const TerminalPanel({super.key, required this.controller, this.showKeyBar});

  final TerminalsController controller;

  /// Defaults to true on Android/iOS.
  final bool? showKeyBar;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mobile = showKeyBar ??
        (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS));
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.activeSession;
        return Container(
          color: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              _Tabs(controller: controller),
              Expanded(
                child: s == null
                    ? Center(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: _Launcher(controller: controller)))
                    : Stack(
                        children: [
                          TerminalView(
                            s.terminal,
                            key: ObjectKey(s),
                            autofocus: true,
                            padding: const EdgeInsets.all(6),
                            textStyle: const TerminalStyle(fontSize: 13),
                            theme: TerminalThemes.defaultTheme,
                          ),
                          if (s.exited)
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: FilledButton.icon(
                                onPressed: () => controller.restart(s),
                                icon: const Icon(Icons.restart_alt),
                                label: Text(l.restart),
                              ),
                            ),
                        ],
                      ),
              ),
              if (mobile && s != null) _KeyBar(controller: controller, ctrl: s.ctrlArmed),
            ],
          ),
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.controller});

  final TerminalsController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.sessions.length,
              itemBuilder: (context, i) {
                final s = controller.sessions[i];
                final selected = i == controller.active;
                return InkWell(
                  onTap: () => controller.activate(i),
                  child: Container(
                    padding: const EdgeInsets.only(left: 10, right: 2),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: selected ? Colors.blueAccent : Colors.transparent, width: 2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.terminal, size: 14, color: s.exited ? Colors.grey : Colors.white70),
                        const SizedBox(width: 4),
                        Text('${l.terminal} ${s.title}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        IconButton(
                          iconSize: 14,
                          visualDensity: VisualDensity.compact,
                          color: Colors.white54,
                          icon: const Icon(Icons.close),
                          onPressed: () => controller.close(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _NewTerminalMenu(controller: controller),
        ],
      ),
    );
  }
}

class _KeyBar extends StatelessWidget {
  const _KeyBar({required this.controller, required this.ctrl});

  final TerminalsController controller;
  final bool ctrl;

  static const _keys = <(String, String)>[
    ('Esc', '\x1b'),
    ('Tab', '\t'),
    ('↑', '\x1b[A'),
    ('↓', '\x1b[B'),
    ('←', '\x1b[D'),
    ('→', '\x1b[C'),
    ('|', '|'),
    ('~', '~'),
    ('/', '/'),
    ('-', '-'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback onTap, {bool active = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: active ? Colors.blueAccent : const Color(0xFF333333),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ),
      ),
    );

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      color: const Color(0xFF252526),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          key('Ctrl', controller.toggleCtrl, active: ctrl),
          key('⏎', () => controller.send('\r')),
          key('^C', () => controller.send('\x03')),
          for (final (label, seq) in _keys) key(label, () => controller.send(seq)),
          key('📋', () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            final text = data?.text;
            if (text != null) controller.paste(text);
          }),
        ],
      ),
    );
  }
}


List<(TerminalProfile, IconData, String?)> _profiles(Map<String, dynamic>? health) {
  final shells = (health?['shells'] as List?)?.cast<String>() ?? const ['cmd', 'powershell'];
  final cli = (health?['cli'] as Map?) ?? const {};
  return [
    if (shells.contains('cmd')) (TerminalProfile.cmd, Icons.terminal, null),
    if (shells.contains('powershell')) (TerminalProfile.powershell, Icons.terminal, null),
    if (shells.contains('bash')) (TerminalProfile.bash, Icons.terminal, null),
    (TerminalProfile.claude, Icons.auto_awesome, cli['claude'] == true ? null : 'claude'),
    (TerminalProfile.codex, Icons.chat_bubble_outline, cli['codex'] == true ? null : 'codex'),
    (TerminalProfile.gemini, Icons.diamond_outlined, cli['gemini'] == true ? null : 'gemini'),
  ];
}

class _NewTerminalMenu extends ConsumerWidget {
  const _NewTerminalMenu({required this.controller});
  final TerminalsController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profiles = _profiles(ref.watch(runnerHealthProvider).value);
    return PopupMenuButton<TerminalProfile>(
      key: const Key('newTerminalMenu'),
      tooltip: l.newTerminal,
      icon: const Icon(Icons.add, size: 18, color: Colors.white70),
      onSelected: controller.open,
      itemBuilder: (_) => [
        for (final (p, icon, missing) in profiles)
          PopupMenuItem(
            value: p,
            enabled: missing == null,
            child: ListTile(
              dense: true,
              leading: Icon(icon),
              title: Text(p.title),
              subtitle: missing == null ? null : Text(l.cliNotInstalled(missing)),
            ),
          ),
      ],
    );
  }
}

class _Launcher extends ConsumerWidget {
  const _Launcher({required this.controller});
  final TerminalsController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profiles = _profiles(ref.watch(runnerHealthProvider).value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.newTerminal, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final (p, icon, missing) in profiles)
              FilledButton.tonalIcon(
                key: Key('term_${p.id}'),
                onPressed: missing == null ? () => controller.open(p) : null,
                icon: Icon(icon),
                label: Text(p.title),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(l.terminalCliHint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}

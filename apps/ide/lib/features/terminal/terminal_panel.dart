import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
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
          color: context.ember.codeSurface,
          child: Column(
            children: [
              _Tabs(controller: controller),
              Expanded(
                child: s == null
                    ? Center(child: SingleChildScrollView(padding: const EdgeInsets.all(Gap.lg), child: _Launcher(controller: controller)))
                    : Stack(
                        children: [
                          TerminalView(
                            s.terminal,
                            key: ObjectKey(s),
                            autofocus: true,
                            padding: const EdgeInsets.all(Gap.sm),
                            textStyle: const TerminalStyle(fontSize: 13),
                            theme: TerminalThemes.defaultTheme,
                            // The panel's own dark surface shows through.
                            backgroundOpacity: 0,
                          ),
                          if (s.exited)
                            PositionedDirectional(
                              end: Gap.md,
                              bottom: Gap.md,
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
    return TabStrip(
      onDark: true,
      selected: controller.active,
      onSelect: controller.activate,
      onClose: controller.close,
      closeTooltip: l.close,
      items: [
        for (final s in controller.sessions) TabStripItem(label: '${l.terminal} ${s.title}', icon: Icons.terminal, muted: s.exited),
      ],
      trailing: [_NewTerminalMenu(controller: controller)],
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
    final scheme = context.scheme;
    final ember = context.ember;
    final l = AppLocalizations.of(context);
    Widget key(String label, VoidCallback onTap, {bool active = false, IconData? icon}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: active ? scheme.primary : ember.onCodeSurface.withValues(alpha: 0.14),
        borderRadius: Radii.smAll,
        child: InkWell(
          borderRadius: Radii.smAll,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
            child: icon != null
                ? Tooltip(message: label, child: Icon(icon, size: 18, color: ember.onCodeSurface, semanticLabel: label))
                : Text(label, style: TextStyle(color: active ? scheme.onPrimary : ember.onCodeSurface, fontSize: 14)),
          ),
        ),
      ),
    );

    // Terminal keys keep their left-to-right order in every language.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.all(Gap.xs),
        decoration: BoxDecoration(
          color: ember.codeSurface,
          border: Border(top: BorderSide(color: ember.onCodeSurface.withValues(alpha: 0.12))),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              key('Ctrl', controller.toggleCtrl, active: ctrl),
              key('⏎', () => controller.send('\r')),
              key('^C', () => controller.send('\x03')),
              for (final (label, seq) in _keys) key(label, () => controller.send(seq)),
              key(l.paste, icon: Icons.content_paste_outlined, () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text;
                if (text != null) controller.paste(text);
              }),
            ],
          ),
        ),
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
      icon: Icon(Icons.add, size: 18, color: context.ember.onCodeSurface),
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
    final ember = context.ember;
    final profiles = _profiles(ref.watch(runnerHealthProvider).value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.newTerminal, style: TextStyle(color: ember.onCodeSurface, fontSize: 16)),
        Gap.vMd,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
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
        Gap.vMd,
        Text(l.terminalCliHint, textAlign: TextAlign.center, style: TextStyle(color: ember.codeMuted, fontSize: 12)),
      ],
    );
  }
}

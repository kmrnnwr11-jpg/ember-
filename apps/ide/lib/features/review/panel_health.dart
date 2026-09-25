import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mockups/mockup_controller.dart' show PanelMember;
import 'reviewers.dart';

/// The models that answered, and what the user decided about the ones that
/// did not. [proceed] is false when the user chose to stop; [members] holds
/// only the ones that answered, ready to be put to work.
typedef PanelCheck = ({bool proceed, Set<String> working, List<PanelMember> members});

/// Asks every model one question before any work starts and, when one does not
/// answer, stops and says which.
///
/// Nothing begins behind the user's back. A model that is out of quota or
/// logged out drops out in silence: the mockups still appear, the app still
/// builds, so nothing looks wrong — but the work was done and judged by fewer
/// models than the user believes, and that is exactly the kind of quiet loss
/// this is meant to prevent. So the question is asked out loud, with the name,
/// and the answer is the user's: fix it and retry, go on without it, or stop.
Future<PanelCheck> checkPanel(BuildContext context, WidgetRef ref) async {
  final settings = await ref.read(reviewerSettingsProvider.future);
  // Two members need no key from the user: Gemini runs on the Runner's own,
  // Claude on the machine's login. Both are free to the user and always there.
  final gemini = await runnerGeminiMember(ref);
  final claude = await runnerClaudeMember(ref);
  final all = [?claude, ...designPanel(settings), ?gemini];
  if (all.isEmpty) return (proceed: true, working: <String>{}, members: all);

  final pings = await pingMembers(all);
  Set<String> okIds(List<PanelPing> p) => {for (final x in p.where((x) => x.ok)) x.id};

  if (pings.every((p) => p.ok)) {
    final working = okIds(pings);
    return (proceed: true, working: working, members: [for (final m in all) if (working.contains(m.id)) m]);
  }
  if (!context.mounted) return (proceed: false, working: okIds(pings), members: <PanelMember>[]);

  // Someone is down: hold everything and let the user decide.
  final result = await showDialog<({bool proceed, List<PanelPing> pings})>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PanelStatusDialog(members: all, initial: pings),
  );
  final finalPings = result?.pings ?? pings;
  final working = okIds(finalPings);
  return (
    proceed: result?.proceed ?? false,
    working: working,
    members: [for (final m in all) if (working.contains(m.id)) m],
  );
}

/// "Groq non sta funzionando" / "Groq e Gemini non stanno funzionando" /
/// "Groq, Gemini e OpenRouter non stanno funzionando" — every name is said,
/// because the user asked to be told which one it is.
String panelDownTitle(List<String> names) {
  if (names.isEmpty) return '';
  final joined = names.length == 1 ? names.first : '${names.take(names.length - 1).join(', ')} e ${names.last}';
  return '$joined ${names.length == 1 ? 'non sta funzionando' : 'non stanno funzionando'}';
}

/// What is left to work with once the broken ones are out.
String panelDownExplanation(int workingCount) => switch (workingCount) {
      0 => 'Non resta nessun AI: non si può disegnare né controllare niente. Riprova, oppure chiudi.',
      1 => 'Resta 1 solo AI: disegnerà da solo e nessuno controllerà il suo lavoro.',
      _ => 'Restano $workingCount AI che lavorano insieme e si controllano a vicenda.',
    };

/// The button that goes on anyway, named after who would be missing.
String proceedWithoutLabel(List<String> missing) => switch (missing.length) {
      0 => 'Continua',
      1 => 'Vai avanti senza ${missing.first}',
      _ => 'Vai avanti senza ${missing.length} AI',
    };

/// Closes Ember, as the user asked for when they choose to stop.
Future<void> quitEmber() async {
  await SystemNavigator.pop();
}

/// Every model with its state — green when it answers, red with the reason
/// when it does not — and a Riprova on each one that is down.
///
/// Nothing starts while this is open: the work waits here until the user says
/// to go on or to stop. A model that comes back after a retry turns green in
/// place, and once they are all green the only thing left to do is continue.
class PanelStatusDialog extends StatefulWidget {
  const PanelStatusDialog({super.key, required this.members, required this.initial});

  final List<PanelMember> members;
  final List<PanelPing> initial;

  @override
  State<PanelStatusDialog> createState() => _PanelStatusDialogState();
}

class _PanelStatusDialogState extends State<PanelStatusDialog> {
  late final Map<String, PanelPing> _state = {for (final p in widget.initial) p.id: p};
  final _busy = <String>{};

  List<PanelPing> get _pings => [for (final m in widget.members) _state[m.id]!];
  List<PanelPing> get _down => _pings.where((p) => !p.ok).toList();
  bool get _allOk => _down.isEmpty;

  Future<void> _retry(List<PanelMember> who) async {
    setState(() => _busy.addAll(who.map((m) => m.id)));
    final results = await pingMembers(who);
    if (!mounted) return;
    setState(() {
      for (final r in results) {
        _state[r.id] = r;
      }
      _busy.removeAll(who.map((m) => m.id));
    });
  }

  void _close(bool proceed) => Navigator.pop(context, (proceed: proceed, pings: _pings));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final down = _down;
    final workingCount = _pings.length - down.length;

    return AlertDialog(
      icon: Icon(
        _allOk ? Icons.check_circle : Icons.warning_amber_rounded,
        color: _allOk ? Colors.green : Colors.orange,
        size: 32,
      ),
      title: Text(_allOk ? 'Tutti gli AI funzionano' : panelDownTitle([for (final d in down) d.label])),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final m in widget.members)
              _MemberRow(
                ping: _state[m.id]!,
                busy: _busy.contains(m.id),
                onRetry: () => _retry([m]),
              ),
            const SizedBox(height: 10),
            Text(panelDownExplanation(workingCount), style: theme.textTheme.bodyMedium),
            if (!_allOk) ...[
              const SizedBox(height: 8),
              Text(
                'Niente parte finché non decidi tu. Se è un problema di login o di chiave, '
                'sistemalo adesso e premi Riprova: quando torna verde si va avanti con tutti.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_allOk)
          TextButton(onPressed: () => _close(false), child: const Text('Chiudi Ember')),
        if (!_allOk && _busy.isEmpty)
          TextButton(
            onPressed: () => _retry([for (final m in widget.members) if (!_state[m.id]!.ok) m]),
            child: const Text('Riprova tutti'),
          ),
        if (!_allOk && workingCount > 0)
          OutlinedButton(
            onPressed: () => _close(true),
            child: Text(proceedWithoutLabel([for (final d in down) d.label])),
          ),
        if (_allOk) FilledButton(onPressed: () => _close(true), child: const Text('Continua con tutti')),
      ],
    );
  }
}

/// One model: its name, whether it answered, and why not.
class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.ping, required this.busy, required this.onRetry});

  final PanelPing ping;
  final bool busy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    ping.ok ? Icons.check_circle : Icons.cancel,
                    size: 20,
                    color: ping.ok ? Colors.green : theme.colorScheme.error,
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ping.label, style: theme.textTheme.titleSmall),
                if (!ping.ok && !busy)
                  Text(
                    ping.error,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!ping.ok)
            TextButton(onPressed: busy ? null : onRetry, child: Text(busy ? 'Provo…' : 'Riprova')),
        ],
      ),
    );
  }
}

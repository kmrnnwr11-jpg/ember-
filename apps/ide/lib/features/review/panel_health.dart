import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mockups/mockup_controller.dart' show PanelMember;
import 'reviewers.dart';

/// The models that answered, and what the user decided about the ones that
/// did not. [proceed] is false when the user chose to stop; [members] holds
/// only the ones that answered, ready to be put to work.
typedef PanelCheck = ({bool proceed, Set<String> working, List<PanelMember> members});

/// Checks the design panel before any drawing starts and, when a model is
/// down, names it and asks whether to go on without it.
///
/// A model silently dropping out is the thing that quietly ruins a set: the
/// work still finishes, so nothing looks wrong, but it was drawn and judged by
/// fewer models than the user believes. So the question is asked out loud,
/// with the names, while there is still a choice.
Future<PanelCheck> checkPanel(BuildContext context, WidgetRef ref) async {
  final settings = await ref.read(reviewerSettingsProvider.future);
  // Gemini needs no key from the user: it runs on the Runner's own.
  final gemini = await runnerGeminiMember(ref);
  final all = [...designPanel(settings), ?gemini];
  if (all.length < 2) return (proceed: true, working: <String>{}, members: all);

  final pings = await pingMembers(all);
  final down = pings.where((p) => !p.ok).toList();
  final working = {for (final p in pings.where((p) => p.ok)) p.id};
  final members = [for (final m in all) if (working.contains(m.id)) m];
  if (down.isEmpty) return (proceed: true, working: working, members: members);
  if (!context.mounted) return (proceed: false, working: working, members: members);

  final answer = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (d) => PanelDownDialog(down: down, workingCount: working.length),
  );
  return (proceed: answer ?? false, working: working, members: members);
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
      0 => 'Non resta nessun AI del gruppo: disegnerà il motore principale, senza controlli. Vuoi procedere lo stesso?',
      1 => 'Resta 1 solo AI: disegnerà da solo e nessuno controllerà il suo lavoro. Vuoi procedere lo stesso?',
      _ => 'Restano $workingCount AI che disegnano e si controllano a vicenda. Vuoi procedere lo stesso?',
    };

/// Closes Ember, as the user asked for when they answer No.
Future<void> quitEmber() async {
  await SystemNavigator.pop();
}

/// Names every model that did not answer, says what is left, and lets the user
/// go on or stop.
class PanelDownDialog extends StatelessWidget {
  const PanelDownDialog({super.key, required this.down, required this.workingCount});

  final List<PanelPing> down;
  final int workingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
      title: Text(panelDownTitle([for (final d in down) d.label])),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final d in down)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• ${d.label}: ${d.error}', style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 8),
          Text(panelDownExplanation(workingCount), style: theme.textTheme.bodyMedium),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No, chiudi Ember'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sì, procedi'),
        ),
      ],
    );
  }
}

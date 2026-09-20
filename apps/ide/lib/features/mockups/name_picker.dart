import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'mockup_controller.dart' show CompleteText;

const _namesSystem = '''
You name mobile apps for the Google Play Store and the App Store.
Rules:
- Output ONLY a JSON array of strings. No markdown, no explanations.
- Each name: 2 to 30 characters, easy to say and to remember, in the language of the app description.
- Say what the app is for, or evoke it; no invented words nobody can spell.
- Never the name of an existing well-known app or brand, and never the name of the app being copied.
- Vary them: some plain and descriptive, some playful, some short and brandable.''';

/// Ten names for the app, drawn from what the user asked for.
Future<List<String>> suggestNames(CompleteText complete, String description, {int count = 10}) async {
  final res = await complete(_namesSystem, 'App description:\n${description.trim()}\n\nGive $count names as a JSON array.');
  final raw = RegExp(r'\[[\s\S]*\]').firstMatch(res.text)?.group(0);
  if (raw == null) return const [];
  try {
    return [
      for (final n in jsonDecode(raw) as List)
        if ('$n'.trim().isNotEmpty && '$n'.trim().length <= 30) '$n'.trim(),
    ].take(count).toList();
  } catch (_) {
    return const [];
  }
}

/// Choosing the app's name, before a line of it is written: the name reaches
/// the store listing, the privacy policy and the package name, and the package
/// name can never be changed once Google has it.
class NamePickerSheet extends StatefulWidget {
  const NamePickerSheet({super.key, required this.names, required this.loading, this.onRetry});

  final List<String> names;
  final bool loading;
  final Future<void> Function()? onRetry;

  @override
  State<NamePickerSheet> createState() => _NamePickerSheetState();
}

class _NamePickerSheetState extends State<NamePickerSheet> {
  final _own = TextEditingController();
  String? _picked;

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  String? get _choice {
    final typed = _own.text.trim();
    return typed.isNotEmpty ? typed : _picked;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.nameTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l.nameHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (widget.loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final n in widget.names)
                        ChoiceChip(
                          label: Text(n),
                          selected: _picked == n && _own.text.trim().isEmpty,
                          onSelected: (_) => setState(() {
                            _picked = n;
                            _own.clear();
                          }),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('ownAppName'),
              controller: _own,
              maxLines: 1,
              textInputAction: TextInputAction.go,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_choice != null) Navigator.pop(context, _choice);
              },
              decoration: InputDecoration(labelText: l.nameYourOwn, border: const OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.onRetry != null)
                  TextButton.icon(
                    onPressed: widget.loading ? null : () => widget.onRetry!(),
                    icon: const Icon(Icons.refresh),
                    label: Text(l.nameMore),
                  ),
                const Spacer(),
                FilledButton(
                  key: const Key('confirmAppName'),
                  onPressed: _choice == null ? null : () => Navigator.pop(context, _choice),
                  child: Text(l.nameUse),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

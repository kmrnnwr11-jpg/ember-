import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'reviewers.dart';

/// One reviewer's key, with an explicit Save button: typing into a box and
/// walking away must never lose the key, and the row says plainly whether one
/// is stored.
class ReviewerKeyRow extends ConsumerStatefulWidget {
  const ReviewerKeyRow({super.key, required this.reviewer, required this.settings});

  final Reviewer reviewer;
  final ReviewerSettings settings;

  /// Where each service hands out its key.
  static const signup = {
    'deepseek': 'https://platform.deepseek.com',
    'groq': 'https://console.groq.com/keys',
    'gemini': 'https://aistudio.google.com/apikey',
    'openrouter': 'https://openrouter.ai/keys',
  };

  @override
  ConsumerState<ReviewerKeyRow> createState() => _ReviewerKeyRowState();
}

class _ReviewerKeyRowState extends ConsumerState<ReviewerKeyRow> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  String? _note;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _note = 'Incolla prima la chiave.');
      return;
    }
    await ref.read(reviewerSettingsProvider.notifier).setKey(widget.reviewer.id, text);
    _ctrl.clear();
    if (mounted) setState(() => _note = 'Chiave salvata.');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reviewer;
    final saved = widget.settings.keys[r.id];
    final has = (saved ?? '').isNotEmpty;
    final url = ReviewerKeyRow.signup[r.id];
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(has ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18, color: has ? Colors.green : theme.disabledColor),
              const SizedBox(width: 8),
              Text(r.label, style: theme.textTheme.titleSmall),
              const Spacer(),
              if (has) Chip(label: Text('•••• ${saved!.length > 4 ? saved.substring(saved.length - 4) : ''}')),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                isDense: true,
                labelText: has ? 'Sostituisci la chiave' : 'Chiave API',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Incolla',
                      icon: const Icon(Icons.content_paste, size: 18),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        final t = data?.text?.trim() ?? '';
                        if (t.isNotEmpty) _ctrl.text = t;
                      },
                    ),
                    IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, size: 18),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(onPressed: _save, child: const Text('Salva')),
                if (has)
                  TextButton(
                    onPressed: () async {
                      await ref.read(reviewerSettingsProvider.notifier).setKey(r.id, '');
                      if (mounted) setState(() => _note = 'Chiave rimossa.');
                    },
                    child: const Text('Elimina'),
                  ),
                if (url != null)
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Prendi la chiave'),
                    onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                  ),
              ],
            ),
            if (_note != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_note!, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

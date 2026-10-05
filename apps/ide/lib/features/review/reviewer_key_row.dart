import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
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
  String? _note;
  bool _noteIsError = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() {
        _note = l.reviewPasteKeyFirst;
        _noteIsError = true;
      });
      return;
    }
    await ref.read(reviewerSettingsProvider.notifier).setKey(widget.reviewer.id, text);
    _ctrl.clear();
    if (mounted) {
      setState(() {
        _note = l.reviewKeySaved;
        _noteIsError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = widget.reviewer;
    final saved = widget.settings.keys[r.id];
    final has = (saved ?? '').isNotEmpty;
    final url = ReviewerKeyRow.signup[r.id];

    return SectionCard(
      margin: const EdgeInsets.only(bottom: Gap.md),
      icon: has ? Icons.check_circle_outline : Icons.radio_button_unchecked,
      title: r.label,
      trailing: has ? Pill('•••• ${saved!.length > 4 ? saved.substring(saved.length - 4) : ''}', tone: Tone.success) : null,
      children: [
        Gap.vSm,
        SecretField(
          controller: _ctrl,
          label: has ? l.replaceApiKey : l.apiKey,
          getUrl: url,
          getLabel: l.getKey,
          onSubmitted: (_) => _save(),
        ),
        Gap.vSm,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(onPressed: _save, child: Text(l.save)),
            if (has)
              TextButton(
                onPressed: () async {
                  await ref.read(reviewerSettingsProvider.notifier).setKey(r.id, '');
                  if (mounted) {
                    setState(() {
                      _note = l.reviewKeyRemoved;
                      _noteIsError = false;
                    });
                  }
                },
                child: Text(l.delete),
              ),
          ],
        ),
        if (_note != null) ...[Gap.vSm, InlineMessage(_note!, error: _noteIsError)],
      ],
    );
  }
}

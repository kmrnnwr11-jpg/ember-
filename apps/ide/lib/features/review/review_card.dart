import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import 'review_state.dart';
import 'reviewers.dart';

/// Where the user turns on the models that check a finished app, and reads what
/// they found. Several models, each reading on its own: what more than one of
/// them saw is the most trustworthy thing on the list.
class ReviewCard extends ConsumerStatefulWidget {
  const ReviewCard({super.key, required this.projectId, this.onFix});

  final String projectId;

  /// Sends one finding back to the engine that wrote the app, to be put right.
  /// Returns when the fix has been applied, so the card can mark it done
  /// instead of guessing.
  final Future<void> Function(String ask)? onFix;

  @override
  ConsumerState<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<ReviewCard> {
  bool _busy = false;
  bool _setupOpen = false;
  String? _error;

  ReviewState get _state => ref.watch(reviewStatesProvider.notifier).of(widget.projectId);
  List<Map<String, dynamic>> get _findings => _state.findings;
  List<Map<String, dynamic>> get _reports => _state.reports;

  /// Where each service hands out its key, so the user is one tap away from it.
  static const _signup = {
    'deepseek': 'https://platform.deepseek.com',
    'groq': 'https://console.groq.com/keys',
    'github': 'https://github.com/marketplace/models',
    'openrouter': 'https://openrouter.ai/keys',
  };

  Future<void> _run(ReviewerSettings s) async {
    final usable = s.usable;
    if (usable.isEmpty) {
      setState(() => _setupOpen = true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    ref.read(reviewStatesProvider.notifier).found(widget.projectId, const [], const []);
    try {
      final api = await ref.read(runnerApiProvider.future);
      final res = await api.reviewApp(widget.projectId, [
        for (final r in usable)
          {'id': r.id, 'label': r.label, 'baseUrl': r.baseUrl, 'apiKey': s.keys[r.id]!, 'model': r.model},
      ]);
      if (!mounted) return;
      ref.read(reviewStatesProvider.notifier).found(
            widget.projectId,
            [for (final f in (res['findings'] as List? ?? const [])) (f as Map).cast<String, dynamic>()],
            [for (final r in (res['reports'] as List? ?? const [])) (r as Map).cast<String, dynamic>()],
          );
    } on RunnerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(reviewerSettingsProvider);

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: async.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
          error: (e, _) => Text('$e'),
          data: (s) {
            final ready = s.usable.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Icon(Icons.fact_check_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Controllo dell\'app', style: theme.textTheme.titleMedium)),
                  IconButton(
                    tooltip: 'Revisori',
                    icon: Icon(_setupOpen ? Icons.expand_less : Icons.tune),
                    onPressed: () => setState(() => _setupOpen = !_setupOpen),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  ready == 0
                      ? 'Fai controllare l\'app finita da piu\' intelligenze artificiali: ognuna la legge per conto suo e dice cosa e\' finto, cosa manca e cosa non funziona. Aggiungi almeno un revisore qui sotto.'
                      : '$ready ${ready == 1 ? 'revisore pronto' : 'revisori pronti'}. Ognuno legge l\'app per conto suo; quello che vedono in piu\' di uno finisce in cima alla lista.',
                  style: theme.textTheme.bodySmall,
                ),
                if (_setupOpen) ...[
                  const SizedBox(height: 12),
                  for (final r in s.reviewers) _reviewerRow(r, s),
                ],
                if (_busy) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('I revisori stanno leggendo l\'app…')),
                  ]),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  SelectableText(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                if (_reports.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final r in _reports)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          r['ok'] == true ? Icons.check_circle : Icons.error_outline,
                          size: 16,
                          color: r['ok'] == true ? Colors.green : theme.colorScheme.error,
                        ),
                        label: Text(
                          r['ok'] == true
                              ? '${r['label']}: ${(r['findings'] as List? ?? const []).length}'
                              : '${r['label']}: non risponde',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ]),
                ],
                if (_findings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final f in _findings) _findingTile(f, theme),
                ] else if (_reports.isNotEmpty && !_busy) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.verified_outlined, color: Colors.green),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Nessun problema trovato dai revisori.')),
                  ]),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _run(s),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(ready == 0 ? 'Aggiungi un revisore' : 'Controlla l\'app'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _reviewerRow(Reviewer r, ReviewerSettings s) {
    final has = s.hasKey(r.id);
    final url = _signup[r.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(has ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18, color: has ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          SizedBox(width: 108, child: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: TextField(
              obscureText: true,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                hintText: has ? '•••••• (chiave salvata)' : 'incolla qui la chiave',
                suffixIcon: IconButton(
                  tooltip: 'Incolla',
                  icon: const Icon(Icons.content_paste, size: 18),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    final t = data?.text?.trim() ?? '';
                    if (t.isEmpty) return;
                    await ref.read(reviewerSettingsProvider.notifier).setKey(r.id, t);
                  },
                ),
              ),
              onSubmitted: (v) => ref.read(reviewerSettingsProvider.notifier).setKey(r.id, v),
            ),
          ),
          if (url != null)
            IconButton(
              tooltip: 'Prendi la chiave',
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            ),
          if (has)
            IconButton(
              tooltip: 'Togli la chiave',
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => ref.read(reviewerSettingsProvider.notifier).setKey(r.id, ''),
            ),
        ],
      ),
    );
  }

  /// Sends one finding to be fixed and keeps it on the list while that runs.
  Future<void> _fix(String title, String ask) async {
    final notifier = ref.read(reviewStatesProvider.notifier);
    notifier.startFixing(widget.projectId, title);
    try {
      await widget.onFix!(ask);
      notifier.doneFixing(widget.projectId, title);
    } catch (e) {
      notifier.failedFixing(widget.projectId, title);
      if (mounted) setState(() => _error = '$e');
    }
  }

  Widget _findingTile(Map<String, dynamic> f, ThemeData theme) {
    final ask = '${f['ask'] ?? ''}'.trim();
    final title = '${f['title']}';
    final done = _state.fixed.contains(title);
    final busy = _state.fixing.contains(title);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${f['title']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${f['detail']}', style: theme.textTheme.bodySmall),
            if (ask.isNotEmpty && widget.onFix != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                // A finding stays on the list after it has been sent to be
                // fixed, marked as done. It disappears only when a new review
                // no longer reports it: the engine saying it fixed something
                // is not the same as it being fixed.
                child: done
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: Colors.green),
                          const SizedBox(width: 6),
                          Text('Corretto — da ricontrollare', style: theme.textTheme.bodySmall),
                        ],
                      )
                    : busy
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              const SizedBox(width: 8),
                              Text('Sto correggendo…', style: theme.textTheme.bodySmall),
                            ],
                          )
                        : TextButton.icon(
                            onPressed: () => _fix(title, ask),
                            icon: const Icon(Icons.auto_fix_high, size: 18),
                            label: const Text('Correggi'),
                          ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

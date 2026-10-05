import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
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

  static const _icon = Icons.fact_check_outlined;

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
    final async = ref.watch(reviewerSettingsProvider);
    final l = AppLocalizations.of(context);
    final title = l.reviewTitle;

    return async.when(
      loading: () => SectionCard(icon: _icon, title: title, children: const [Gap.vSm, LoadingState()]),
      error: (e, _) => SectionCard(
        icon: _icon,
        title: title,
        children: [ErrorState(message: '$e', onRetry: () => ref.invalidate(reviewerSettingsProvider))],
      ),
      data: (s) {
        final ready = s.usable.length;
        return SectionCard(
          icon: _icon,
          title: title,
          hint: ready == 0 ? l.reviewHintNone : l.reviewHintReady(ready),
          trailing: IconButton(
            tooltip: l.reviewReviewers,
            icon: Icon(_setupOpen ? Icons.expand_less : Icons.tune_outlined),
            onPressed: () => setState(() => _setupOpen = !_setupOpen),
          ),
          children: [
            if (_setupOpen) ...[
              Gap.vMd,
              for (final r in s.reviewers) _reviewerRow(r, s),
            ],
            if (_busy) ...[
              Gap.vMd,
              BusyRow(l.reviewReading),
            ],
            if (_error != null) ...[
              Gap.vMd,
              InlineMessage(_error!, error: true),
            ],
            if (_reports.isNotEmpty) ...[
              Gap.vMd,
              Wrap(spacing: Gap.sm, runSpacing: Gap.xs, children: [
                for (final r in _reports)
                  Pill(
                    r['ok'] == true
                        ? '${r['label']}: ${(r['findings'] as List? ?? const []).length}'
                        : l.reviewNoAnswer('${r['label']}'),
                    icon: r['ok'] == true ? Icons.check_circle_outline : Icons.error_outline,
                    tone: r['ok'] == true ? Tone.success : Tone.error,
                  ),
              ]),
            ],
            if (_findings.isNotEmpty) ...[
              Gap.vMd,
              for (final f in _findings) _findingTile(f),
            ] else if (_reports.isNotEmpty && !_busy) ...[
              Gap.vMd,
              StatusRow(done: true, text: l.reviewNothingFound),
            ],
            Gap.vMd,
            FilledButton.icon(
              onPressed: _busy ? null : () => _run(s),
              icon: const Icon(Icons.play_arrow_outlined),
              label: Text(ready == 0 ? l.reviewAddReviewer : l.reviewRun),
            ),
          ],
        );
      },
    );
  }

  /// One reviewer in the quick setup: pasting or submitting saves at once, so
  /// it stays a plain field instead of a SecretField with its own Save button.
  Widget _reviewerRow(Reviewer r, ReviewerSettings s) {
    final l = AppLocalizations.of(context);
    final has = s.hasKey(r.id);
    final url = _signup[r.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Row(
        children: [
          Icon(
            has ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 18,
            color: has ? context.ember.success : context.scheme.onSurfaceVariant,
          ),
          Gap.hSm,
          SizedBox(width: 108, child: Text(r.label, style: context.text.titleSmall)),
          Expanded(
            child: TextField(
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: has ? l.reviewKeySavedMask : l.reviewPasteKeyHint,
                suffixIcon: IconButton(
                  tooltip: l.paste,
                  icon: const Icon(Icons.content_paste_outlined),
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
              tooltip: l.getKey,
              icon: const Icon(Icons.open_in_new),
              onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            ),
          if (has)
            IconButton(
              tooltip: l.reviewRemoveKey,
              icon: const Icon(Icons.delete_outline),
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

  Widget _findingTile(Map<String, dynamic> f) {
    final l = AppLocalizations.of(context);
    final ask = '${f['ask'] ?? ''}'.trim();
    final title = '${f['title']}';
    final done = _state.fixed.contains(title);
    final busy = _state.fixing.contains(title);
    final fixable = ask.isNotEmpty && widget.onFix != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: FindingTile(
        title: title,
        detail: '${f['detail']}',
        fixable: fixable,
        // A finding stays on the list after it has been sent to be
        // fixed, marked as done. It disappears only when a new review
        // no longer reports it: the engine saying it fixed something
        // is not the same as it being fixed.
        action: !fixable
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: Gap.xs),
                child: done
                    ? StatusRow(done: true, text: l.reviewFixedRecheck)
                    : busy
                        ? BusyRow(l.reviewFixing)
                        : Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton.icon(
                              onPressed: () => _fix(title, ask),
                              icon: const Icon(Icons.auto_fix_high_outlined),
                              label: Text(l.reviewFix),
                            ),
                          ),
              ),
      ),
    );
  }
}

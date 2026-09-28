import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../review/panel_health.dart';
import '../review/reviewers.dart';
import 'app_builder.dart';

/// Logo studio: describe the logo (optional), get 6 proposals, "More logos" adds 5 more, pick one.
class LogoCard extends ConsumerStatefulWidget {
  const LogoCard({super.key, required this.builder, required this.projectId});
  final AppBuilder builder;
  final String projectId;

  @override
  ConsumerState<LogoCard> createState() => _LogoCardState();
}

class _LogoCardState extends ConsumerState<LogoCard> {
  final _hint = TextEditingController();
  final _logos = <({String id, Uint8List png})>[];
  String? _selected;
  String? _applied;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final s = await (await ref.read(runnerApiProvider.future)).storeState(widget.projectId);
      if (!mounted) return;
      setState(() {
        _logos
          ..clear()
          ..addAll([for (final l in (s['logos'] as List).cast<Map<String, dynamic>>()) (id: l['id'] as String, png: base64Decode(l['thumb'] as String))]);
        _applied = s['appliedLogo'] as String?;
        _selected ??= _applied;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _hint.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = await ref.read(runnerApiProvider.future);
      // The configured reviewers draw the icons together and then review each
      // other's drawings; with fewer than two the Runner's own engine draws.
      if (!mounted) return;
      final health = await checkPanel(context, ref, forDrawing: true);
      if (!health.proceed) return quitEmber();
      final settings = await ref.read(reviewerSettingsProvider.future);
      final reviewers = settings.usable.where((r) => health.working.contains(r.id)).toList();
      final res = await api.generateLogos(widget.projectId, {
        // The Runner takes 4000 characters, and a detailed brief runs well
        // past that: the whole logo step failed with "Too big: expected string
        // to have <=4000 characters", which says nothing about what to do.
        // A logo is drawn from what the app is, and that is in the opening
        // lines; the rest is instructions for the engine that writes it.
        'about': widget.builder.prompt.length <= 4000
            ? widget.builder.prompt
            : widget.builder.prompt.substring(0, 4000),
        if (_hint.text.trim().isNotEmpty) 'hint': _hint.text.trim(),
        // Five a round, each drawn by a different model in turn.
        'count': 5,
        if (ref.read(chosenDesignersProvider) case final only?) 'only': only.toList(),
        if (reviewers.length > 1)
          'panel': [
            for (final r in reviewers)
              {'id': r.id, 'label': r.label, 'baseUrl': r.baseUrl, 'apiKey': settings.keys[r.id]!, 'model': r.model},
          ],
        // Drawing is the graphics engine's job, not the coding engine's.
        'engine': widget.builder.designEngine == BuildEngine.claudeCode ? 'claude' : 'auto',
      });
      final list = (res['logos'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _logos.insertAll(0, [for (final l in list) (id: l['id'] as String, png: base64Decode(l['png'] as String))]);
      });
    } on RunnerException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    final id = _selected;
    if (id == null) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = await ref.read(runnerApiProvider.future);
      await api.applyLogo(widget.projectId, id);
      // Generate Android / iOS / web / Windows icons from the chosen logo.
      await ref.read(runnerSocketProvider).request(MsgType.jobStart, {'projectId': widget.projectId, 'kind': 'launcher_icons'});
      setState(() => _applied = id);
      messenger.showSnackBar(SnackBar(content: Text(l.logoApplied)));
    } on RunnerException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(l.logoTitle, style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.logoHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            TextField(
              key: const Key('logoHint'),
              controller: _hint,
              // One line, so Enter means "go" instead of a new line.
              maxLines: 1,
              // Enter starts the drawing: typing then pressing enter is what a
              // person expects here, not a hunt for the button.
              textInputAction: TextInputAction.go,
              onSubmitted: (_) {
                if (!_busy) _generate();
              },
              decoration: InputDecoration(labelText: l.logoDescribe, hintText: l.logoDescribeHint, border: const OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            if (_logos.isNotEmpty)
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 3 : 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  for (final logo in _logos)
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _busy ? null : () => setState(() => _selected = logo.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(width: 3, color: logo.id == _selected ? theme.colorScheme.primary : Colors.transparent),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(logo.png, fit: BoxFit.cover)),
                            if (logo.id == _applied)
                              const Align(alignment: Alignment.topRight, child: Padding(padding: EdgeInsets.all(4), child: Icon(Icons.check_circle, color: Colors.greenAccent))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('generateLogos'),
                  onPressed: _busy ? null : _generate,
                  icon: _busy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.brush_outlined),
                  label: Text(_logos.isEmpty ? l.logoGenerate : l.logoMore),
                ),
                if (_selected != null)
                  FilledButton.tonalIcon(
                    key: const Key('applyLogo'),
                    onPressed: _busy || _selected == _applied ? null : _apply,
                    icon: const Icon(Icons.check),
                    label: Text(l.logoUse),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

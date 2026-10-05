import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../review/panel_health.dart';
import '../review/reviewers.dart';
import 'app_builder.dart';

/// Logo studio: describe the logo (optional), get 6 proposals, "More logos" adds 5 more, pick one.
/// A proposal nobody wants is deleted; one the user likes is dragged into the
/// description box and comes back as 5 variants of itself.
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

  /// The logo dragged into the box: the next round draws variants of it.
  String? _base;
  bool _dragOver = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final s = await (await ref.read(
        runnerApiProvider.future,
      )).storeState(widget.projectId);
      if (!mounted) return;
      setState(() {
        _logos
          ..clear()
          ..addAll([
            for (final l in (s['logos'] as List).cast<Map<String, dynamic>>())
              (id: l['id'] as String, png: base64Decode(l['thumb'] as String)),
          ]);
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

  Future<void> _delete(String id) async {
    final l = AppLocalizations.of(context);
    try {
      await (await ref.read(
        runnerApiProvider.future,
      )).deleteLogo(widget.projectId, id);
      if (!mounted) return;
      setState(() {
        _logos.removeWhere((x) => x.id == id);
        if (_selected == id) _selected = _applied;
        if (_base == id) _base = null;
      });
      showEmberSnack(context, l.logoDeleted);
    } on RunnerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
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
      if (!health.proceed) return;
      final settings = await ref.read(reviewerSettingsProvider.future);
      final reviewers = settings.usable
          .where((r) => health.working.contains(r.id))
          .toList();
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
        // Variants of the logo the user dragged in.
        if (_base != null) 'base': _base,
        // Five a round, each drawn by a different model in turn.
        'count': 5,
        // Logos are drawn by Gemini and DeepSeek only: the user's choice.
        'only': const <String>['gemini_runner', 'deepseek'],
        if (reviewers.isNotEmpty)
          'panel': [
            for (final r in reviewers)
              {
                'id': r.id,
                'label': r.label,
                'baseUrl': r.baseUrl,
                'apiKey': settings.keys[r.id]!,
                'model': r.model,
              },
          ],
        // Drawing is the graphics engine's job, not the coding engine's.
        'engine': widget.builder.designEngine == BuildEngine.claudeCode
            ? 'claude'
            : 'auto',
      });
      final list = (res['logos'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _logos.insertAll(0, [
          for (final l in list)
            (id: l['id'] as String, png: base64Decode(l['png'] as String)),
        ]);
        _base = null;
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = await ref.read(runnerApiProvider.future);
      await api.applyLogo(widget.projectId, id);
      // Generate Android / iOS / web / Windows icons from the chosen logo.
      await ref.read(runnerSocketProvider).request(MsgType.jobStart, {
        'projectId': widget.projectId,
        'kind': 'launcher_icons',
      });
      setState(() => _applied = id);
      if (mounted) showEmberSnack(context, l.logoApplied);
    } on RunnerException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = context.scheme;
    final ember = context.ember;
    return SectionCard(
      icon: Icons.auto_awesome_outlined,
      title: l.logoTitle,
      hint: l.logoHint,
      children: [
        Gap.vMd,
        DragTarget<String>(
          onWillAcceptWithDetails: (d) {
            if (_busy) return false;
            setState(() => _dragOver = true);
            return true;
          },
          onLeave: (_) => setState(() => _dragOver = false),
          onAcceptWithDetails: (d) {
            setState(() {
              _dragOver = false;
              _base = d.data;
            });
            _generate();
          },
          builder: (context, _, _) => AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.curve,
            decoration: BoxDecoration(
              borderRadius: Radii.smAll,
              color: _dragOver ? scheme.primary.withValues(alpha: 0.12) : null,
              border: _dragOver ? Border.all(color: scheme.primary, width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_base != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.sm),
                    child: Row(
                      children: [
                        for (final b in _logos.where((x) => x.id == _base)) ClipRRect(borderRadius: Radii.smAll, child: Image.memory(b.png, width: 36, height: 36)),
                        Gap.hSm,
                        Expanded(child: Text(l.logoVariantsOf, style: context.text.bodyMedium)),
                        if (!_busy) IconButton(tooltip: l.close, icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _base = null)),
                      ],
                    ),
                  ),
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
                  decoration: InputDecoration(
                    labelText: l.logoDescribe,
                    hintText: l.logoDescribeHint,
                    helperText: l.logoDropHint,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        Gap.vMd,
        if (_logos.isNotEmpty)
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 3 : 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Gap.md,
            crossAxisSpacing: Gap.md,
            children: [
              for (final logo in _logos)
                Draggable<String>(
                  data: logo.id,
                  maxSimultaneousDrags: _busy ? 0 : 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.85,
                      child: ClipRRect(borderRadius: Radii.mdAll, child: Image.memory(logo.png, width: 96, height: 96)),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: ClipRRect(borderRadius: Radii.mdAll, child: Image.memory(logo.png, fit: BoxFit.cover)),
                  ),
                  child: InkWell(
                    borderRadius: Radii.lgAll,
                    onTap: _busy ? null : () => setState(() => _selected = logo.id),
                    child: AnimatedContainer(
                      duration: Motion.fast,
                      curve: Motion.curve,
                      padding: const EdgeInsets.all(Gap.xs),
                      decoration: BoxDecoration(
                        borderRadius: Radii.lgAll,
                        border: Border.all(width: 3, color: logo.id == _selected ? scheme.primary : Colors.transparent),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(borderRadius: Radii.mdAll, child: Image.memory(logo.png, fit: BoxFit.cover)),
                          if (logo.id == _applied)
                            Align(
                              alignment: AlignmentDirectional.topEnd,
                              child: Padding(
                                padding: const EdgeInsets.all(Gap.xs),
                                child: Icon(Icons.check_circle, color: ember.success),
                              ),
                            ),
                          // The applied logo is the app's icon: it cannot be deleted from here.
                          if (logo.id != _applied)
                            Align(
                              alignment: AlignmentDirectional.topStart,
                              // The visible mark stays small; the area that takes the tap is a full target.
                              child: Material(
                                type: MaterialType.transparency,
                                child: Tooltip(
                                  message: l.logoDelete,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: _busy ? null : () => _delete(logo.id),
                                    child: SizedBox.square(
                                      dimension: kTapTarget,
                                      child: Align(
                                        alignment: AlignmentDirectional.topStart,
                                        child: Padding(
                                          padding: const EdgeInsets.all(Gap.xs),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(color: ember.scrim, shape: BoxShape.circle),
                                            child: Padding(
                                              padding: const EdgeInsets.all(Gap.xs),
                                              child: Icon(Icons.delete_outline, size: 16, color: ember.onCodeSurface),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (_error != null) ...[
          Gap.vSm,
          InlineMessage(_error!, error: true),
        ],
        Gap.vMd,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
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
    );
  }
}

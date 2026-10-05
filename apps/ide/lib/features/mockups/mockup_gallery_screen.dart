import 'dart:async';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/locale.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../ai/ai_settings.dart';
import '../create/app_builder.dart';
import '../create/create_app_screen.dart';
import '../projects/projects_screen.dart';
import '../review/panel_health.dart';
import 'mockup_controller.dart';
import 'mockup_gallery_widgets.dart';
import 'name_picker.dart';

/// Full-screen gallery of 5 style mockups shown right after the user
/// describes the app (§1B step 3). Choosing one creates the project and
/// starts the build with that design.
class MockupGalleryScreen extends ConsumerStatefulWidget {
  const MockupGalleryScreen({super.key, required this.args});

  final CreateAppArgs args;

  @override
  ConsumerState<MockupGalleryScreen> createState() => _MockupGalleryScreenState();
}

class _MockupGalleryScreenState extends ConsumerState<MockupGalleryScreen> {
  MockupController? _c;
  final _pages = PageController();
  int _page = 0;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    if (!kIsWeb) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _c?.dispose();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final a = widget.args;
    final CompleteText complete;
    AiModel? model;
    // The drawing engine, not the coding one: mockups and names are graphics.
    if (a.designEngine == BuildEngine.claudeCode) {
      final socket = ref.read(runnerSocketProvider);
      complete = claudeCodeCompleter((t, p) => socket.request(t, p, timeout: const Duration(minutes: 6)));
    } else {
      final catalog = await ref.read(aiCatalogProvider.future);
      // Subscription CLIs have no one-shot mode: their mockups use Gemini (Runner key or the user's).
      final engine = a.designEngine.isCli ? BuildEngine.gemini : a.designEngine;
      model = catalog.where((m) => m.provider == engine.provider && m.id == engine.defaultModel).firstOrNull ??
          catalog.firstWhere((m) => m.provider == engine.provider);
      complete = apiCompleter(ref.read(aiProviderFactory), model);
    }
    // The configured reviewers draw the set together and then review each
    // other; with fewer than two of them the design engine works alone. Any
    // that are down are named to the user before a single mockup is drawn.
    if (!mounted) return;
    final health = await checkPanel(context, ref, forDrawing: true);
    if (!health.proceed) {
      // Stopping here goes back to the description; the app is not closed.
      if (mounted) context.pop();
      return;
    }
    final panel = health.members;
    final c = MockupController(
      description: '${a.prompt}${a.reference ?? ''}',
      engine: a.engine,
      model: model,
      // One model picked to draw: that one draws, not the default engine.
      complete: panel.length == 1 ? panel.first.complete : complete,
      styleBrief: a.styleBrief,
      panel: panel.length > 1 ? panel : const [],
      strings: ref.read(stringsProvider),
    );
    c.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() => _c = c);
    await c.generateSet();
  }

  void _newSet() {
    final c = _c;
    if (c == null || c.loading) return;
    c.generateSet();
    _jumpTo(0);
  }

  void _slide(int i) {
    // No slide when the system asks for reduced motion.
    final duration = Motion.of(context);
    if (_pages.hasClients && duration > Duration.zero) {
      _pages.animateToPage(i, duration: duration, curve: Motion.curve);
    } else {
      _jumpTo(i);
    }
  }

  void _jumpTo(int i) {
    setState(() => _page = i);
    if (_pages.hasClients) _pages.jumpToPage(i);
  }

  Future<void> _edit(Mockup m) async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final change = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (d) => OverPage(child: Padding(
        padding: EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, MediaQuery.of(d).viewInsets.bottom + Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.editMockup, style: d.text.titleMedium),
            Gap.vSm,
            TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(hintText: l.editMockupHint),
            ),
            Gap.vSm,
            FilledButton(onPressed: () => Navigator.pop(d, ctrl.text.trim()), child: Text(l.applyChange)),
          ],
        ),
      )),
    );
    ctrl.dispose();
    if (change != null && change.isNotEmpty) await _c?.edit(m, change);
  }

  /// The app's name, chosen before anything is built: it reaches the store
  /// listing, the privacy policy and the package name, which is final once
  /// Google has it.
  Future<String?> _askName() async {
    final complete = _c?.completeText;
    if (complete == null) return null;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (d) => OverPage(child: NamePickerSheet(
        load: () => suggestNames(complete, '${widget.args.prompt}${widget.args.reference ?? ''}'),
      )),
    );
  }

  Future<void> _choose(Mockup? m) async {
    if (_creating) return;
    final l = AppLocalizations.of(context);
    final appName = await _askName();
    if (!mounted) return;
    setState(() => _creating = true);
    try {
      final api = await ref.read(runnerApiProvider.future);
      final ws = await ref.read(workspaceProvider.future);
      final (project, job) = await api.createProject(ws.id, BuildSupport.projectNameFromPrompt(widget.args.prompt));
      ref.invalidate(projectsProvider);
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => OverPage(child: JobLogDialog(title: l.creatingProject(project.name), jobId: job.jobId)),
      );
      // The name is saved before the build: from here on the package name, the
      // privacy policy and the store listing all read it from the same place.
      if (ok == true && appName != null && appName.isNotEmpty) {
        await api.saveListing(project.id, {'title': appName}).catchError((_) {});
      }
      if (ok == true && mounted) {
        context.go(
          '/projects/${project.id}/create',
          extra: CreateAppArgs(
            prompt: widget.args.prompt,
            engine: widget.args.engine,
            modelKey: widget.args.modelKey,
            quality: widget.args.quality,
            design: (widget.args.reference ?? '') + (m?.designBrief() ?? ''),
            reference: widget.args.reference,
            referenceId: widget.args.referenceId,
            referenceTopics: widget.args.referenceTopics,
            styleBrief: widget.args.styleBrief,
            referenceSiteUrl: widget.args.referenceSiteUrl,
            designEngine: widget.args.designEngine,
            designName: m?.name,
            appName: appName,
          ),
        );
      }
    } on RunnerException catch (e) {
      if (mounted) showEmberSnack(context, l.error(e.message), error: true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _c;
    final mockups = c?.current ?? const <Mockup>[];
    final m = mockups.isEmpty ? null : mockups[_page.clamp(0, mockups.length - 1)];
    final readyCount = mockups.where((x) => x.status == MockupStatus.ready).length;
    final ember = context.ember;
    final material = MaterialLocalizations.of(context);
    // The start side goes back: the chevrons swap in right-to-left languages.
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: ember.codeSurface,
      body: Stack(
        children: [
          if (mockups.isEmpty)
            const LoadingState()
          else
            PageView.builder(
              controller: _pages,
              itemCount: mockups.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => MockupPage(mockup: mockups[i], onRetry: () => c!.retry(mockups[i])),
            ),
          // Previous / next arrows (a mouse cannot swipe the pages).
          if (mockups.length > 1) ...[
            if (_page > 0)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.all(Gap.sm),
                  child: OverPage(child: OverlayButton(
                    key: const Key('mockupPrev'),
                    tooltip: material.previousPageTooltip,
                    onPressed: () => _slide(_page - 1),
                    icon: rtl ? Icons.chevron_right : Icons.chevron_left,
                  )),
                ),
              ),
            if (_page < mockups.length - 1)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(Gap.sm),
                  child: OverPage(child: OverlayButton(
                    key: const Key('mockupNext'),
                    tooltip: material.nextPageTooltip,
                    onPressed: () => _slide(_page + 1),
                    icon: rtl ? Icons.chevron_left : Icons.chevron_right,
                  )),
                ),
              ),
          ],
          // Top bar: close, progress, page dots, previous sets.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.xs),
              child: OverPage(child: Row(
                children: [
                  OverlayButton(icon: Icons.close, tooltip: l.close, onPressed: () => context.pop()),
                  Gap.hSm,
                  Expanded(
                    // Eight dots with a full tap area each do not fit a narrow
                    // phone: they shrink together rather than overflow.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < mockups.length; i++)
                            Semantics(
                              button: true,
                              selected: i == _page,
                              label: '${i + 1} / ${mockups.length}',
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _jumpTo(i),
                                // The dot stays 8px; the area that answers a tap is 32x48.
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 20),
                                  child: AnimatedContainer(
                                    duration: Motion.of(context, Motion.fast),
                                    width: i == _page ? 22 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: mockups[i].status == MockupStatus.ready ? ember.onCodeSurface : ember.codeMuted,
                                      borderRadius: Radii.pillAll,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if ((c?.sets.length ?? 0) > 1)
                    PopupMenuButton<int>(
                      tooltip: l.previousMockups,
                      icon: Icon(Icons.history, color: ember.onCodeSurface),
                      onSelected: (i) {
                        c!.showSet(i);
                        _jumpTo(0);
                      },
                      itemBuilder: (_) => [
                        for (var i = 0; i < c!.sets.length; i++)
                          CheckedPopupMenuItem(value: i, checked: i == c.viewingSet, child: Text(l.mockupSet(i + 1))),
                      ],
                    ),
                  Gap.hXs,
                  Text('$readyCount/${mockups.length}', style: TextStyle(color: ember.onCodeSurface)),
                ],
              )),
            ),
          ),
          // Bottom panel: style info + actions.
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: OverPage(child: Container(
                margin: const EdgeInsets.all(Gap.sm),
                padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
                decoration: BoxDecoration(color: ember.codeSurface.withValues(alpha: 0.82), borderRadius: Radii.lgAll),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            m == null ? l.generatingMockups : (m.name.isEmpty ? mockupStyleLabel(l, m.style.id) : m.name),
                            style: TextStyle(color: ember.onCodeSurface, fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                        ),
                        // The mockup's own colours: data, not theme.
                        for (final hex in m?.palette.take(5) ?? const <String>[])
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsetsDirectional.only(start: Gap.xs),
                            decoration: BoxDecoration(
                              color: _hex(hex) ?? ember.codeMuted,
                              shape: BoxShape.circle,
                              border: Border.all(color: ember.onCodeSurface.withValues(alpha: 0.24)),
                            ),
                          ),
                      ],
                    ),
                    // Who drew it and what the other designers gave it: with
                    // eight proposals on the table, the panel's verdict is the
                    // fastest way to see which ones are worth opening.
                    if (m != null && m.authorLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: Gap.sm),
                        child: Wrap(
                          spacing: Gap.sm,
                          runSpacing: Gap.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Pill(m.authorLabel, icon: Icons.edit_outlined, onDark: true),
                            if (m.score != null) Pill('${m.score!.toStringAsFixed(1)}/10', icon: Icons.star_outline, onDark: true),
                            if (m.refined) Pill(l.mockupRefined, icon: Icons.check, onDark: true),
                          ],
                        ),
                      ),
                    if (m != null && m.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: Gap.xs),
                        child: Text(
                          l.mockupPanelNotes(m.notes.join(' · ')),
                          style: TextStyle(color: ember.codeMuted, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (c != null && c.panelStatus.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: Gap.sm),
                        child: DefaultTextStyle.merge(
                          style: TextStyle(color: ember.onCodeSurface, fontSize: 12),
                          child: BusyRow(c.panelStatus),
                        ),
                      ),
                    if (m != null && (m.tagline.isNotEmpty || m.font.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: Gap.xs),
                        child: Text(
                          [if (m.tagline.isNotEmpty) m.tagline, if (m.font.isNotEmpty) l.fontLabel(m.font)].join(' · '),
                          style: TextStyle(color: ember.onCodeSurface, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Gap.vMd,
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            key: const Key('chooseMockup'),
                            onPressed: m?.status == MockupStatus.ready && !_creating ? () => _choose(m) : null,
                            icon: _creating
                                ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.check),
                            label: Text(l.chooseMockup),
                          ),
                        ),
                        Gap.hSm,
                        IconButton.filledTonal(
                          tooltip: l.editMockup,
                          onPressed: m?.status == MockupStatus.ready ? () => _edit(m!) : null,
                          icon: const Icon(Icons.edit),
                        ),
                        Gap.hXs,
                        IconButton.filledTonal(
                          key: const Key('newMockups'),
                          tooltip: l.newMockups,
                          onPressed: c == null || c.loading ? null : _newSet,
                          icon: const Icon(Icons.autorenew),
                        ),
                      ],
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: ember.onCodeSurface, disabledForegroundColor: ember.codeMuted),
                      onPressed: _creating ? null : () => _choose(null),
                      child: Text(l.skipMockups),
                    ),
                  ],
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  /// Null when the mockup's colour cannot be read.
  static Color? _hex(String s) {
    final v = s.replaceAll('#', '');
    final n = int.tryParse(v.length == 6 ? 'FF$v' : v, radix: 16);
    return n == null ? null : Color(n);
  }
}

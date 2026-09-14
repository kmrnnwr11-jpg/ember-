import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../ai/ai_settings.dart';
import '../create/app_builder.dart';
import '../create/create_app_screen.dart';
import '../projects/projects_screen.dart';
import 'mockup_controller.dart';

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
    if (a.engine == BuildEngine.claudeCode) {
      final socket = ref.read(runnerSocketProvider);
      complete = claudeCodeCompleter((t, p) => socket.request(t, p, timeout: const Duration(minutes: 6)));
    } else {
      final catalog = await ref.read(aiCatalogProvider.future);
      // Subscription CLIs have no one-shot mode: their mockups use Gemini (Runner key or the user's).
      final engine = a.engine.isCli ? BuildEngine.gemini : a.engine;
      model = catalog.where((m) => m.key == a.modelKey).firstOrNull ??
          catalog.where((m) => m.provider == engine.provider && m.id == engine.defaultModel).firstOrNull ??
          catalog.firstWhere((m) => m.provider == engine.provider);
      complete = apiCompleter(ref.read(aiProviderFactory), model);
    }
    final c = MockupController(description: '${a.prompt}${a.reference ?? ''}', engine: a.engine, model: model, complete: complete);
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
    if (_pages.hasClients) {
      _pages.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
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
      builder: (d) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(d).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.editMockup, style: Theme.of(d).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(hintText: l.editMockupHint, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => Navigator.pop(d, ctrl.text.trim()), child: Text(l.applyChange)),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (change != null && change.isNotEmpty) await _c?.edit(m, change);
  }

  Future<void> _choose(Mockup? m) async {
    if (_creating) return;
    final l = AppLocalizations.of(context);
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
        builder: (_) => JobLogDialog(title: l.creatingProject(project.name), jobId: job.jobId),
      );
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
            designName: m?.name,
          ),
        );
      }
    } on RunnerException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.error(e.message))));
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (mockups.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            PageView.builder(
              controller: _pages,
              itemCount: mockups.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _MockupPage(mockup: mockups[i], onRetry: () => c!.retry(mockups[i])),
            ),
          // Previous / next arrows (a mouse cannot swipe the pages).
          if (mockups.length > 1) ...[
            if (_page > 0)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filled(
                    key: const Key('mockupPrev'),
                    style: IconButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, fixedSize: const Size(52, 52)),
                    tooltip: '$_page / ${mockups.length}',
                    onPressed: () => _slide(_page - 1),
                    icon: const Icon(Icons.chevron_left, size: 32),
                  ),
                ),
              ),
            if (_page < mockups.length - 1)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filled(
                    key: const Key('mockupNext'),
                    style: IconButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, fixedSize: const Size(52, 52)),
                    tooltip: '${_page + 2} / ${mockups.length}',
                    onPressed: () => _slide(_page + 1),
                    icon: const Icon(Icons.chevron_right, size: 32),
                  ),
                ),
              ),
          ],
          // Top bar: close, progress, page dots, previous sets.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _RoundButton(icon: Icons.close, onTap: () => context.pop()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < mockups.length; i++)
                          GestureDetector(
                            onTap: () => _jumpTo(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _page ? 22 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: mockups[i].status == MockupStatus.ready ? Colors.white : Colors.white38,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if ((c?.sets.length ?? 0) > 1)
                    PopupMenuButton<int>(
                      tooltip: l.previousMockups,
                      icon: const Icon(Icons.history, color: Colors.white),
                      onSelected: (i) {
                        c!.showSet(i);
                        _jumpTo(0);
                      },
                      itemBuilder: (_) => [
                        for (var i = 0; i < c!.sets.length; i++)
                          CheckedPopupMenuItem(value: i, checked: i == c.viewingSet, child: Text(l.mockupSet(i + 1))),
                      ],
                    ),
                  const SizedBox(width: 4),
                  Text('$readyCount/${mockups.length}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          // Bottom panel: style info + actions.
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.82), borderRadius: BorderRadius.circular(18)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            m == null ? l.generatingMockups : (m.name.isEmpty ? mockupStyleLabel(l, m.style.id) : m.name),
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                        ),
                        for (final hex in m?.palette.take(5) ?? const <String>[])
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(color: _hex(hex), shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                          ),
                      ],
                    ),
                    if (m != null && (m.tagline.isNotEmpty || m.font.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [if (m.tagline.isNotEmpty) m.tagline, if (m.font.isNotEmpty) l.fontLabel(m.font)].join(' · '),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 10),
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
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: l.editMockup,
                          onPressed: m?.status == MockupStatus.ready ? () => _edit(m!) : null,
                          icon: const Icon(Icons.edit),
                        ),
                        const SizedBox(width: 4),
                        IconButton.filledTonal(
                          key: const Key('newMockups'),
                          tooltip: l.newMockups,
                          onPressed: c == null || c.loading ? null : _newSet,
                          icon: const Icon(Icons.autorenew),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _creating ? null : () => _choose(null),
                      child: Text(l.skipMockups, style: const TextStyle(color: Colors.white60)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _hex(String s) {
    final v = s.replaceAll('#', '');
    final n = int.tryParse(v.length == 6 ? 'FF$v' : v, radix: 16);
    return n == null ? Colors.grey : Color(n);
  }
}

class _MockupPage extends StatelessWidget {
  const _MockupPage({required this.mockup, required this.onRetry});

  final Mockup mockup;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (mockup.status) {
      case MockupStatus.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l.designingStyle(mockupStyleLabel(l, mockup.style.id)), style: const TextStyle(color: Colors.white70)),
            ],
          ),
        );
      case MockupStatus.failed:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 40),
                const SizedBox(height: 8),
                Text(mockup.error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                FilledButton(onPressed: onRetry, child: Text(l.retry)),
              ],
            ),
          ),
        );
      case MockupStatus.ready:
        return InAppWebView(
          key: ValueKey(mockup.html.hashCode),
          initialData: InAppWebViewInitialData(data: mockup.html!, mimeType: 'text/html', encoding: 'utf8'),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: false,
            supportZoom: false,
            transparentBackground: false,
            verticalScrollBarEnabled: false,
          ),
          // Horizontal swipes go to the PageView; vertical scroll stays in the mockup.
          gestureRecognizers: const {},
        );
    }
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black54,
    shape: const CircleBorder(),
    child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white))),
  );
}

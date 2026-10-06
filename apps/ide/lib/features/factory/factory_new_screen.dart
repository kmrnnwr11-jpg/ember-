import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ide_core/ide_core.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'factory_controller.dart';
import 'factory_models.dart';
import 'factory_new_box.dart';
import 'factory_new_recipe.dart';
import 'factory_new_review.dart';

/// A new batch in three steps: say everything in the big box, choose how it is
/// made, then check the apps the supervisor proposes and start.
class FactoryNewScreen extends ConsumerStatefulWidget {
  const FactoryNewScreen({super.key});

  @override
  ConsumerState<FactoryNewScreen> createState() => _FactoryNewScreenState();
}

class _FactoryNewScreenState extends ConsumerState<FactoryNewScreen> {
  static const _maxFileBytes = 400 * 1024;
  static const _maxFiles = 12;

  int _step = 0;
  final _text = TextEditingController();
  final _theme = TextEditingController();
  final _name = TextEditingController();
  bool _invent = false;
  int _count = 20;
  final _files = <AttachedFile>[];

  BatchRecipe _recipe = const BatchRecipe();
  int? _dailyLimit;

  PlanResult? _plan;
  List<AppProposal> _proposals = const [];
  bool _planning = false;
  String? _planError;
  bool _starting = false;

  @override
  void dispose() {
    _text.dispose();
    _theme.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _hasInput => _invent ? _theme.text.trim().isNotEmpty : (_text.text.trim().isNotEmpty || _files.isNotEmpty);

  /// What the owner wrote or chose changed: the supervisor's answer is out of date.
  void _inputChanged() => setState(() {
    _plan = null;
    _proposals = const [];
    _planError = null;
  });

  Future<void> _attach() async {
    final l = AppLocalizations.of(context);
    final picked = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(label: l.fxFilesLabel, extensions: const ['txt', 'md', 'json', 'csv', 'yaml', 'yml', 'html']),
      ],
    );
    final added = <AttachedFile>[];
    var tooBig = false;
    for (final f in picked) {
      if (_files.length + added.length >= _maxFiles) break;
      if (await f.length() > _maxFileBytes) {
        tooBig = true;
        continue;
      }
      added.add((name: f.name, content: await f.readAsString()));
    }
    if (!mounted) return;
    if (tooBig) showEmberSnack(context, l.fxFileTooBig, error: true);
    if (added.isNotEmpty) {
      _files.addAll(added);
      _inputChanged();
    }
  }

  Future<void> _analyze() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _planning = true;
      _planError = null;
    });
    try {
      final api = await ref.read(runnerApiProvider.future);
      // Whatever the owner pasted and every file go to the supervisor as one text.
      final text = _invent
          ? _theme.text.trim()
          : [
              _text.text.trim(),
              for (final f in _files) '--- ${f.name} ---\n${f.content.trim()}',
            ].where((s) => s.isNotEmpty).join('\n\n');
      final json = await api.factoryPlan(text: text, count: _invent ? _count : null, engines: _recipe.engines);
      final plan = PlanResult.fromJson(json);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        // A batch holds at most 100 apps: the rest starts unticked.
        _proposals = [for (final (i, p) in plan.proposals.indexed) i < 100 ? p : p.copyWith(include: false)];
        if (_name.text.trim().isEmpty) _name.text = l.fxBatchDefaultName(_today());
      });
    } on RunnerException catch (e) {
      if (mounted) setState(() => _planError = e.message);
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  String _today() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  void _next() {
    if (_step == 1 && _plan == null && !_planning) _analyze();
    setState(() => _step++);
  }

  Future<void> _start(FactoryData data) async {
    final l = AppLocalizations.of(context);
    final chosen = [
      for (final p in _proposals)
        if (p.include) p,
    ];
    final limit = _dailyLimit ?? data.settings.dailyStoreCap;
    final stores = _recipe.goal == Goal.android || _recipe.goal == Goal.ios;
    final yes = await showConfirm(
      context,
      title: l.fxStartTitle(chosen.length),
      message: stores ? l.fxStartBodyStores(limit) : l.fxStartBody,
      confirmLabel: l.fxStart,
    );
    if (!yes || !mounted) return;
    setState(() => _starting = true);
    try {
      final ctl = ref.read(factoryProvider.notifier);
      if (limit != data.settings.dailyStoreCap) await ctl.setDailyCap(limit);
      await ctl.startBatch(name: _name.text.trim(), apps: chosen, recipe: _recipe);
      if (!mounted) return;
      showEmberSnack(context, l.fxStarted(chosen.length));
      context.go('/factory');
    } on RunnerException catch (e) {
      if (mounted) showEmberSnack(context, l.error(e.message), error: true);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(factoryProvider).value;
    final chosen = _proposals.where((p) => p.include).length;
    final canNext = switch (_step) {
      0 => _hasInput,
      _ => true,
    };
    final canStart = !_planning && !_starting && chosen > 0 && _name.text.trim().isNotEmpty && data != null;

    // The way on stays under the page, always in reach, however long the page is.
    return Column(
      children: [
        Expanded(
          child: PageBody(
            children: [
              StepHeader(current: _step, labels: [l.fxStepIdeas, l.fxStepRecipe, l.fxStepReview]),
              Gap.vLg,
              if (_step == 0)
                FactoryBoxStep(
                  text: _text,
                  theme: _theme,
                  invent: _invent,
                  count: _count,
                  files: _files,
                  onInvent: (v) {
                    _invent = v;
                    _inputChanged();
                  },
                  onCount: (v) {
                    _count = v;
                    _inputChanged();
                  },
                  onChanged: _inputChanged,
                  onAttach: _attach,
                  onRemoveFile: (f) {
                    _files.remove(f);
                    _inputChanged();
                  },
                )
              else if (_step == 1)
                FactoryRecipeStep(
                  recipe: _recipe,
                  connections: ref.watch(factoryConnectionsProvider).value,
                  dailyLimit: _dailyLimit ?? data?.settings.dailyStoreCap ?? 10,
                  onRecipe: (r) => setState(() => _recipe = r),
                  onDailyLimit: (v) => setState(() => _dailyLimit = v),
                )
              else
                FactoryReviewStep(
                  planning: _planning,
                  error: _planError,
                  plan: _plan,
                  proposals: _proposals,
                  name: _name,
                  goal: _recipe.goal,
                  dailyLimit: _dailyLimit ?? data?.settings.dailyStoreCap ?? 10,
                  onRetry: _analyze,
                  onChanged: (list) => setState(() => _proposals = list),
                  onNameChanged: () => setState(() {}),
                ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.scheme.outlineVariant)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Widths.page),
              child: Padding(
                padding: const EdgeInsets.all(Gap.md),
                child: Row(
                  children: [
                    if (_step > 0)
                      OutlinedButton(
                        key: const Key('factoryBack'),
                        onPressed: _starting ? null : () => setState(() => _step--),
                        child: Text(l.fxBack),
                      ),
                    const Spacer(),
                    if (_step < 2)
                      FilledButton(
                        key: const Key('factoryNext'),
                        onPressed: canNext ? _next : null,
                        child: Text(l.fxContinue),
                      )
                    else
                      FilledButton.icon(
                        key: const Key('factoryStart'),
                        onPressed: canStart ? () => _start(data) : null,
                        icon: const Icon(Icons.rocket_launch_outlined),
                        label: Text(chosen > 0 ? l.fxStartCount(chosen) : l.fxStart),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

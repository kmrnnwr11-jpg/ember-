import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/session.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/ui.dart';
import '../app_builder.dart';
import '../forge_view.dart';

/// What was asked for, and who is building it.
class PromptCard extends StatelessWidget {
  const PromptCard({super.key, required this.prompt, required this.engine, required this.model, this.designName, this.quality = 'fast'});
  final String prompt;
  final String quality;
  final BuildEngine? engine;
  final AiModel? model;
  final String? designName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final who = engine != null && engine!.isCli ? engine!.cliLabel : (model?.label ?? '');
    final cliModel = engine != null && engine!.isCli && quality != 'fast' && quality != 'best' ? quality : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prompt, maxLines: 4, overflow: TextOverflow.ellipsis),
            Gap.vSm,
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.xs,
              children: [
                if (who.isNotEmpty) Pill(cliModel == null ? who : '$who · $cliModel', icon: Icons.memory_outlined),
                if (designName != null) Pill(l.designChosen(designName!), icon: Icons.palette_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The build in progress: what is happening now and what comes next.
class BuildProgress extends StatelessWidget {
  const BuildProgress({super.key, required this.builder});
  final AppBuilder builder;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final b = builder;
    const order = [BuildPhase.generating, BuildPhase.dependencies, BuildPhase.checking, BuildPhase.building, BuildPhase.ready];
    final labels = {
      BuildPhase.generating: b.engine?.isCli == true
          ? [
              '${b.engine == BuildEngine.claudeCode ? l.stepClaudeCode : b.engine!.cliLabel} (${b.writtenFiles.length} file)',
              if (b.currentAction != null) b.currentAction!,
            ].join('\n')
          : l.stepWriting(b.writtenFiles.length),
      BuildPhase.dependencies: l.stepDependencies,
      BuildPhase.checking: b.fixRound > 0 ? l.stepFixing(b.fixRound) : l.stepChecking,
      BuildPhase.building: l.stepBuilding,
      BuildPhase.ready: l.stepReady,
    };
    final current = b.phase == BuildPhase.fixing ? BuildPhase.checking : b.phase;
    final currentIndex = order.indexOf(current);
    return ForgeView(
      builder: b,
      status: labels[current] ?? '',
      steps: [
        for (var i = 0; i < order.length; i++) (label: labels[order[i]]!, done: i < currentIndex, current: i == currentIndex),
      ],
    );
  }
}

/// The app is built: one thing to do next, which is to open it.
class ReadyHero extends ConsumerWidget {
  const ReadyHero({super.key, required this.builder, required this.projectId});
  final AppBuilder builder;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider).value;
    final url = session == null ? null : builder.preview?.resolve(session.runnerUrl);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: context.ember.success, size: 28),
                Gap.hMd,
                Expanded(child: Text(l.appReadyTitle, style: context.text.titleLarge)),
              ],
            ),
            Gap.vLg,
            FilledButton.icon(
              key: const Key('openPreview'),
              onPressed: () => url == null ? context.go('/projects/$projectId?panel=preview') : context.push(Uri(path: '/run', queryParameters: {'url': url}).toString()),
              icon: const Icon(Icons.play_arrow_outlined),
              label: Text(l.openApp),
            ),
          ],
        ),
      ),
    );
  }
}

/// The built app in the browser, outside Ember.
class OpenInBrowserCard extends ConsumerWidget {
  const OpenInBrowserCard({super.key, required this.builder});
  final AppBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider).value;
    final url = session == null ? null : builder.preview?.resolve(session.runnerUrl);
    if (url == null) return const SizedBox.shrink();
    return SectionCard(
      icon: Icons.public,
      title: l.openInBrowser,
      children: [
        Gap.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const Key('openInBrowser'),
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l.openInBrowser),
          ),
        ),
      ],
    );
  }
}

/// The build stopped: say why, and offer to carry on or start again.
class FailedCard extends StatelessWidget {
  const FailedCard({super.key, required this.builder, required this.projectId});
  final AppBuilder builder;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      icon: Icons.error_outline,
      title: builder.phase == BuildPhase.cancelled ? l.buildCancelled : l.buildFailedTitle,
      tone: Tone.error,
      margin: EdgeInsets.zero,
      children: [
        if (builder.error != null) ...[
          Gap.vSm,
          SelectableText(builder.error!, maxLines: 12, style: TextStyle(color: context.scheme.onErrorContainer)),
        ],
        Gap.vMd,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            // With files already on disk the first button continues the
            // work; starting over stays available, but as the second
            // choice, because it costs another full build.
            if (builder.canResume)
              FilledButton.icon(
                key: const Key('resumeBuild'),
                onPressed: builder.resumeFailed,
                icon: const Icon(Icons.play_arrow_outlined),
                label: Text(l.resumeFromHere(builder.writtenFiles.length)),
              ),
            (builder.canResume ? OutlinedButton.icon : FilledButton.icon)(
              key: const Key('retryBuild'),
              onPressed: () => builder.build(prompt: builder.prompt, engine: builder.engine!, model: builder.model, quality: builder.quality, design: builder.design, designName: builder.designName),
              icon: const Icon(Icons.refresh),
              label: Text(builder.canResume ? l.startOver : l.retry),
            ),
            TextButton(onPressed: () => context.go('/projects/$projectId'), child: Text(l.openEditor)),
          ],
        ),
      ],
    );
  }
}

/// One place to go next from the app screen.
class NextStep {
  const NextStep({required this.key, required this.icon, required this.title, required this.hint, required this.onTap, this.status});
  final String key;
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  /// A short state shown at the end of the row (e.g. "3 to fix").
  final Widget? status;
}

/// Everything else you can do with a finished app, one row each.
class NextSteps extends StatelessWidget {
  const NextSteps({super.key, required this.steps});
  final List<NextStep> steps;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: Gap.xs, bottom: Gap.sm),
          child: Text(l.hubNextSteps, style: context.text.titleMedium),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, s) in steps.indexed) ...[
                if (i > 0) const Divider(),
                ListTile(
                  key: Key('step_${s.key}'),
                  leading: Icon(s.icon),
                  title: Text(s.title),
                  subtitle: Text(s.hint),
                  shape: const RoundedRectangleBorder(),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (s.status != null) ...[s.status!, Gap.hSm],
                      Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
                    ],
                  ),
                  onTap: s.onTap,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A message of the conversation with Ember; Ember's replies are Markdown.
class AppChatBubble extends StatelessWidget {
  const AppChatBubble({super.key, required this.role, required this.text});
  final String role;
  final String text;

  @override
  Widget build(BuildContext context) {
    final user = role == 'user';
    return ChatBubble(
      isUser: user,
      child: user
          ? SelectableText(text)
          : MarkdownBody(
              data: text,
              selectable: true,
              onTapLink: (_, href, _) {
                if (href != null) launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
              },
            ),
    );
  }
}

/// The raw build log, for whoever wants to see what happened underneath.
class BuildLogView extends StatelessWidget {
  const BuildLogView({super.key, required this.builder, required this.scroll});
  final AppBuilder builder;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final b = builder;
    final ember = context.ember;
    final generating = b.phase == BuildPhase.generating || b.phase == BuildPhase.fixing;
    final live = b.liveText.toString();
    final tail = live.length > 1500 ? live.substring(live.length - 1500) : live;
    return LogSurface(
      height: 280,
      child: ListView(
        controller: scroll,
        reverse: true,
        children: [
          if (generating && tail.isNotEmpty && b.engine?.isCli != true) Text(tail, style: TextStyle(fontSize: 11, color: ember.codeMuted)),
          for (final line in b.log.reversed.take(300))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2, end: Gap.sm),
                    child: Icon(
                      switch (line.kind) {
                        'file' => Icons.description_outlined,
                        'tool' => Icons.settings_outlined,
                        'error' => Icons.warning_amber_outlined,
                        'ai' => Icons.chat_bubble_outline,
                        _ => Icons.circle_outlined,
                      },
                      size: 12,
                      color: line.kind == 'error' ? ember.warning : null,
                    ),
                  ),
                  Expanded(child: Text(line.text, style: TextStyle(color: line.kind == 'error' ? ember.warning : null))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'theme.dart';
import 'tokens.dart';

/// How a card or a pill is tinted.
enum Tone { neutral, attention, error, success }

/// A titled card: icon, title, one line of help, then the content.
/// Every feature card in the app is one of these.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.icon,
    required this.title,
    this.hint,
    this.trailing,
    this.tone = Tone.neutral,
    this.margin = const EdgeInsets.only(top: Gap.md),
    this.children = const [],
  });

  final IconData? icon;
  final String title;
  final String? hint;

  /// Small control at the end of the title row (refresh, toggle).
  final Widget? trailing;
  final Tone tone;
  final EdgeInsetsGeometry margin;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final (Color? background, Color? foreground) = switch (tone) {
      Tone.error => (scheme.errorContainer, scheme.onErrorContainer),
      Tone.attention => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      Tone.success => (scheme.primaryContainer, scheme.onPrimaryContainer),
      Tone.neutral => (null, null),
    };
    return Card(
      margin: margin,
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[Icon(icon, color: foreground), Gap.hSm],
                Expanded(child: Text(title, style: context.text.titleMedium?.copyWith(color: foreground))),
                ?trailing,
              ],
            ),
            if (hint != null && hint!.isNotEmpty) ...[
              Gap.vXs,
              Text(hint!, style: context.text.bodySmall?.copyWith(color: foreground?.withValues(alpha: 0.85))),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

/// "Working on it": a small spinner and one line of text.
class BusyRow extends StatelessWidget {
  const BusyRow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      children: [
        const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        Gap.hSm,
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// The result of an action, shown where the action was started.
class InlineMessage extends StatelessWidget {
  const InlineMessage(this.text, {super.key, this.error = false});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: SelectableText(text, style: TextStyle(color: error ? context.scheme.error : null)),
  );
}

/// One line of a checklist: done or not yet.
class StatusRow extends StatelessWidget {
  const StatusRow({super.key, required this.done, required this.text, this.trailing});
  final bool done;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(
          done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 18,
          color: done ? context.ember.success : context.scheme.onSurfaceVariant,
          semanticLabel: done ? AppLocalizations.of(context).done : null,
        ),
        Gap.hSm,
        Expanded(child: Text(text)),
        ?trailing,
      ],
    ),
  );
}

/// Something a check found: what it is, why it matters, and what to do about it.
class FindingTile extends StatelessWidget {
  const FindingTile({super.key, required this.title, this.detail, this.fixable = false, this.action});
  final String title;
  final String? detail;
  final bool fixable;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(fixable ? Icons.build_circle_outlined : Icons.info_outline, size: 18),
      Gap.hSm,
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.titleSmall),
            if (detail != null && detail!.isNotEmpty) Text(detail!, style: context.text.bodySmall),
            ?action,
          ],
        ),
      ),
    ],
  );
}

/// A small label: a status, a count, a tag.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.icon, this.tone = Tone.neutral, this.onDark = false});
  final String label;
  final IconData? icon;
  final Tone tone;

  /// Drawn over a preview or another always-dark surface.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final ember = context.ember;
    final Color color = switch (tone) {
      Tone.success => ember.success,
      Tone.attention => ember.warning,
      Tone.error => scheme.error,
      Tone.neutral => onDark ? ember.onCodeSurface : scheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.pillAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), Gap.hXs],
          Flexible(child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// A numbered guide: one short step per line instead of a wall of text.
class StepsList extends StatelessWidget {
  const StepsList(this.steps, {super.key});
  final List<String> steps;

  /// Splits "1. … 2. …" or one-step-per-line text into steps.
  factory StepsList.parse(String text, {Key? key}) {
    final lines = text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty);
    return StepsList([for (final line in lines) line.replaceFirst(RegExp(r'^\d+[.)]\s*'), '')], key: key);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, step) in steps.indexed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Gap.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: context.scheme.primaryContainer, shape: BoxShape.circle),
                child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.scheme.onPrimaryContainer)),
              ),
              Gap.hSm,
              Expanded(child: Text(step)),
            ],
          ),
        ),
    ],
  );
}

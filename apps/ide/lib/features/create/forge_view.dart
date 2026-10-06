import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../../widgets/ember_logo.dart';
import 'app_builder.dart';
import 'creation_steps.dart';

/// One line of the build checklist.
typedef ForgeStep = ({String label, bool done, bool current});

/// What the user sees while an app is being built: what Ember is doing now,
/// how far it has got, roughly how long is left, and a way to stop.
class ForgeView extends StatefulWidget {
  const ForgeView({super.key, required this.builder, required this.status, this.steps = const []});
  final AppBuilder builder;

  /// The step in progress, in words.
  final String status;
  final List<ForgeStep> steps;

  @override
  State<ForgeView> createState() => _ForgeViewState();
}

class _ForgeViewState extends State<ForgeView> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // The elapsed time moves on its own; everything else follows the builder.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  /// "3 of 12 files" pace when the plan is known, otherwise a typical duration for the engine.
  String _timeLine(AppLocalizations l, AppBuilder b) {
    final started = b.startedAt;
    if (started == null) return '';
    final elapsed = DateTime.now().difference(started);
    final clock = '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    final planned = b.expectedFiles;
    final written = b.writtenFiles.length;
    int minutesLeft;
    if (planned != null && planned > 0 && written > 0) {
      final perFile = elapsed.inSeconds / written;
      // Remaining files plus checks and the web build (~1.5 min).
      minutesLeft = ((perFile * math.max(planned - written, 0) + 90) / 60).ceil();
      return '${l.forgeEta(math.max(minutesLeft, 1))} · ${l.forgeElapsed(clock)}';
    }
    final typical = b.engine?.isCli == true ? (RegExp('best|opus|fable|pro|terra').hasMatch(b.quality) ? 15 : 8) : 4;
    minutesLeft = math.max(typical - elapsed.inMinutes, 1);
    return '${l.forgeEstimated(minutesLeft)} · ${l.forgeElapsed(clock)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final b = widget.builder;
    final planned = b.expectedFiles;
    final written = b.writtenFiles.length;
    final known = planned != null && planned > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The first build is the last step of making an app; later changes are not.
            if (b.conversation.length <= 1) ...[const CreationSteps(current: 3), Gap.vXl],
            Row(
              children: [
                const ExcludeSemantics(child: EmberMark(size: 48)),
                Gap.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.forgeTitle, style: context.text.titleLarge),
                      Gap.vXs,
                      Semantics(
                        liveRegion: true,
                        child: Text(widget.status, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Gap.vLg,
            ClipRRect(
              borderRadius: Radii.pillAll,
              child: LinearProgressIndicator(
                minHeight: 6,
                // Known plan: how many files are written. Otherwise just "working".
                value: known && written > 0 ? (written / math.max(planned, written)).clamp(0.02, 0.95) : null,
              ),
            ),
            Gap.vSm,
            // Side by side when there is room; the time goes under the files on a phone.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Gap.md,
              runSpacing: Gap.xs,
              children: [
                Text(
                  known ? l.forgeFilesOf(written, math.max(planned, written)) : l.forgeFiles(written),
                  style: context.text.bodySmall,
                ),
                Text(_timeLine(l, b), style: context.text.bodySmall),
              ],
            ),
            if (widget.steps.isNotEmpty) ...[
              Gap.vLg,
              for (final step in widget.steps)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                  child: Row(
                    children: [
                      if (step.current)
                        const SizedBox.square(dimension: 18, child: Padding(padding: EdgeInsets.all(1), child: CircularProgressIndicator(strokeWidth: 2)))
                      else
                        Icon(
                          step.done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                          size: 18,
                          color: step.done ? context.ember.success : context.scheme.outline,
                        ),
                      Gap.hMd,
                      Expanded(
                        child: Text(
                          step.label.split('\n').first,
                          style: TextStyle(
                            color: step.done || step.current ? null : context.scheme.onSurfaceVariant,
                            fontWeight: step.current ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            Gap.vLg,
            Text(l.forgeBackground, style: context.text.bodySmall),
            Gap.vMd,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(key: const Key('stopBuild'), onPressed: b.cancel, icon: const Icon(Icons.stop_outlined, size: 18), label: Text(l.stop)),
            ),
          ],
        ),
      ),
    );
  }
}

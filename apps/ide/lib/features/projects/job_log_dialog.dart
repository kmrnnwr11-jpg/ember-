import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';

/// Follows a job on the Runner: a line saying it is working, and the raw log
/// for whoever wants it. Pops `true` on success, `false` on failure.
class JobLogDialog extends ConsumerStatefulWidget {
  const JobLogDialog({super.key, required this.title, required this.jobId});

  final String title;
  final String jobId;

  @override
  ConsumerState<JobLogDialog> createState() => _JobLogDialogState();
}

class _JobLogDialogState extends ConsumerState<JobLogDialog> {
  final _log = StringBuffer();
  final _scroll = ScrollController();
  final _subs = <StreamSubscription<WsFrame>>[];
  JobStatus? _status;
  bool _showLog = false;

  @override
  void initState() {
    super.initState();
    final socket = ref.read(runnerSocketProvider);
    _subs
      ..add(socket.eventsOf(MsgType.jobLog).where((f) => f.payload['jobId'] == widget.jobId).listen((f) {
        setState(() => _log.write(f.payload['chunk'] as String? ?? ''));
        _scrollToEnd();
      }))
      ..add(socket.eventsOf(MsgType.jobStatus).where((f) => f.payload['jobId'] == widget.jobId).listen((f) {
        final status = JobStatus.fromJson(f.payload);
        setState(() {
          _status = status;
          // A failure is explained by the log: open it.
          if (status.isDone && status.status != 'succeeded') _showLog = true;
        });
      }));
    // Replay what was logged before we subscribed.
    ref.read(runnerApiProvider.future).then((api) => api.jobLog(widget.jobId)).then((prior) {
      if (!mounted || _log.isNotEmpty) return;
      setState(() => _log.write(prior));
      _scrollToEnd();
    }, onError: (_) {});
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  });

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final done = _status?.isDone ?? false;
    final ok = _status?.status == 'succeeded';
    return AlertDialog(
      title: Row(
        children: [
          if (!done) const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          if (done) Icon(ok ? Icons.check_circle_outline : Icons.error_outline, color: ok ? context.ember.success : context.scheme.error),
          Gap.hMd,
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!done) const LinearProgressIndicator(),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('jobLogDetails'),
                  onPressed: () {
                    setState(() => _showLog = !_showLog);
                    _scrollToEnd();
                  },
                  icon: Icon(_showLog ? Icons.expand_less : Icons.expand_more, size: 18),
                  label: Text(l.details),
                ),
              ),
              AnimatedSize(
                duration: Motion.of(context),
                curve: Motion.curve,
                alignment: Alignment.topCenter,
                child: !_showLog
                    ? const SizedBox(width: double.infinity)
                    : LogSurface(
                        height: 240,
                        child: SingleChildScrollView(controller: _scroll, child: SelectableText(_log.toString())),
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (done) FilledButton(onPressed: () => Navigator.pop(context, ok), child: Text(ok ? l.statusReady : l.cancel)),
      ],
    );
  }
}

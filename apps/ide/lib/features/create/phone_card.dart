import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import 'app_builder.dart';

/// Puts the app on a phone plugged into this computer, and opens it there.
///
/// The preview cannot show what matters most: Google sign-in, notifications,
/// ads, and how the app really feels in a hand. This card appears only when a
/// phone is actually connected, so it is never a dead button.
class PhoneCard extends ConsumerStatefulWidget {
  const PhoneCard({super.key, required this.projectId, required this.builder});
  final String projectId;
  final AppBuilder builder;

  @override
  ConsumerState<PhoneCard> createState() => _PhoneCardState();
}

class _PhoneCardState extends ConsumerState<PhoneCard> {
  List<Map<String, dynamic>> _devices = const [];
  bool _busy = false;
  String? _message;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _look();
  }

  Future<void> _look() async {
    try {
      final found = await (await ref.read(runnerApiProvider.future)).devices();
      if (mounted) setState(() => _devices = found);
    } catch (_) {
      // No phone, no card: a failed look is simply nothing to show.
    }
  }

  Future<void> _send(String deviceId) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
      _error = false;
    });
    try {
      // The phone needs the APK, so build it first when it is not there yet.
      if (widget.builder.androidKind != 'apk' || widget.builder.androidStatus != 'ready') {
        setState(() => _message = l.phoneBuilding);
        await widget.builder.buildAndroid('apk');
        if (widget.builder.androidStatus != 'ready') throw RunnerException('build_failed', widget.builder.androidError ?? l.androidFailed);
      }
      setState(() => _message = l.phoneInstalling);
      final res = await (await ref.read(runnerApiProvider.future)).runOnDevice(widget.projectId, deviceId: deviceId);
      setState(() {
        _message = '${res['message']}';
        _error = false;
      });
    } on RunnerException catch (e) {
      setState(() {
        _message = e.message;
        _error = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (_devices.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.smartphone),
                const SizedBox(width: 8),
                Expanded(child: Text(l.phoneTitle, style: theme.textTheme.titleMedium)),
                IconButton(tooltip: l.phoneLookAgain, icon: const Icon(Icons.refresh, size: 20), onPressed: _busy ? null : _look),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.phoneHint, style: theme.textTheme.bodySmall),
            if (_busy) ...[
              const SizedBox(height: 10),
              Row(children: [const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Expanded(child: Text(_message ?? ''))]),
            ] else if (_message != null) ...[
              const SizedBox(height: 10),
              SelectableText(_message!, style: TextStyle(color: _error ? theme.colorScheme.error : null)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _devices)
                  if (d['state'] == 'device')
                    FilledButton.icon(
                      onPressed: _busy || widget.builder.running ? null : () => _send('${d['id']}'),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l.phoneRunOn('${d['name']}')),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _look,
                      icon: const Icon(Icons.lock_outline),
                      label: Text(l.phoneUnauthorized('${d['name']}')),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

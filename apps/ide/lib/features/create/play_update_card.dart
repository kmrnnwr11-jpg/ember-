import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../store/play_publish_screen.dart' show uploadSummary;
import 'app_builder.dart';

/// Finished app: what is saved for Google Play and one tap to ship a new version.
class PlayUpdateCard extends ConsumerStatefulWidget {
  const PlayUpdateCard({super.key, required this.builder, required this.projectId});
  final AppBuilder builder;
  final String projectId;

  @override
  ConsumerState<PlayUpdateCard> createState() => _PlayUpdateCardState();
}

class _PlayUpdateCardState extends ConsumerState<PlayUpdateCard> {
  static const _saKey = 'play_service_account';
  Map<String, dynamic>? _state;
  bool _connected = false;
  String? _busy;
  String? _message;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final s = await (await ref.read(runnerApiProvider.future)).storeState(widget.projectId);
      final sa = await ref.read(keyValueStoreProvider).read(_saKey);
      if (mounted) {
        setState(() {
          _state = s;
          _connected = sa != null && sa.contains('private_key');
        });
      }
    } catch (_) {}
  }

  Future<void> _newVersion() async {
    final l = AppLocalizations.of(context);
    final sa = await ref.read(keyValueStoreProvider).read(_saKey);
    final listing = _state?['listing'] as Map<String, dynamic>?;
    if (!mounted) return;
    // Say exactly what is missing instead of a generic "connect first".
    if (sa == null || !sa.contains('private_key')) {
      setState(() {
        _message = l.upNeedsKey;
        _error = true;
      });
      return;
    }
    if (listing == null || '${listing['title'] ?? ''}'.isEmpty) {
      setState(() {
        _message = l.upNeedsListing;
        _error = true;
      });
      return;
    }
    setState(() {
      _busy = l.upBuilding;
      _message = null;
      _error = false;
    });
    try {
      await widget.builder.buildAndroid('aab');
      if (widget.builder.androidStatus != 'ready') throw RunnerException('build_failed', widget.builder.androidError ?? l.androidFailed);
      setState(() => _busy = l.upUploading);
      final api = await ref.read(runnerApiProvider.future);
      final result = await api.publishToPlay(widget.projectId, {
        'serviceAccount': sa,
        'track': 'internal',
        'status': 'completed',
        'listing': {
          'language': 'it-IT',
          'title': listing['title'],
          if ('${listing['shortDescription'] ?? ''}'.isNotEmpty) 'shortDescription': listing['shortDescription'],
          if ('${listing['fullDescription'] ?? ''}'.isNotEmpty) 'fullDescription': listing['fullDescription'],
        },
        if ('${listing['releaseNotes'] ?? ''}'.isNotEmpty) 'releaseNotes': {'language': 'it-IT', 'text': listing['releaseNotes']},
        if ('${listing['contactEmail'] ?? ''}'.contains('@')) 'contactEmail': listing['contactEmail'],
      });
      setState(() {
        _message = '${l.playUploaded('${result['versionCode']}', '${result['track']}', result['downgradedToDraft'] == true ? l.playDraftNote : '')}\n${uploadSummary(l, result)}';
        _error = false;
      });
    } on RunnerException catch (e) {
      setState(() {
        _message = e.message;
        _error = true;
      });
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _dataSafety() async {
    final l = AppLocalizations.of(context);
    final sa = await ref.read(keyValueStoreProvider).read(_saKey);
    if (!mounted) return;
    if (sa == null || !sa.contains('private_key')) {
      setState(() {
        _message = l.upNeedsKey;
        _error = true;
      });
      return;
    }
    setState(() {
      _busy = l.dsWorking;
      _message = null;
      _error = false;
    });
    try {
      await (await ref.read(runnerApiProvider.future)).fillDataSafety(widget.projectId, sa);
      setState(() {
        _message = l.dsDone;
        _error = false;
      });
    } on RunnerException catch (e) {
      setState(() {
        _message = e.code == 'needs_csv' ? l.dsNeedsCsv : e.message;
        _error = true;
      });
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _row(bool ok, String text) => Row(
    children: [
      Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: ok ? Colors.greenAccent : Theme.of(context).disabledColor),
      const SizedBox(width: 8),
      Expanded(child: Text(text)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = _state;
    final shots = (s?['screenshots'] as List?)?.length ?? 0;
    final listing = s?['listing'] as Map<String, dynamic>?;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [const Icon(Icons.shop_outlined), const SizedBox(width: 8), Text(l.upTitle, style: theme.textTheme.titleMedium)]),
            const SizedBox(height: 4),
            Text(l.upHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            _row(_connected, l.upStateConnected),
            _row(s?['appliedLogo'] != null, l.upStateLogo),
            _row(shots >= 2, l.upStateShots(shots)),
            _row(listing != null && '${listing['title'] ?? ''}'.isNotEmpty, listing == null ? l.upStateListing : '${l.upStateListing}: ${listing['title']}'),
            if (_busy != null) ...[
              const SizedBox(height: 10),
              Row(children: [const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Expanded(child: Text(_busy!))]),
            ],
            if (_message != null) ...[
              const SizedBox(height: 10),
              SelectableText(_message!, style: TextStyle(color: _error ? theme.colorScheme.error : null)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy != null || widget.builder.running ? null : _newVersion,
                  icon: const Icon(Icons.upload),
                  label: Text(l.upNewVersion),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.push('/projects/${widget.projectId}/play/details', extra: widget.builder.prompt);
                    _refresh();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l.upEditListing),
                ),
                OutlinedButton.icon(
                  onPressed: _busy != null ? null : _dataSafety,
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: Text(l.dsButton),
                ),
                TextButton(
                  onPressed: () async {
                    await context.push('/projects/${widget.projectId}/play', extra: widget.builder.prompt);
                    _refresh();
                  },
                  child: Text(_connected ? l.upOpenGuide : l.upConnectPlay),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

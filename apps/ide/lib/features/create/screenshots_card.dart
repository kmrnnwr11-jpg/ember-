import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import 'app_builder.dart';

/// Asks the AI to add the screenshot mode to apps built before it existed.
const screenshotUpgradeRequest =
    "Add a screenshot mode to this app for the Play Store screenshots. On web, when the URL has the query parameter ember_screen=N (N = 0..5), open directly the app's N-th most representative screen (home, main feature, detail, list, profile/settings, premium…), filled with realistic demo content, skipping splash, login, onboarding and \"configuration needed\" screens, without dialogs or debug banners. Read it with Uri.base.queryParameters['ember_screen'] and keep the screen list in lib/config/screenshot_screens.dart. Normal launches are unchanged. Do not change anything else.";

/// Six phone screenshots for the Play Store, taken automatically from the app.
class ScreenshotsCard extends ConsumerStatefulWidget {
  const ScreenshotsCard({super.key, required this.builder, required this.projectId});
  final AppBuilder builder;
  final String projectId;

  @override
  ConsumerState<ScreenshotsCard> createState() => _ScreenshotsCardState();
}

class _ScreenshotsCardState extends ConsumerState<ScreenshotsCard> {
  final _shots = <Uint8List>[];
  bool _busy = false;

  /// The app is being upgraded with the screenshot mode; take the shots when it is ready.
  bool _waitingUpgrade = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.builder.addListener(_onBuilder);
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final s = await (await ref.read(runnerApiProvider.future)).storeState(widget.projectId);
      final shots = (s['screenshots'] as List).cast<String>();
      if (mounted && _shots.isEmpty) setState(() => _shots.addAll(shots.map(base64Decode)));
    } catch (_) {}
  }

  @override
  void dispose() {
    widget.builder.removeListener(_onBuilder);
    super.dispose();
  }

  void _onBuilder() {
    if (!_waitingUpgrade || widget.builder.running) return;
    _waitingUpgrade = false;
    if (widget.builder.phase == BuildPhase.ready) _take();
  }

  Future<void> _take() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = await ref.read(runnerApiProvider.future);
      final res = await api.takeScreenshots(widget.projectId);
      final list = (res['shots'] as List).cast<Map<String, dynamic>>();
      setState(() => _shots
        ..clear()
        ..addAll(list.map((s) => base64Decode(s['thumb'] as String))));
    } on RunnerException catch (e) {
      if (e.code == 'needs_screenshot_mode') {
        setState(() => _waitingUpgrade = true);
        widget.builder.improve(screenshotUpgradeRequest, display: l.shotsPreparingChat);
      } else {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final working = _busy || _waitingUpgrade;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_android),
                const SizedBox(width: 8),
                Expanded(child: Text(l.shotsTitle, style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 4),
            Text(_waitingUpgrade ? l.shotsPreparing : l.shotsHint, style: theme.textTheme.bodySmall),
            if (_shots.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _shots.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_shots[i], fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 6),
              Text(l.shotsSaved(_shots.length), style: theme.textTheme.bodySmall),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                key: const Key('takeScreenshots'),
                onPressed: working || widget.builder.running ? null : _take,
                icon: working ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_camera_outlined),
                label: Text(_shots.isEmpty ? l.shotsGenerate : l.shotsAgain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

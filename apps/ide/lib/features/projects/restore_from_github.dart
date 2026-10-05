import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show Project, RunnerException;

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';

/// The apps saved on GitHub, ready to come back onto this computer.
/// This is how the same apps are opened from Windows and from a Mac.
class RestoreFromGitHubDialog extends ConsumerStatefulWidget {
  const RestoreFromGitHubDialog({super.key, required this.workspaceId, required this.alreadyHere});

  final String workspaceId;

  /// Folder names already on this computer, not offered again.
  final Set<String> alreadyHere;

  @override
  ConsumerState<RestoreFromGitHubDialog> createState() => _RestoreFromGitHubDialogState();
}

class _RestoreFromGitHubDialogState extends ConsumerState<RestoreFromGitHubDialog> {
  static const _tokenKey = 'github_token';
  final _token = TextEditingController();

  List<Map<String, dynamic>>? _apps;
  bool _busy = false;
  String? _working;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(settingsStoreProvider).read(_tokenKey).then((t) {
      if (mounted && t != null && t.isNotEmpty) _load(t);
    });
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _load(String token) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final apps = await (await ref.read(runnerApiProvider.future)).githubApps(token);
      await ref.read(settingsStoreProvider).write(_tokenKey, token);
      if (mounted) setState(() => _apps = apps);
    } on RunnerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore(Map<String, dynamic> app) async {
    final token = await ref.read(settingsStoreProvider).read(_tokenKey) ?? '';
    setState(() {
      _working = app['repo'] as String?;
      _error = null;
    });
    try {
      final project = await (await ref.read(runnerApiProvider.future))
          .restoreFromGitHub(widget.workspaceId, token, '${app['repo']}', owner: app['owner'] as String?);
      if (mounted) Navigator.of(context).pop<Project>(project);
    } on RunnerException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  String _folder(String repo) => repo.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final apps = _apps;

    return AlertDialog(
      title: Text(l.ghRestoreTitle),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.ghRestoreHint, style: context.text.bodySmall),
            if (apps == null) ...[
              Gap.vMd,
              SecretField(
                controller: _token,
                label: l.ghToken,
                getUrl: 'https://github.com/settings/tokens/new?scopes=repo&description=Ember',
                getLabel: l.ghGetToken,
              ),
            ] else if (apps.isEmpty)
              EmptyState(icon: Icons.cloud_off_outlined, text: l.ghRestoreNone, compact: true)
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: apps.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final a = apps[i];
                    final repo = '${a['repo']}';
                    final here = widget.alreadyHere.contains(_folder(repo));
                    return ListTile(
                      leading: const Icon(Icons.cloud_download_outlined),
                      title: Text('${a['app']}'),
                      subtitle: Text(here ? l.ghRestoreHere : repo),
                      enabled: !here && _working == null,
                      trailing: _working == repo ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                      onTap: here || _working != null ? null : () => _restore(a),
                    );
                  },
                ),
              ),
            if (_busy) const Padding(padding: EdgeInsets.only(top: Gap.md), child: LinearProgressIndicator()),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: Gap.md), child: InlineMessage(_error!, error: true)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _working == null ? () => Navigator.of(context).pop() : null, child: Text(l.cancel)),
        if (apps == null)
          FilledButton(
            onPressed: _busy ? null : () => _load(_token.text.trim()),
            child: Text(l.ghRestoreLoad),
          )
        else
          TextButton(
            onPressed: _busy || _working != null
                ? null
                : () async {
                    final t = await ref.read(settingsStoreProvider).read(_tokenKey) ?? '';
                    await _load(t);
                  },
            child: Text(l.refresh),
          ),
      ],
    );
  }
}

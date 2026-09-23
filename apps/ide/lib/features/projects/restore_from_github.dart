import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show Project, RunnerException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../l10n/app_localizations.dart';

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
    final theme = Theme.of(context);
    final apps = _apps;

    return AlertDialog(
      title: Text(l.ghRestoreTitle),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.ghRestoreHint, style: theme.textTheme.bodySmall),
            if (apps == null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _token,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l.ghToken,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: l.paste,
                    icon: const Icon(Icons.content_paste),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) _token.text = data!.text!.trim();
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://github.com/settings/tokens/new?scopes=repo&description=Ember'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l.ghGetToken),
                ),
              ),
            ] else if (apps.isEmpty)
              Padding(padding: const EdgeInsets.only(top: 16), child: Text(l.ghRestoreNone))
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
            if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: SelectableText(_error!, style: TextStyle(color: theme.colorScheme.error))),
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

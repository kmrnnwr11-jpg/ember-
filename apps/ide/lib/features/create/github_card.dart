import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';

/// Keeps the app's source on GitHub: one repository per app, the user's own.
class GitHubCard extends ConsumerStatefulWidget {
  const GitHubCard({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<GitHubCard> createState() => _GitHubCardState();
}

class _GitHubCardState extends ConsumerState<GitHubCard> {
  static const _tokenKey = 'github_token';
  final _token = TextEditingController();
  bool _hasToken = false;
  bool _busy = false;
  String? _message;
  String? _repoUrl;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    ref.read(keyValueStoreProvider).read(_tokenKey).then((t) {
      if (mounted && t != null && t.isNotEmpty) setState(() => _hasToken = true);
    });
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final store = ref.read(keyValueStoreProvider);
    final typed = _token.text.trim();
    if (typed.isNotEmpty) {
      await store.write(_tokenKey, typed);
      _token.clear();
      if (mounted) setState(() => _hasToken = true);
    }
    final token = await store.read(_tokenKey);
    if (token == null || token.isEmpty) {
      setState(() {
        _message = l.ghNeedsToken;
        _error = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _error = false;
    });
    try {
      final res = await (await ref.read(runnerApiProvider.future)).saveToGitHub(widget.projectId, token);
      setState(() {
        _repoUrl = res['url'] as String?;
        _message = res['created'] == true ? l.ghCreated('${res['repo']}') : l.ghUpdated('${res['repo']}');
        _error = false;
      });
    } on RunnerException catch (e) {
      setState(() {
        _message = e.message;
        _error = true;
        if (e.code == 'bad_token') _hasToken = false;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [const Icon(Icons.hub_outlined), const SizedBox(width: 8), Text(l.ghTitle, style: theme.textTheme.titleMedium)]),
            const SizedBox(height: 4),
            Text(l.ghHint, style: theme.textTheme.bodySmall),
            if (!_hasToken) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _token,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l.ghToken,
                  helperText: l.ghTokenHelp,
                  helperMaxLines: 3,
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
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://github.com/settings/tokens/new?scopes=repo&description=Ember'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l.ghGetToken),
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 10),
              Row(children: [const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Expanded(child: Text(l.ghSaving))]),
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
                FilledButton.icon(onPressed: _busy ? null : _save, icon: const Icon(Icons.cloud_upload_outlined), label: Text(l.ghSave)),
                if (_repoUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(_repoUrl!), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l.ghOpen),
                  ),
                if (_hasToken)
                  TextButton(
                    onPressed: () async {
                      await ref.read(keyValueStoreProvider).delete(_tokenKey);
                      if (mounted) setState(() => _hasToken = false);
                    },
                    child: Text(l.ghForgetToken),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

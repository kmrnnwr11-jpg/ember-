import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';

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
  String? _linkedRepo;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    ref.read(settingsStoreProvider).read(_tokenKey).then((t) {
      if (mounted && t != null && t.isNotEmpty) setState(() => _hasToken = true);
    });
    // Show right away whether this app is already saved on GitHub, and where.
    ref.read(runnerApiProvider.future).then((api) => api.githubLink(widget.projectId)).then((info) {
      if (mounted && info['linked'] == true) {
        setState(() {
          _linkedRepo = '${info['owner']}/${info['repo']}';
          _repoUrl = info['url'] as String?;
        });
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final store = ref.read(settingsStoreProvider);
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
    return SectionCard(
      icon: Icons.hub_outlined,
      title: l.ghTitle,
      hint: l.ghHint,
      children: [
        // Already linked to a repository: show its name, so it is clear the
        // app is saved and where, without pressing anything.
        if (_linkedRepo != null) ...[
          Gap.vSm,
          InkWell(
            borderRadius: Radii.smAll,
            onTap: _repoUrl == null ? null : () => launchUrl(Uri.parse(_repoUrl!), mode: LaunchMode.externalApplication),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kTapTarget),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                heightFactor: 1,
                child: StatusRow(done: true, text: '${l.ghSavedOn}: $_linkedRepo', trailing: const Icon(Icons.open_in_new, size: 16)),
              ),
            ),
          ),
        ],
        if (!_hasToken) ...[
          Gap.vMd,
          SecretField(
            controller: _token,
            label: l.ghToken,
            helper: l.ghTokenHelp,
            getUrl: 'https://github.com/settings/tokens/new?scopes=repo&description=Ember',
            getLabel: l.ghGetToken,
          ),
        ],
        if (_busy) ...[
          Gap.vMd,
          BusyRow(l.ghSaving),
        ],
        if (_message != null) ...[
          Gap.vMd,
          InlineMessage(_message!, error: _error),
        ],
        Gap.vMd,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
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
                  await ref.read(settingsStoreProvider).delete(_tokenKey);
                  if (mounted) setState(() => _hasToken = false);
                },
                child: Text(l.ghForgetToken),
              ),
          ],
        ),
      ],
    );
  }
}

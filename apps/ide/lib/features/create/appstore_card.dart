import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';

/// Apple's side of publishing, with the same listing Google gets: title,
/// description, what's new, privacy address and the privacy answers, in every
/// language. The key stays on this computer.
class AppStoreCard extends ConsumerStatefulWidget {
  const AppStoreCard({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<AppStoreCard> createState() => _AppStoreCardState();
}

class _AppStoreCardState extends ConsumerState<AppStoreCard> {
  static const _keyIdKey = 'appstore_key_id';
  static const _issuerKey = 'appstore_issuer_id';
  static const _p8Key = 'appstore_p8';

  final _keyId = TextEditingController();
  final _issuer = TextEditingController();
  final _p8 = TextEditingController();

  bool _hasKey = false;
  bool _busy = false;
  bool _uploadBuild = false;
  bool _submit = false;
  String? _message;
  bool _error = false;
  List<String> _notes = const [];

  @override
  void initState() {
    super.initState();
    final store = ref.read(keyValueStoreProvider);
    Future.wait([store.read(_keyIdKey), store.read(_issuerKey), store.read(_p8Key)]).then((v) {
      if (mounted && (v[0]?.isNotEmpty ?? false) && (v[2]?.isNotEmpty ?? false)) setState(() => _hasKey = true);
    });
  }

  @override
  void dispose() {
    _keyId.dispose();
    _issuer.dispose();
    _p8.dispose();
    super.dispose();
  }

  /// The listing the user already wrote for Google, in Apple's words.
  Future<(Map<String, dynamic>?, List<Map<String, dynamic>>, String?)> _listing() async {
    final state = await (await ref.read(runnerApiProvider.future)).storeState(widget.projectId);
    final listing = state['listing'] as Map<String, dynamic>?;
    if (listing == null) return (null, <Map<String, dynamic>>[], null);

    Map<String, dynamic> page(String language, Map<String, dynamic> from) => {
      'language': language,
      'title': '${from['title'] ?? ''}',
      'subtitle': '${from['shortDescription'] ?? ''}',
      'description': '${from['fullDescription'] ?? ''}',
      'releaseNotes': '${from['releaseNotes'] ?? ''}',
    };

    final main = page('it-IT', listing);
    final others = <Map<String, dynamic>>[];
    try {
      final j = jsonDecode('${listing['translations'] ?? ''}') as Map<String, dynamic>;
      for (final e in ((j['pages'] as Map?) ?? const {}).entries) {
        others.add(page('${e.key}', (e.value as Map).cast<String, dynamic>()));
      }
    } catch (_) {
      // No translations saved yet: the main language is enough.
    }
    return (main, others, '${listing['privacyUrl'] ?? ''}');
  }

  Future<void> _publish() async {
    final l = AppLocalizations.of(context);
    final store = ref.read(keyValueStoreProvider);
    if (_keyId.text.trim().isNotEmpty) await store.write(_keyIdKey, _keyId.text.trim());
    if (_issuer.text.trim().isNotEmpty) await store.write(_issuerKey, _issuer.text.trim());
    if (_p8.text.trim().isNotEmpty) await store.write(_p8Key, _p8.text.trim());

    final keyId = await store.read(_keyIdKey) ?? '';
    final issuerId = await store.read(_issuerKey) ?? '';
    final p8 = await store.read(_p8Key) ?? '';
    if (keyId.isEmpty || issuerId.isEmpty || p8.isEmpty) {
      setState(() {
        _message = l.ascKeyHelp;
        _error = true;
      });
      return;
    }
    _p8.clear();

    setState(() {
      _busy = true;
      _hasKey = true;
      _message = null;
      _error = false;
      _notes = const [];
    });
    try {
      final (listing, translations, privacyUrl) = await _listing();
      final res = await (await ref.read(runnerApiProvider.future)).publishToAppStore(widget.projectId, {
        'keyId': keyId,
        'issuerId': issuerId,
        'privateKey': p8,
        'listing': ?listing,
        if (translations.isNotEmpty) 'translations': translations,
        'privacyPolicyUrl': ?(privacyUrl?.isNotEmpty ?? false ? privacyUrl : null),
        'uploadBuild': _uploadBuild,
        'submit': _submit,
      });
      setState(() {
        _message = l.ascDone('${res['versionString']}', ((res['languages'] as List?) ?? const []).join(', '));
        _notes = ((res['notes'] as List?) ?? const []).map((n) => '$n').toList();
        _error = false;
      });
    } on RunnerException catch (e) {
      setState(() {
        _message = e.message;
        _error = true;
        if (e.code == 'bad_key') _hasKey = false;
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
            Row(children: [const Icon(Icons.cloud_upload_outlined), const SizedBox(width: 8), Text(l.ascTitle, style: theme.textTheme.titleMedium)]),
            const SizedBox(height: 4),
            Text(l.ascHint, style: theme.textTheme.bodySmall),
            if (!_hasKey) ...[
              const SizedBox(height: 10),
              Text(l.ascKeyHelp, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _keyId, decoration: InputDecoration(labelText: l.ascKeyId, border: const OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _issuer, decoration: InputDecoration(labelText: l.ascIssuerId, border: const OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _p8,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l.ascPrivateKey,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: l.paste,
                    icon: const Icon(Icons.content_paste),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) _p8.text = data!.text!.trim();
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            CheckboxListTile(
              key: const Key('ascUploadBuild'),
              contentPadding: EdgeInsets.zero,
              value: _uploadBuild,
              onChanged: _busy ? null : (v) => setState(() => _uploadBuild = v ?? false),
              title: Text(l.ascUploadBuild),
            ),
            CheckboxListTile(
              key: const Key('ascSubmit'),
              contentPadding: EdgeInsets.zero,
              value: _submit,
              onChanged: _busy ? null : (v) => setState(() => _submit = v ?? false),
              title: Text(l.ascSubmit),
            ),
            if (_busy) ...[
              const SizedBox(height: 8),
              Row(children: [const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Expanded(child: Text(l.ascWorking))]),
            ],
            if (_message != null) ...[
              const SizedBox(height: 10),
              SelectableText(_message!, style: TextStyle(color: _error ? theme.colorScheme.error : null)),
            ],
            for (final note in _notes) Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $note', style: theme.textTheme.bodySmall)),
            const SizedBox(height: 10),
            Text(l.ascManual, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('ascPublish'),
                  onPressed: _busy ? null : _publish,
                  icon: const Icon(Icons.apple),
                  label: Text(l.ascPublish),
                ),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://appstoreconnect.apple.com/apps'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l.ascOpen),
                ),
                if (_hasKey)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            final store = ref.read(keyValueStoreProvider);
                            await Future.wait([store.delete(_keyIdKey), store.delete(_issuerKey), store.delete(_p8Key)]);
                            if (mounted) setState(() => _hasKey = false);
                          },
                    child: Text(l.ascForget),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

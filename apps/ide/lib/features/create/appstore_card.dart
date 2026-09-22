import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';

/// Apple's side of publishing, with the same listing Google gets: title,
/// description, what's new, privacy address and the privacy answers, in every
/// language.
///
/// The Apple key (Key ID, Issuer ID, AuthKey_….p8) is saved ONCE for the whole
/// account on the Runner, under ~/.ember/apple, so it comes back filled for
/// every project and survives a reload, a closed browser, a Runner restart or a
/// reboot. The .p8 never touches the browser's storage and never reaches git.
class AppStoreCard extends ConsumerStatefulWidget {
  const AppStoreCard({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<AppStoreCard> createState() => _AppStoreCardState();
}

class _AppStoreCardState extends ConsumerState<AppStoreCard> with AutomaticKeepAliveClientMixin {
  // The card lives in a scrolling ListView; without this its State (and so the
  // chosen category, checkboxes and review fields) would be thrown away when it
  // scrolls off screen and rebuilt empty on the way back.
  @override
  bool get wantKeepAlive => true;

  static final _keyIdRe = RegExp(r'^[A-Za-z0-9]{8,12}$');
  static final _issuerRe = RegExp(r'^[0-9a-fA-F-]{36}$');
  static final _fileKeyIdRe = RegExp(r'AuthKey_([A-Za-z0-9]{8,12})\.p8$', caseSensitive: false);

  final _keyId = TextEditingController();
  final _issuer = TextEditingController();
  final _p8 = TextEditingController();

  bool _loading = true;
  bool _hasKey = false; // a key is saved on the Runner
  bool _editingKey = false; // show the .p8 input (first time, or "Cambia chiave")
  String _p8File = ''; // e.g. "AuthKey_Z47GM3ZDZ6.p8"

  bool _busy = false; // publishing
  bool _verifying = false;
  bool _uploadBuild = false;
  bool _submit = false;

  // iOS submission chores Ember now fills automatically.
  String? _category; // App Store category id, e.g. "UTILITIES"
  bool _free = false;
  bool _screenshots = false;
  final _reviewEmail = TextEditingController();
  final _reviewNotes = TextEditingController();
  final _demoUser = TextEditingController();
  final _demoPass = TextEditingController();

  /// App Store categories (Italian label → App Store Connect API id).
  static const _categories = <(String, String)>[
    ('Utility', 'UTILITIES'),
    ('Produttività', 'PRODUCTIVITY'),
    ('Business', 'BUSINESS'),
    ('Istruzione', 'EDUCATION'),
    ('Intrattenimento', 'ENTERTAINMENT'),
    ('Finanza', 'FINANCE'),
    ('Cibo e bevande', 'FOOD_AND_DRINK'),
    ('Salute e fitness', 'HEALTH_AND_FITNESS'),
    ('Stile di vita', 'LIFESTYLE'),
    ('Musica', 'MUSIC'),
    ('Navigazione', 'NAVIGATION'),
    ('Notizie', 'NEWS'),
    ('Foto e video', 'PHOTO_AND_VIDEO'),
    ('Consultazione', 'REFERENCE'),
    ('Shopping', 'SHOPPING'),
    ('Social', 'SOCIAL_NETWORKING'),
    ('Sport', 'SPORTS'),
    ('Viaggi', 'TRAVEL'),
    ('Meteo', 'WEATHER'),
    ('Libri', 'BOOKS'),
    ('Strumenti sviluppatore', 'DEVELOPER_TOOLS'),
    ('Grafica e design', 'GRAPHICS_AND_DESIGN'),
    ('Giochi', 'GAMES'),
  ];

  Timer? _debounce;
  String? _savedMsg; // "Salvato ✓"
  String? _message; // publish / verify result or error
  bool _error = false;
  List<String> _notes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = await ref.read(runnerApiProvider.future);
      final creds = await api.appStoreCredentials();
      if (!mounted) return;
      final hasKey = creds['hasKey'] == true;
      setState(() {
        _hasKey = hasKey;
        _p8File = '${creds['p8File'] ?? ''}';
        _keyId.text = '${creds['keyId'] ?? ''}';
        _issuer.text = '${creds['issuerId'] ?? ''}';
        _editingKey = !hasKey; // need the .p8 the first time
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _keyId.dispose();
    _issuer.dispose();
    _p8.dispose();
    _reviewEmail.dispose();
    _reviewNotes.dispose();
    _demoUser.dispose();
    _demoPass.dispose();
    super.dispose();
  }

  /// Key ID / Issuer ID changed: save automatically once both look valid (the
  /// .p8 is not resent — it already lives on the Runner).
  void _onIdChanged() {
    _debounce?.cancel();
    if (!_hasKey || _editingKey) return; // while editing the key, saving happens on "Salva chiave"
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final keyId = _keyId.text.trim();
      final issuer = _issuer.text.trim();
      if (_keyIdRe.hasMatch(keyId) && _issuerRe.hasMatch(issuer)) _save(keyId: keyId, issuer: issuer);
    });
  }

  /// Persist to the Runner. With [privateKey] the .p8 is (re)stored; without it
  /// only the two IDs change.
  Future<void> _save({required String keyId, required String issuer, String? privateKey}) async {
    try {
      final api = await ref.read(runnerApiProvider.future);
      final res = await api.saveAppStoreCredentials(keyId: keyId, issuerId: issuer, privateKey: privateKey);
      if (!mounted) return;
      setState(() {
        _hasKey = res['hasKey'] == true;
        _p8File = '${res['p8File'] ?? _p8File}';
        _editingKey = false;
        _savedMsg = 'Salvato ✓';
        _message = null;
        _error = false;
      });
      _p8.clear();
      // Fade the confirmation after a moment.
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _savedMsg = null);
      });
    } on RunnerException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _error = true;
          _savedMsg = null;
        });
      }
    }
  }

  /// Save the pasted / loaded .p8. Refuses anything that is not the real key
  /// contents (e.g. only the file name), in Italian, without saving.
  Future<void> _saveKey() async {
    final keyId = _keyId.text.trim();
    final issuer = _issuer.text.trim();
    final p8 = _p8.text.trim();
    if (!_keyIdRe.hasMatch(keyId)) {
      setState(() {
        _message = 'Key ID non valido: è il codice breve accanto alla chiave, es. Z47GM3ZDZ6.';
        _error = true;
      });
      return;
    }
    if (!_issuerRe.hasMatch(issuer)) {
      setState(() {
        _message = "Issuer ID non valido: è il codice lungo (un UUID) in cima alla pagina Chiavi.";
        _error = true;
      });
      return;
    }
    if (!p8.contains('BEGIN PRIVATE KEY')) {
      setState(() {
        _message =
            'Questo non è il contenuto della chiave: incolla tutto il file AuthKey_….p8, dalla riga -----BEGIN PRIVATE KEY----- fino a -----END PRIVATE KEY-----. Il solo nome del file non basta.';
        _error = true;
      });
      return;
    }
    await _save(keyId: keyId, issuer: issuer, privateKey: p8);
  }

  /// Pick an AuthKey_….p8 file, read it, and fill the Key ID from its name.
  Future<void> _loadFile() async {
    try {
      const group = XTypeGroup(label: 'Apple key (.p8)', extensions: ['p8']);
      final file = await openFile(acceptedTypeGroups: const [group]);
      if (file == null) return;
      final content = await file.readAsString();
      final fromName = _fileKeyIdRe.firstMatch(file.name)?.group(1);
      if (!mounted) return;
      setState(() {
        _p8.text = content.trim();
        if (fromName != null && fromName.isNotEmpty) _keyId.text = fromName;
        _message = null;
        _error = false;
      });
      // If the IDs are already valid, store it straight away.
      if (_keyIdRe.hasMatch(_keyId.text.trim()) && _issuerRe.hasMatch(_issuer.text.trim())) await _saveKey();
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Non sono riuscito a leggere il file .p8: $e';
          _error = true;
        });
      }
    }
  }

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _message = null;
      _error = false;
    });
    try {
      final api = await ref.read(runnerApiProvider.future);
      final res = await api.verifyAppStoreConnection();
      if (!mounted) return;
      final n = res['apps'];
      setState(() {
        _message = n is int ? 'Connessione OK (App Store Connect raggiunto)' : 'Connessione OK';
        _error = false;
      });
    } on RunnerException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _error = true;
        });
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _forget() async {
    try {
      final api = await ref.read(runnerApiProvider.future);
      await api.deleteAppStoreCredentials();
    } catch (_) {
      // Even if the call fails, let the user start over locally.
    }
    if (!mounted) return;
    setState(() {
      _hasKey = false;
      _editingKey = true;
      _p8File = '';
      _keyId.clear();
      _issuer.clear();
      _p8.clear();
      _message = null;
      _error = false;
      _savedMsg = null;
    });
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
    if (!_hasKey) {
      setState(() {
        _message = 'Salva prima la chiave Apple (Key ID, Issuer ID e file .p8).';
        _error = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _error = false;
      _notes = const [];
    });
    try {
      final (listing, translations, privacyUrl) = await _listing();
      final review = <String, dynamic>{
        if (_reviewEmail.text.trim().isNotEmpty) 'email': _reviewEmail.text.trim(),
        if (_reviewNotes.text.trim().isNotEmpty) 'notes': _reviewNotes.text.trim(),
        if (_demoUser.text.trim().isNotEmpty) 'demoUser': _demoUser.text.trim(),
        if (_demoPass.text.trim().isNotEmpty) 'demoPassword': _demoPass.text.trim(),
      };
      // The Runner uses the saved account key; no secret leaves the browser.
      final res = await (await ref.read(runnerApiProvider.future)).publishToAppStore(widget.projectId, {
        'listing': ?listing,
        if (translations.isNotEmpty) 'translations': translations,
        'privacyPolicyUrl': ?(privacyUrl?.isNotEmpty ?? false ? privacyUrl : null),
        'uploadBuild': _uploadBuild,
        'submit': _submit,
        'category': ?_category,
        'free': _free,
        'screenshots': _screenshots,
        if (review.isNotEmpty) 'review': review,
      });
      setState(() {
        _message = l.ascDone('${res['versionString']}', ((res['languages'] as List?) ?? const []).join(', '));
        _notes = [..._doneSummary(res), ...((res['notes'] as List?) ?? const []).map((n) => '$n')];
        _error = false;
      });
    } on RunnerException catch (e) {
      setState(() {
        _message = e.message;
        _error = true;
        if (e.code == 'bad_key') {
          _hasKey = false;
          _editingKey = true;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A short, human list of the chores Ember filled on Apple this run.
  List<String> _doneSummary(Map<String, dynamic> res) {
    final out = <String>[];
    if (res['exportCompliance'] == true) out.add('Export compliance (crittografia) impostata');
    if (res['ageRated'] == true) out.add('Fascia d\'età compilata');
    if (res['categorized'] == true) out.add('Categoria impostata');
    if (res['reviewInfoSet'] == true) out.add('Dati per la revisione salvati');
    if (res['pricedFree'] == true) out.add('Prezzo: gratis in tutti i paesi');
    if (res['privacy'] is Map && (res['privacy'] as Map)['categories'] != null) out.add('Privacy (nutrition label) compilata');
    final shots = res['screenshots'];
    if (shots is Map && shots.isNotEmpty) {
      final total = shots.values.fold<int>(0, (a, b) => a + (b is int ? b : 0));
      if (total > 0) out.add('Screenshot caricati: $total');
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // keep-alive
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
            if (_loading) ...[
              const SizedBox(height: 12),
              const Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ] else ...[
              const SizedBox(height: 10),
              if (!_hasKey) Text(l.ascKeyHelp, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keyId,
                      onChanged: (_) => _onIdChanged(),
                      decoration: InputDecoration(labelText: l.ascKeyId, border: const OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _issuer,
                      onChanged: (_) => _onIdChanged(),
                      decoration: InputDecoration(labelText: l.ascIssuerId, border: const OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // The .p8 itself: a saved-state chip, or the input while (re)setting it.
              if (_hasKey && !_editingKey)
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Chiave salvata: $_p8File ✓', style: theme.textTheme.bodyMedium)),
                    TextButton.icon(
                      onPressed: _busy ? null : () => setState(() => _editingKey = true),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Cambia chiave'),
                    ),
                  ],
                )
              else ...[
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _loadFile,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Carica file .p8'),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : _saveKey,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salva chiave'),
                    ),
                    if (_hasKey)
                      TextButton(
                        onPressed: _busy ? null : () => setState(() => _editingKey = false),
                        child: const Text('Annulla'),
                      ),
                  ],
                ),
              ],
              if (_savedMsg != null) ...[
                const SizedBox(height: 8),
                Text(_savedMsg!, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
              ],
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
            // ---- iOS: le cose che prima compilavi a mano su App Store Connect ----
            const Divider(height: 20),
            Text('Cosa compilo per te su iOS', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              'Al Publish imposto in automatico: fascia d\'età (4+), export compliance (crittografia), privacy e — se le scegli qui sotto — categoria, prezzo e screenshot.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Categoria App Store', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('— non impostare —')),
                for (final c in _categories) DropdownMenuItem<String>(value: c.$2, child: Text(c.$1)),
              ],
              onChanged: _busy ? null : (v) => setState(() => _category = v),
            ),
            CheckboxListTile(
              key: const Key('ascFree'),
              contentPadding: EdgeInsets.zero,
              value: _free,
              onChanged: _busy ? null : (v) => setState(() => _free = v ?? false),
              title: const Text('App gratis (in tutti i paesi)'),
            ),
            CheckboxListTile(
              key: const Key('ascScreenshots'),
              contentPadding: EdgeInsets.zero,
              value: _screenshots,
              onChanged: _busy ? null : (v) => setState(() => _screenshots = v ?? false),
              title: const Text('Genera e carica screenshot iPhone/iPad'),
              subtitle: const Text('Usa l\'anteprima web (richiede la "modalità screenshot" nell\'app)'),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: const Text('Dati per la revisione (facoltativi)'),
              children: [
                TextField(
                  controller: _reviewEmail,
                  decoration: const InputDecoration(labelText: 'Email di contatto (vuoto = il tuo account)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewNotes,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Note per il recensore', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _demoUser, decoration: const InputDecoration(labelText: 'Account demo (se serve login)', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _demoPass, decoration: const InputDecoration(labelText: 'Password demo', border: OutlineInputBorder()))),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
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
                  onPressed: (_busy || _verifying || !_hasKey) ? null : _verify,
                  icon: _verifying
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('Verifica connessione'),
                ),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://appstoreconnect.apple.com/apps'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l.ascOpen),
                ),
                if (_hasKey)
                  TextButton(
                    onPressed: _busy ? null : _forget,
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

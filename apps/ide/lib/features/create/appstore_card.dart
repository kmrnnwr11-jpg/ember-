import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:url_launcher/url_launcher.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../l10n/app_localizations.dart';
import 'app_builder.dart';

/// Apple's side of publishing, with the same listing Google gets: title,
/// description, what's new, privacy address and the privacy answers, in every
/// language.
///
/// The Apple key (Key ID, Issuer ID, AuthKey_….p8) is saved ONCE for the whole
/// account on the Runner, under ~/.ember/apple, so it comes back filled for
/// every project and survives a reload, a closed browser, a Runner restart or a
/// reboot. The .p8 never touches the browser's storage and never reaches git.
class AppStoreCard extends ConsumerStatefulWidget {
  const AppStoreCard({super.key, required this.projectId, this.builder});

  final String projectId;

  /// The engine that wrote the app: it fixes the preflight findings made of code.
  final AppBuilder? builder;

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
  static final _teamRe = RegExp(r'^[A-Za-z0-9]{10}$');
  static final _fileKeyIdRe = RegExp(r'AuthKey_([A-Za-z0-9]{8,12})\.p8$', caseSensitive: false);

  final _keyId = TextEditingController();
  final _issuer = TextEditingController();
  final _p8 = TextEditingController();
  final _team = TextEditingController(); // Apple Developer Team ID, found by the Runner when empty

  bool _loading = true;
  bool _hasKey = false; // a key is saved on the Runner
  bool _editingKey = false; // show the .p8 input (first time, or "Cambia chiave")
  String _p8File = ''; // e.g. "AuthKey_Z47GM3ZDZ6.p8"

  bool _busy = false; // publishing
  bool _verifying = false;
  // A new app publishes everything with one press (build, screenshots, free,
  // review); the choices made later are kept per app.
  bool _uploadBuild = true;
  bool _submit = true;

  // iOS submission chores Ember now fills automatically.
  String? _category; // App Store category id, e.g. "UTILITIES"
  bool _free = true;
  bool _screenshots = true;
  final _reviewEmail = TextEditingController();
  final _reviewPhone = TextEditingController();
  final _marketingUrl = TextEditingController(); // developer website, where app-ads.txt lives
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
  Timer? _poll; // follows the one-press publish running on the Runner
  Map<String, dynamic>? _auto; // its last status
  List<Map<String, dynamic>> _checks = const []; // what Apple would reject, before sending
  bool _checking = false;
  String? _savedMsg; // "Salvato ✓"
  String? _message; // publish / verify result or error
  bool _error = false;
  List<String> _notes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// The publish choices of this app, kept on the Runner: a reload must not undo them.
  String get _optsKey => 'appstore_opts_${widget.projectId}';

  Future<void> _loadOptions() async {
    final raw = await Settings.instance.read(_optsKey);
    if (raw == null || !mounted) return;
    try {
      final o = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _uploadBuild = o['uploadBuild'] != false;
        _submit = o['submit'] != false;
        _category = o['category'] as String?;
        _free = o['free'] != false;
        _screenshots = o['screenshots'] != false;
      });
    } catch (_) {}
  }

  void _saveOptions() {
    unawaited(Settings.instance.write(_optsKey, jsonEncode({
      'uploadBuild': _uploadBuild,
      'submit': _submit,
      'category': _category,
      'free': _free,
      'screenshots': _screenshots,
    })).catchError((Object _) {}));
  }

  Future<void> _load() async {
    unawaited(_loadOptions());
    unawaited(_refreshAuto()); // a publish started earlier keeps showing its progress
    unawaited(_preflight());
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
        _team.text = '${creds['teamId'] ?? ''}';
        // Saved once for the account: shown filled for every app.
        if (_reviewPhone.text.isEmpty) _reviewPhone.text = '${creds['reviewPhone'] ?? ''}';
        if (_marketingUrl.text.isEmpty) _marketingUrl.text = '${creds['marketingUrl'] ?? ''}';
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
    _poll?.cancel();
    _keyId.dispose();
    _issuer.dispose();
    _p8.dispose();
    _team.dispose();
    _reviewEmail.dispose();
    _reviewPhone.dispose();
    _marketingUrl.dispose();
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
      final team = _team.text.trim();
      if (team.isNotEmpty && !_teamRe.hasMatch(team)) return; // still typing
      if (_keyIdRe.hasMatch(keyId) && _issuerRe.hasMatch(issuer)) _save(keyId: keyId, issuer: issuer);
    });
  }

  /// Persist to the Runner. With [privateKey] the .p8 is (re)stored; without it
  /// only the two IDs change.
  Future<void> _save({required String keyId, required String issuer, String? privateKey}) async {
    try {
      final api = await ref.read(runnerApiProvider.future);
      final res = await api.saveAppStoreCredentials(keyId: keyId, issuerId: issuer, privateKey: privateKey, teamId: _team.text.trim().toUpperCase());
      if (!mounted) return;
      setState(() {
        _team.text = '${res['teamId'] ?? _team.text}';
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
      final team = '${res['teamId'] ?? ''}';
      setState(() {
        if (team.isNotEmpty && _team.text.trim().isEmpty) _team.text = team;
        _message = [
          n is int ? 'Connessione OK (App Store Connect raggiunto)' : 'Connessione OK',
          if (team.isNotEmpty) 'Team $team',
        ].join(' · ');
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

    final main = page('en-US', listing); // the main listing is written in English, like on Play
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
        if (_reviewPhone.text.trim().isNotEmpty) 'phone': _reviewPhone.text.trim(),
        if (_reviewNotes.text.trim().isNotEmpty) 'notes': _reviewNotes.text.trim(),
        if (_demoUser.text.trim().isNotEmpty) 'demoUser': _demoUser.text.trim(),
        if (_demoPass.text.trim().isNotEmpty) 'demoPassword': _demoPass.text.trim(),
      };
      // The Runner uses the saved account key; no secret leaves the browser. It
      // runs the whole publish in the background; this card follows it.
      final status = await (await ref.read(runnerApiProvider.future)).autoPublishToAppStore(widget.projectId, {
        'listing': ?listing,
        if (translations.isNotEmpty) 'translations': translations,
        'privacyPolicyUrl': ?(privacyUrl?.isNotEmpty ?? false ? privacyUrl : null),
        'uploadBuild': _uploadBuild,
        'submit': _submit,
        'category': ?_category,
        'free': _free,
        'screenshots': _screenshots,
        if (_marketingUrl.text.trim().startsWith('https://')) 'marketingUrl': _marketingUrl.text.trim(),
        if (review.isNotEmpty) 'review': review,
      });
      _applyAuto(status);
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
      if (mounted && !_autoRunning) setState(() => _busy = false);
    }
  }

  Future<void> _preflight() async {
    setState(() => _checking = true);
    try {
      final res = await (await ref.read(runnerApiProvider.future)).appStorePreflight(widget.projectId);
      if (mounted) setState(() => _checks = ((res['findings'] as List?) ?? const []).cast<Map<String, dynamic>>());
    } catch (_) {
      // The check is advice: never block the card on it.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _fixChecks() async {
    final ids = _checks.where((f) => f['fixable'] == true).map((f) => '${f['id']}').toList();
    if (ids.isEmpty) return;
    setState(() => _checking = true);
    try {
      final res = await (await ref.read(runnerApiProvider.future)).fixAppStorePreflight(widget.projectId, ids);
      if (!mounted) return;
      final done = ((res['done'] as List?) ?? const []).cast<Map<String, dynamic>>();
      setState(() {
        _checks = ((res['findings'] as List?) ?? const []).cast<Map<String, dynamic>>();
        _message = done.map((d) => '${d['ok'] == true ? '✓' : '✗'} ${d['message']}').join('\n');
        _error = done.any((d) => d['ok'] != true);
        _notes = const [];
      });
    } on RunnerException catch (e) {
      if (mounted) setState(() => (_message = e.message, _error = true));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// "Before sending": what Apple would reject (red) or is worth fixing (amber).
  Widget _checksView(ThemeData theme) {
    final blocks = _checks.where((f) => f['severity'] == 'block').length;
    final fixable = _checks.where((f) => f['fixable'] == true).length;
    final b = widget.builder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(blocks > 0 ? Icons.gpp_bad_outlined : Icons.gpp_good_outlined, size: 20, color: blocks > 0 ? theme.colorScheme.error : theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _checks.isEmpty
                  ? 'Controllo prima dell’invio: nessun problema per Apple'
                  : blocks > 0
                      ? 'Controllo prima dell’invio: $blocks ${blocks == 1 ? 'problema blocca' : 'problemi bloccano'} l’invio'
                      : 'Controllo prima dell’invio: solo avvisi, si può inviare',
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(tooltip: 'Controlla di nuovo', onPressed: _checking ? null : _preflight, icon: _checking ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 18)),
        ]),
        for (final f in _checks)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(f['severity'] == 'block' ? Icons.error_outline : Icons.warning_amber_rounded, size: 18, color: f['severity'] == 'block' ? theme.colorScheme.error : Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${f['title']}', style: theme.textTheme.bodyMedium),
                      Text('${f['detail']}', style: theme.textTheme.bodySmall),
                      if ('${f['ask'] ?? ''}'.isNotEmpty && b != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                          onPressed: b.running ? null : () => b.improve('${f['ask']}', display: '${f['title']}').then((_) => _preflight()),
                          icon: const Icon(Icons.auto_fix_high, size: 16),
                          label: const Text('Fai correggere a Ember'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (fixable > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: _checking || _busy ? null : _fixChecks,
              icon: const Icon(Icons.build_circle_outlined),
              label: Text('Correggi ora ($fixable)'),
            ),
          ),
      ],
    );
  }

  static const _runningPhases = {'building', 'publishing', 'waiting'};
  bool get _autoRunning => _runningPhases.contains(_auto?['phase']);

  Future<void> _refreshAuto() async {
    try {
      final status = await (await ref.read(runnerApiProvider.future)).autoPublishStatus(widget.projectId);
      if (mounted && status['phase'] != null) _applyAuto(status);
    } catch (_) {
      // Runner unreachable for a moment: the next tick tries again.
    }
  }

  /// Shows a status from the Runner and keeps polling while it runs.
  void _applyAuto(Map<String, dynamic> status) {
    final l = AppLocalizations.of(context);
    final phase = '${status['phase']}';
    final result = status['result'] is Map ? (status['result'] as Map).cast<String, dynamic>() : null;
    final notes = ((status['notes'] as List?) ?? const []).map((n) => '$n').toList();
    final wasFailed = _auto?['phase'] == 'failed';
    setState(() {
      _auto = status;
      _busy = _autoRunning;
      if (phase == 'failed') {
        if (!wasFailed) unawaited(_preflight()); // the stop may have listed problems
        _message = '${status['error'] ?? status['message']}';
        _error = true;
        _notes = notes;
      } else if (phase == 'submitted' || phase == 'done') {
        _message = result != null
            ? '${status['message']}\n${l.ascDone('${result['versionString']}', ((result['languages'] as List?) ?? const []).join(', '))}'
            : '${status['message']}';
        _error = false;
        // Notes written while waiting (e.g. "press again") no longer apply once it went through.
        _notes = [if (result != null) ..._doneSummary(result), if (phase == 'done') ...notes];
      } else {
        _message = null;
        _error = false;
        _notes = const [];
      }
    });
    _poll?.cancel();
    if (_autoRunning) _poll = Timer(Duration(seconds: phase == 'waiting' ? 15 : 4), _refreshAuto);
  }

  /// The live steps of the one-press publish.
  Widget _autoProgress(ThemeData theme) {
    final a = _auto!;
    final steps = ((a['steps'] as List?) ?? const []).map((s) => '$s').where((s) => s != 'Parto').toList();
    final started = DateTime.tryParse('${a['startedAt']}');
    final minutes = started == null ? 0 : DateTime.now().difference(started).inMinutes;
    Widget row(Widget icon, String text, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 20, child: icon), const SizedBox(width: 8), Expanded(child: Text(text, style: style))]),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in steps) row(Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary), s, style: theme.textTheme.bodySmall),
        row(const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)), '${a['message']}', style: theme.textTheme.bodyMedium),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            a['phase'] == 'waiting'
                ? 'Puoi chiudere questa pagina: Ember continua da solo e invia in revisione appena Apple ha finito ($minutes min).'
                : 'In corso da $minutes min.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
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
              TextField(
                controller: _team,
                onChanged: (_) => _onIdChanged(),
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Team ID (facoltativo)',
                  helperText: 'Serve a firmare l’app iPhone. Se lo lasci vuoto lo leggo da Apple con la chiave.',
                  border: OutlineInputBorder(),
                ),
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
              onChanged: _busy ? null : (v) {
                setState(() => _uploadBuild = v ?? false);
                _saveOptions();
              },
              title: Text(l.ascUploadBuild),
            ),
            CheckboxListTile(
              key: const Key('ascSubmit'),
              contentPadding: EdgeInsets.zero,
              value: _submit,
              onChanged: _busy ? null : (v) {
                setState(() => _submit = v ?? false);
                _saveOptions();
              },
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
              onChanged: _busy ? null : (v) {
                setState(() => _category = v);
                _saveOptions();
              },
            ),
            CheckboxListTile(
              key: const Key('ascFree'),
              contentPadding: EdgeInsets.zero,
              value: _free,
              onChanged: _busy ? null : (v) {
                setState(() => _free = v ?? false);
                _saveOptions();
              },
              title: const Text('App gratis (in tutti i paesi)'),
            ),
            CheckboxListTile(
              key: const Key('ascScreenshots'),
              contentPadding: EdgeInsets.zero,
              value: _screenshots,
              onChanged: _busy ? null : (v) {
                setState(() => _screenshots = v ?? false);
                _saveOptions();
              },
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
                  controller: _marketingUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Sito sviluppatore (Marketing URL)',
                    helperText: 'AdMob cerca app-ads.txt qui. Salvato per tutte le app.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewPhone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefono di contatto (obbligatorio per Apple, es. +39 333 1234567)',
                    helperText: 'Lo vede solo chi rivede l’app. Lo ricordo per le prossime app.',
                    border: OutlineInputBorder(),
                  ),
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
            _checksView(theme),
            const Divider(height: 20),
            if (_autoRunning) ...[
              const SizedBox(height: 4),
              _autoProgress(theme),
            ] else if (_busy) ...[
              const SizedBox(height: 8),
              Row(children: [const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Expanded(child: Text(l.ascWorking))]),
            ],
            if (_message != null) ...[
              const SizedBox(height: 10),
              SelectableText(_message!, style: TextStyle(color: _error ? theme.colorScheme.error : null)),
            ],
            for (final note in _notes) Padding(padding: const EdgeInsets.only(top: 4), child: Text('• $note', style: theme.textTheme.bodySmall)),
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

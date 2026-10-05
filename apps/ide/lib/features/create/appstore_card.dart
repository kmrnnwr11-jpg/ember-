import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart' show RunnerException;

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../l10n/app_localizations.dart';
import 'app_builder.dart';
import 'appstore/appstore_publish.dart';
import 'appstore/appstore_sections.dart';

/// Apple's side of publishing, with the same listing Google gets: title,
/// description, what's new, privacy address and the privacy answers, in every
/// language.
///
/// The Apple key (Key ID, Issuer ID, AuthKey_….p8) is saved ONCE for the whole
/// account on the Runner, under ~/.ember/apple, so it comes back filled for
/// every project and survives a reload, a closed browser, a Runner restart or a
/// reboot. The .p8 never touches the browser's storage and never reaches git.
/// On the page it is four sections: key, what Ember fills in, checks, publish.
class AppStoreCard extends ConsumerStatefulWidget {
  const AppStoreCard({super.key, required this.projectId, this.builder});

  final String projectId;

  /// The engine that wrote the app: it fixes the preflight findings made of code.
  final AppBuilder? builder;

  @override
  ConsumerState<AppStoreCard> createState() => _AppStoreCardState();
}

/// Which section a message belongs to: it is shown where the action was started.
enum _Place { connection, checks, publish }

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
  bool _editingKey = false; // show the key form (first time, or "change key")
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

  Timer? _debounce;
  Timer? _poll; // follows the one-press publish running on the Runner
  Map<String, dynamic>? _auto; // its last status
  List<Map<String, dynamic>> _checks = const []; // what Apple would reject, before sending
  bool _checking = false;
  String? _savedMsg; // "Saved", for a moment after a save
  String? _message; // publish / verify result or error
  _Place _messageAt = _Place.publish;
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

  /// A publish choice changed: show it and keep it.
  void _setOption(VoidCallback change) {
    setState(change);
    _saveOptions();
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
    for (final c in [_keyId, _issuer, _p8, _team, _reviewEmail, _reviewPhone, _marketingUrl, _reviewNotes, _demoUser, _demoPass]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Key ID / Issuer ID changed: save automatically once both look valid (the
  /// .p8 is not resent — it already lives on the Runner).
  void _onIdChanged() {
    _debounce?.cancel();
    if (!_hasKey || _editingKey) return; // while editing the key, saving happens on "save key"
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
      final l = AppLocalizations.of(context);
      setState(() {
        _team.text = '${res['teamId'] ?? _team.text}';
        _hasKey = res['hasKey'] == true;
        _p8File = '${res['p8File'] ?? _p8File}';
        _editingKey = false;
        _savedMsg = l.saved;
        _message = null;
        _error = false;
      });
      _p8.clear();
      // Fade the confirmation after a moment.
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _savedMsg = null);
      });
    } on RunnerException catch (e) {
      if (!mounted) return;
      _savedMsg = null;
      _fail(e.message, _Place.connection);
    }
  }

  /// Save the pasted / loaded .p8. Refuses anything that is not the real key
  /// contents (e.g. only the file name), without saving.
  Future<void> _saveKey() async {
    final l = AppLocalizations.of(context);
    final keyId = _keyId.text.trim();
    final issuer = _issuer.text.trim();
    final p8 = _p8.text.trim();
    if (!_keyIdRe.hasMatch(keyId)) return _fail(l.asBadKeyId, _Place.connection);
    if (!_issuerRe.hasMatch(issuer)) return _fail(l.asBadIssuerId, _Place.connection);
    // The IDs now sit inside the "change key" form: with a key already saved
    // and nothing pasted, saving changes only the IDs and keeps that key.
    if (p8.isEmpty && _hasKey) return _save(keyId: keyId, issuer: issuer);
    if (!p8.contains('BEGIN PRIVATE KEY')) return _fail(l.asBadP8, _Place.connection);
    await _save(keyId: keyId, issuer: issuer, privateKey: p8);
  }

  /// Pick an AuthKey_….p8 file, read it, and fill the Key ID from its name.
  Future<void> _loadFile() async {
    final l = AppLocalizations.of(context);
    try {
      final group = XTypeGroup(label: l.asP8FileType, extensions: const ['p8']);
      final file = await openFile(acceptedTypeGroups: [group]);
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
      if (mounted) _fail(l.asP8ReadFailed('$e'), _Place.connection);
    }
  }

  Future<void> _verify() async {
    final l = AppLocalizations.of(context);
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
          n is int ? l.asVerifyOkReached : l.asVerifyOk,
          if (team.isNotEmpty) l.asVerifyTeam(team),
        ].join(' · ');
        _messageAt = _Place.connection;
        _error = false;
      });
    } on RunnerException catch (e) {
      if (mounted) _fail(e.message, _Place.connection);
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

  Future<void> _publish() async {
    if (!_hasKey) return _fail(AppLocalizations.of(context).asSaveKeyFirst, _Place.publish);
    setState(() {
      _busy = true;
      _message = null;
      _error = false;
      _notes = const [];
    });
    try {
      // The listing the user already wrote for Google, in Apple's words.
      final state = await (await ref.read(runnerApiProvider.future)).storeState(widget.projectId);
      final request = appStorePublishRequest(
        state: state,
        uploadBuild: _uploadBuild,
        submit: _submit,
        category: _category,
        free: _free,
        screenshots: _screenshots,
        marketingUrl: _marketingUrl.text,
        reviewEmail: _reviewEmail.text,
        reviewPhone: _reviewPhone.text,
        reviewNotes: _reviewNotes.text,
        demoUser: _demoUser.text,
        demoPassword: _demoPass.text,
      );
      // The Runner uses the saved account key; no secret leaves the browser. It
      // runs the whole publish in the background; this card follows it.
      final status = await (await ref.read(runnerApiProvider.future)).autoPublishToAppStore(widget.projectId, request);
      _applyAuto(status);
    } on RunnerException catch (e) {
      setState(() {
        _message = e.message;
        _messageAt = _Place.publish;
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
    final l = AppLocalizations.of(context);
    final ids = _checks.where((f) => f['fixable'] == true).map((f) => '${f['id']}').toList();
    if (ids.isEmpty) return;
    setState(() => _checking = true);
    try {
      final res = await (await ref.read(runnerApiProvider.future)).fixAppStorePreflight(widget.projectId, ids);
      if (!mounted) return;
      final done = ((res['done'] as List?) ?? const []).cast<Map<String, dynamic>>();
      setState(() {
        _checks = ((res['findings'] as List?) ?? const []).cast<Map<String, dynamic>>();
        _message = done.map((d) => d['ok'] == true ? l.asFixDone('${d['message']}') : l.asFixFailed('${d['message']}')).join('\n');
        _messageAt = _Place.checks;
        _error = done.any((d) => d['ok'] != true);
        _notes = const [];
      });
    } on RunnerException catch (e) {
      if (mounted) _fail(e.message, _Place.checks);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  bool get _autoRunning => AppStorePublishSection.runningPhases.contains(_auto?['phase']);

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
        _messageAt = _Place.publish;
        _error = true;
        _notes = notes;
      } else if (phase == 'submitted' || phase == 'done') {
        _message = result != null
            ? '${status['message']}\n${l.ascDone('${result['versionString']}', ((result['languages'] as List?) ?? const []).join(', '))}'
            : '${status['message']}';
        _messageAt = _Place.publish;
        _error = false;
        // Notes written while waiting (e.g. "press again") no longer apply once it went through.
        _notes = [if (result != null) ...appStoreDoneSummary(l, result), if (phase == 'done') ...notes];
      } else {
        _message = null;
        _error = false;
        _notes = const [];
      }
    });
    _poll?.cancel();
    if (_autoRunning) _poll = Timer(Duration(seconds: phase == 'waiting' ? 15 : 4), _refreshAuto);
  }

  /// Says what went wrong, in the section where the action was started.
  void _fail(String message, _Place at) => setState(() {
    _message = message;
    _messageAt = at;
    _error = true;
  });

  String? _messageFor(_Place place) => _messageAt == place ? _message : null;

  @override
  Widget build(BuildContext context) {
    super.build(context); // keep-alive
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppStoreConnectionSection(
          loading: _loading,
          hasKey: _hasKey,
          editingKey: _editingKey,
          p8File: _p8File,
          busy: _busy,
          verifying: _verifying,
          keyId: _keyId,
          issuer: _issuer,
          team: _team,
          p8: _p8,
          onIdChanged: _onIdChanged,
          onEditKey: (editing) => setState(() => _editingKey = editing),
          onLoadFile: _loadFile,
          onSaveKey: _saveKey,
          onVerify: _verify,
          onForget: _forget,
          saved: _savedMsg,
          message: _messageFor(_Place.connection),
          error: _error,
        ),
        AppStoreFillSection(
          busy: _busy,
          category: _category,
          free: _free,
          screenshots: _screenshots,
          uploadBuild: _uploadBuild,
          submit: _submit,
          onCategory: (v) => _setOption(() => _category = v),
          onFree: (v) => _setOption(() => _free = v),
          onScreenshots: (v) => _setOption(() => _screenshots = v),
          onUploadBuild: (v) => _setOption(() => _uploadBuild = v),
          onSubmit: (v) => _setOption(() => _submit = v),
          reviewEmail: _reviewEmail,
          reviewPhone: _reviewPhone,
          marketingUrl: _marketingUrl,
          reviewNotes: _reviewNotes,
          demoUser: _demoUser,
          demoPass: _demoPass,
        ),
        AppStoreChecksSection(
          checks: _checks,
          checking: _checking,
          busy: _busy,
          builder: widget.builder,
          onRefresh: _preflight,
          onFix: _fixChecks,
          message: _messageFor(_Place.checks),
          error: _error,
        ),
        AppStorePublishSection(
          busy: _busy,
          onPublish: _publish,
          auto: _auto,
          message: _messageFor(_Place.publish),
          error: _error,
          notes: _notes,
        ),
      ],
    );
  }
}

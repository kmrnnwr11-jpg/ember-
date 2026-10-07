import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'connect_models.dart';
import 'connect_sheet_parts.dart';

Future<bool?> showGoogleConnectSheet(BuildContext context, StoreAccounts accounts) =>
    showConnectSheet(context, (_) => GoogleConnectSheet(accounts: accounts));

/// Connecting Google Play, once: the key file of a service account, checked
/// with Google before it is kept. With the Google Cloud tools on this computer
/// the whole thing can also be done hands-free.
class GoogleConnectSheet extends ConsumerStatefulWidget {
  const GoogleConnectSheet({super.key, required this.accounts});
  final StoreAccounts accounts;

  @override
  ConsumerState<GoogleConnectSheet> createState() => _GoogleConnectSheetState();
}

class _GoogleConnectSheetState extends ConsumerState<GoogleConnectSheet> {
  final _paste = TextEditingController();
  late final _developer = TextEditingController(text: widget.accounts.developerId);
  PickedKey? _file;
  String? _working;
  String? _error;

  /// The Google account the Google Cloud tools are signed in with ('' when nobody is).
  late String _gcloud = widget.accounts.gcloudAccount;
  bool _waitingSignIn = false;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    _paste.dispose();
    _developer.dispose();
    super.dispose();
  }

  String get _key => _paste.text.trim().isNotEmpty ? _paste.text.trim() : (_file?.text ?? '');
  bool get _busy => _working != null;
  String _link(String id) => widget.accounts.links[id] ?? fallbackLinks[id]!;

  Future<void> _pick() async {
    final picked = await pickKeyFile('JSON', const ['json']);
    if (picked != null && mounted) setState(() => _file = picked);
  }

  /// Runs [action] with a line of progress, and closes with a yes when it works.
  Future<void> _run(String progress, Future<void> Function() action) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _working = progress;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = connectFailure(l, e));
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    await _run(l.fxcChecking, () async {
      final api = await ref.read(runnerApiProvider.future);
      await api.connectGooglePlay(serviceAccount: _key, developerId: _developer.text.trim());
    });
  }

  /// Opens the window that signs the Google Cloud tools in to Google, then watches for the sign-in to finish.
  Future<void> _signIn() async {
    final l = AppLocalizations.of(context);
    try {
      await (await ref.read(runnerApiProvider.future)).startGcloudLogin();
    } catch (e) {
      if (mounted) setState(() => _error = connectFailure(l, e));
      return;
    }
    setState(() {
      _error = null;
      _waitingSignIn = true;
    });
    var tries = 0;
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (t) async {
      tries++;
      try {
        final now = StoreAccounts.fromJson(await (await ref.read(runnerApiProvider.future)).connectGcloudStatus());
        if (!mounted) return;
        if (now.gcloudAccount.isNotEmpty) {
          t.cancel();
          setState(() {
            _gcloud = now.gcloudAccount;
            _waitingSignIn = false;
          });
        }
      } catch (_) {
        // The Runner did not answer this time: the next try asks again.
      }
      if (tries >= 100 && mounted) {
        t.cancel();
        setState(() => _waitingSignIn = false);
      }
    });
  }

  /// The hands-free way: key, invitation in Play Console, then the same check and save.
  Future<void> _auto() async {
    final l = AppLocalizations.of(context);
    final dev = _developer.text.trim();
    if (_gcloud.isEmpty) {
      setState(() => _error = l.fxcWhyGcloudLogin);
      return;
    }
    if (dev.isEmpty) {
      setState(() => _error = l.fxcWhyDeveloperId);
      return;
    }
    await _run(l.fxcAutoWorking, () async {
      final api = await ref.read(runnerApiProvider.future);
      final made = await api.playCreateKey();
      await api.playInvite(dev, '${made['email']}');
      await api.connectGooglePlay(serviceAccount: '${made['key']}', developerId: dev);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ConnectSheetFrame(
      title: l.fxcGoogleTitle,
      children: [
        StepsList([l.fxcGoogleStep1, l.fxcGoogleStep2, l.fxcGoogleStep3, l.fxcGoogleStep4]),
        Gap.vMd,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            OutlinedButton.icon(key: const Key('openGoogleCloud'), onPressed: () => openLink(_link('googleCloudKeys')), icon: const Icon(Icons.open_in_new, size: 18), label: Text(l.fxcOpenGoogleCloud)),
            OutlinedButton.icon(key: const Key('openPlayConsole'), onPressed: () => openLink(_link('playConsole')), icon: const Icon(Icons.open_in_new, size: 18), label: Text(l.fxcOpenPlayConsole)),
          ],
        ),
        Gap.vLg,
        KeyFileRow(buttonKey: const Key('chooseJson'), label: l.fxcChooseJson, picked: _file?.name, onPick: _pick, enabled: !_busy),
        Gap.vSm,
        SecretField(controller: _paste, label: l.fxcPasteKey, hint: '{ "type": "service_account", … }', maxLines: 4, enabled: !_busy, onChanged: (_) => setState(() {})),
        Gap.vSm,
        TextField(
          key: const Key('developerId'),
          controller: _developer,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.fxcDeveloperId, helperText: l.fxcDeveloperIdHelp, helperMaxLines: 3),
        ),
        if (_error != null) ...[Gap.vMd, InlineMessage(_error!, error: true)],
        Gap.vLg,
        if (_busy)
          BusyRow(_working!)
        else
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              FilledButton.icon(key: const Key('saveGoogle'), onPressed: _key.isEmpty ? null : _save, icon: const Icon(Icons.verified_outlined), label: Text(l.fxcCheckSave)),
              if (widget.accounts.gcloudInstalled && _gcloud.isNotEmpty)
                OutlinedButton.icon(key: const Key('autoGoogle'), onPressed: _auto, icon: const Icon(Icons.auto_fix_high), label: Text(l.fxcAuto)),
              if (widget.accounts.gcloudInstalled && _gcloud.isEmpty)
                OutlinedButton.icon(key: const Key('gcloudSignIn'), onPressed: _waitingSignIn ? null : _signIn, icon: const Icon(Icons.login), label: Text(l.fxcGcloudSignIn)),
            ],
          ),
        if (widget.accounts.gcloudInstalled) ...[
          Gap.vSm,
          if (_waitingSignIn) BusyRow(l.fxcGcloudWaiting) else Text(_gcloud.isEmpty ? l.fxcAutoHelp : l.fxcGcloudSignedIn(_gcloud), style: context.text.bodySmall),
        ],
      ],
    );
  }
}

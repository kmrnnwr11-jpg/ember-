import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'connect_models.dart';
import 'connect_sheet_parts.dart';

Future<bool?> showAppleConnectSheet(BuildContext context, StoreAccounts accounts) =>
    showConnectSheet(context, (_) => AppleConnectSheet(accounts: accounts));

/// Connecting the App Store, once: the App Store Connect key (Key ID, Issuer
/// ID and the .p8 file), checked with Apple before it is kept.
class AppleConnectSheet extends ConsumerStatefulWidget {
  const AppleConnectSheet({super.key, required this.accounts});
  final StoreAccounts accounts;

  @override
  ConsumerState<AppleConnectSheet> createState() => _AppleConnectSheetState();
}

class _AppleConnectSheetState extends ConsumerState<AppleConnectSheet> {
  final _issuer = TextEditingController();
  late final _keyId = TextEditingController(text: widget.accounts.apple.account);
  late final _team = TextEditingController(text: widget.accounts.apple.teamId);
  PickedKey? _file;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _issuer.dispose();
    _keyId.dispose();
    _team.dispose();
    super.dispose();
  }

  /// A key is already saved: the file may stay out, and the saved one is kept.
  bool get _hasSaved => widget.accounts.apple.state != StoreState.missing;
  bool get _ready => _issuer.text.trim().isNotEmpty && _keyId.text.trim().isNotEmpty && (_file != null || _hasSaved);
  String get _link => widget.accounts.links['appStoreKeys'] ?? fallbackLinks['appStoreKeys']!;

  Future<void> _pick() async {
    final picked = await pickKeyFile('p8', const ['p8']);
    if (picked != null && mounted) setState(() => _file = picked);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = await ref.read(runnerApiProvider.future);
      await api.connectApple(keyId: _keyId.text.trim(), issuerId: _issuer.text.trim(), privateKey: _file?.text, teamId: _team.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = connectFailure(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ConnectSheetFrame(
      title: l.fxcAppleTitle,
      children: [
        StepsList([l.fxcAppleStep1, l.fxcAppleStep2, l.fxcAppleStep3]),
        Gap.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(key: const Key('openAppStoreConnect'), onPressed: () => openLink(_link), icon: const Icon(Icons.open_in_new, size: 18), label: Text(l.fxcOpenAppStoreConnect)),
        ),
        Gap.vLg,
        TextField(
          key: const Key('appleIssuer'),
          controller: _issuer,
          enabled: !_busy,
          autocorrect: false,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l.fxcIssuerId, helperText: l.fxcIssuerHelp, helperMaxLines: 2),
        ),
        Gap.vSm,
        TextField(
          key: const Key('appleKeyId'),
          controller: _keyId,
          enabled: !_busy,
          autocorrect: false,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l.fxcKeyId, helperText: l.fxcKeyIdHelp, helperMaxLines: 2),
        ),
        Gap.vMd,
        KeyFileRow(buttonKey: const Key('chooseP8'), label: l.fxcChooseP8, picked: _file?.name, onPick: _pick, enabled: !_busy),
        if (_hasSaved) ...[Gap.vXs, Text(l.fxcKeepSavedKey, style: context.text.bodySmall)],
        Gap.vSm,
        TextField(
          key: const Key('appleTeam'),
          controller: _team,
          enabled: !_busy,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: l.fxcTeamId, helperText: l.fxcTeamIdHelp, helperMaxLines: 2),
        ),
        if (_error != null) ...[Gap.vMd, InlineMessage(_error!, error: true)],
        Gap.vLg,
        if (_busy) BusyRow(l.fxcChecking) else FilledButton.icon(key: const Key('saveApple'), onPressed: _ready ? _save : null, icon: const Icon(Icons.verified_outlined), label: Text(l.fxcCheckSave)),
      ],
    );
  }
}

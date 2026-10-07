import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'connect_apple_sheet.dart';
import 'connect_controller.dart';
import 'connect_google_sheet.dart';
import 'connect_models.dart';

/// What the store said, in the owner's words (the Runner's own text is only a hint).
String storeWhy(AppLocalizations l, StoreAccount a) => switch (a.detail) {
  'bad_key' => l.fxcWhyBadKey,
  'key_refused' => l.fxcWhyRefused,
  'no_permission' => l.fxcWhyNoRole,
  'offline' => l.fxcWhyOffline,
  _ => '',
};

Tone storeTone(StoreState s) => switch (s) {
  StoreState.connected => Tone.success,
  StoreState.missing => Tone.neutral,
  StoreState.invalid => Tone.error,
  StoreState.unreachable => Tone.attention,
};

String storeStateLabel(AppLocalizations l, StoreState s) => switch (s) {
  StoreState.connected => l.fxcStateConnected,
  StoreState.missing => l.fxcStateMissing,
  StoreState.invalid => l.fxcStateInvalid,
  StoreState.unreachable => l.fxcStateUnreachable,
};

/// Opens the connection window of one store.
Future<void> openConnectSheet(BuildContext context, WidgetRef ref, String provider, StoreAccounts accounts) async {
  final l = AppLocalizations.of(context);
  final Future<bool?> window = provider == 'google_play' ? showGoogleConnectSheet(context, accounts) : showAppleConnectSheet(context, accounts);
  if (await window != true) return;
  storeAccountsChanged(ref);
  // The window is gone by now: the message comes from the screen that opened it.
  if (context.mounted) showEmberSnack(context, l.fxcConnectedOk(provider == 'google_play' ? l.fxcGoogleName : l.fxcAppleName));
}

/// "Store accounts": Google Play and the App Store, each with its state and
/// the buttons to connect it once, check it, or forget it.
class StoreAccountsSection extends ConsumerWidget {
  const StoreAccountsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final accounts = ref.watch(storeAccountsProvider);
    return SectionCard(
      key: const Key('storeAccounts'),
      icon: Icons.storefront_outlined,
      title: l.fxcTitle,
      hint: l.fxcIntro,
      children: [
        Gap.vSm,
        accounts.when(
          loading: () => Padding(padding: const EdgeInsets.all(Gap.lg), child: LoadingState(text: l.fxLoading)),
          error: (e, _) => ErrorState(message: l.error(e is RunnerException ? e.message : '$e'), onRetry: () => ref.invalidate(storeAccountsProvider)),
          data: (a) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StoreAccountRow(rowKey: 'GooglePlay', icon: Icons.android, name: l.fxcGoogleName, account: a.googlePlay, accounts: a),
              const Divider(height: Gap.xl),
              StoreAccountRow(rowKey: 'Apple', icon: Icons.apple, name: l.fxcAppleName, account: a.apple, accounts: a),
            ],
          ),
        ),
      ],
    );
  }
}

/// One store: its name and state, who it is connected as, and what can be done.
class StoreAccountRow extends ConsumerStatefulWidget {
  const StoreAccountRow({super.key, required this.rowKey, required this.icon, required this.name, required this.account, required this.accounts});
  final String rowKey;
  final IconData icon;
  final String name;
  final StoreAccount account;
  final StoreAccounts accounts;

  @override
  ConsumerState<StoreAccountRow> createState() => _StoreAccountRowState();
}

class _StoreAccountRowState extends ConsumerState<StoreAccountRow> {
  bool _busy = false;

  String get _path => providerPath(widget.account.provider);

  Future<void> _run(Future<void> Function() action) async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) storeAccountsChanged(ref);
    } on RunnerException catch (e) {
      if (mounted) showEmberSnack(context, l.error(e.message), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final l = AppLocalizations.of(context);
    final ok = await showConfirm(context, title: l.fxcDisconnectTitle(widget.name), message: l.fxcDisconnectBody, confirmLabel: l.fxcDisconnect, destructive: true);
    if (!ok || !mounted) return;
    await _run(() async => (await ref.read(runnerApiProvider.future)).connectDisconnect(_path));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = widget.account;
    final why = storeWhy(l, a);
    final isApple = a.provider == 'apple';
    final who = a.account.isEmpty ? '' : (isApple ? [l.fxcAccountApple(a.account), if (a.teamId.isNotEmpty) l.fxcAccountTeam(a.teamId)].join(' · ') : l.fxcAccountGoogle(a.account));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(widget.icon),
            Gap.hSm,
            Expanded(child: Text(widget.name, style: context.text.titleMedium)),
            Pill(storeStateLabel(l, a.state), tone: storeTone(a.state), icon: a.connected ? Icons.check : null),
          ],
        ),
        if (who.isNotEmpty) ...[Gap.vXs, SelectableText(who, style: context.text.bodySmall)],
        if (why.isNotEmpty && !a.connected) ...[Gap.vXs, Text(why, style: context.text.bodySmall?.copyWith(color: a.state == StoreState.invalid ? context.scheme.error : null))],
        Gap.vMd,
        if (_busy)
          BusyRow(l.fxcChecking)
        else
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              if (!a.connected || a.state == StoreState.invalid)
                FilledButton.icon(
                  key: Key('connect${widget.rowKey}'),
                  onPressed: () => openConnectSheet(context, ref, a.provider, widget.accounts),
                  icon: const Icon(Icons.link),
                  label: Text(a.state == StoreState.invalid ? l.fxcReconnect : l.fxcConnect),
                )
              else
                OutlinedButton.icon(
                  key: Key('reconnect${widget.rowKey}'),
                  onPressed: () => openConnectSheet(context, ref, a.provider, widget.accounts),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l.fxcChange),
                ),
              if (a.state != StoreState.missing)
                TextButton.icon(
                  key: Key('verify${widget.rowKey}'),
                  onPressed: () => _run(() async => (await ref.read(runnerApiProvider.future)).connectVerify(_path)),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l.fxcVerify),
                ),
              if (a.state != StoreState.missing)
                TextButton(key: Key('disconnect${widget.rowKey}'), onPressed: _disconnect, child: Text(l.fxcDisconnect)),
            ],
          ),
      ],
    );
  }
}

/// On the dashboard: a store is not connected yet, so apps would stop before the upload.
class StoreAccountsBanner extends ConsumerWidget {
  const StoreAccountsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final a = ref.watch(storeAccountsProvider).value;
    if (a == null || a.allConnected) return const SizedBox.shrink();
    return SectionCard(
      key: const Key('storeAccountsBanner'),
      icon: Icons.link_off,
      tone: Tone.attention,
      margin: const EdgeInsets.only(bottom: Gap.md),
      title: l.fxcBannerTitle,
      hint: l.fxcBannerBody,
      children: [
        Gap.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            key: const Key('storeAccountsBannerGo'),
            onPressed: () => context.go('/factory/links'),
            icon: const Icon(Icons.link),
            label: Text(l.fxcConnect),
          ),
        ),
      ],
    );
  }
}

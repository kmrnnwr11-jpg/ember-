import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale.dart';
import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../core/theme_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../ai/settings_screen.dart';

/// Accounts the user connects once and every app then uses. The value is the
/// settings key the connection is saved under.
const _accounts = <(String name, String key, IconData icon)>[
  ('GitHub', 'github_token', Icons.hub_outlined),
  ('Google Play', 'play_service_account', Icons.shop_outlined),
];

final _accountsProvider = FutureProvider.autoDispose<Map<String, bool>>((ref) async {
  await ref.watch(runnerApiProvider.future);
  final store = ref.watch(settingsStoreProvider);
  return {
    for (final (_, key, _) in _accounts) key: ((await store.read(key)) ?? '').trim().isNotEmpty,
  };
});

/// Everything that is set once and not per app, in one place.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider).languageCode;
    final mode = ref.watch(themeModeProvider);
    final session = ref.watch(sessionProvider).value;
    final accounts = ref.watch(_accountsProvider).value ?? const <String, bool>{};

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: PageBody(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.xxl),
        children: [
          SectionCard(
            icon: Icons.translate,
            title: l.language,
            children: [
              Gap.vMd,
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final (code, name) in appLanguages)
                    ChoiceChip(
                      key: Key('language_$code'),
                      label: Text(name),
                      selected: code == locale,
                      onSelected: (_) => ref.read(localeProvider.notifier).set(code),
                    ),
                ],
              ),
            ],
          ),
          SectionCard(
            icon: Icons.contrast,
            title: l.settingsAppearance,
            children: [
              Gap.vMd,
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final (m, label) in [(ThemeMode.system, l.themeSystem), (ThemeMode.light, l.themeLight), (ThemeMode.dark, l.themeDark)])
                    ChoiceChip(
                      key: Key('theme_${m.name}'),
                      label: Text(label),
                      selected: m == mode,
                      onSelected: (_) => ref.read(themeModeProvider.notifier).set(m),
                    ),
                ],
              ),
            ],
          ),
          SectionCard(
            icon: Icons.auto_awesome_outlined,
            title: l.settingsAi,
            hint: l.apiKeysHint,
            children: const [Gap.vMd, AiSettingsSection()],
          ),
          SectionCard(
            icon: Icons.link,
            title: l.settingsAccounts,
            hint: l.settingsAccountsHint,
            children: [
              Gap.vSm,
              for (final (name, key, _) in _accounts)
                StatusRow(
                  done: accounts[key] ?? false,
                  text: (accounts[key] ?? false) ? l.accountConnected(name) : l.accountNotConnected(name),
                  trailing: (accounts[key] ?? false)
                      ? TextButton(
                          key: Key('disconnect_$key'),
                          onPressed: () async {
                            if (!await showConfirm(context, title: '${l.disconnect} $name?', confirmLabel: l.disconnect, destructive: true)) return;
                            await ref.read(settingsStoreProvider).delete(key);
                            ref.invalidate(_accountsProvider);
                          },
                          child: Text(l.disconnect),
                        )
                      : null,
                ),
            ],
          ),
          Card(
            margin: const EdgeInsets.only(top: Gap.md),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: const Key('settingsAdvanced'),
              leading: const Icon(Icons.tune),
              title: Text(l.advanced),
              shape: const RoundedRectangleBorder(),
              collapsedShape: const RoundedRectangleBorder(),
              childrenPadding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.runnerAddress, style: context.text.titleSmall),
                Gap.vXs,
                Text(l.runnerAddressHint, style: context.text.bodySmall),
                Gap.vSm,
                Row(
                  children: [
                    Expanded(child: SelectableText(session?.runnerUrl ?? '—')),
                    if (session != null)
                      IconButton(
                        tooltip: l.copy,
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: session.runnerUrl));
                          showEmberSnack(context, l.copied);
                        },
                      ),
                  ],
                ),
                const Divider(height: Gap.xl),
                const AiProxySwitch(),
              ],
            ),
          ),
          Gap.vXl,
          if (session != null) Text(l.signedInAs(session.email), style: context.text.bodySmall, textAlign: TextAlign.center),
          Gap.vSm,
          Center(
            child: OutlinedButton.icon(
              key: const Key('signOut'),
              onPressed: () => ref.read(sessionProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: Text(l.signOut),
            ),
          ),
        ],
      ),
    );
  }
}

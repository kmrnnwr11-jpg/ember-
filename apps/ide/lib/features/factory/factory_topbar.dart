import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale.dart';
import '../../core/theme_mode.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../../widgets/connection_badge.dart';
import '../../widgets/ember_logo.dart';
import 'connect_cards.dart';
import 'connect_controller.dart';
import 'connect_models.dart';
import 'factory_controller.dart';

/// One place of the Fabbrica: where it goes, how it looks, how it is called.
class FactoryDest {
  const FactoryDest(this.path, this.icon, this.selectedIcon);
  final String path;
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l) => switch (path) {
    '/factory/new' => l.fxNavNew,
    '/factory/needs' => l.fxNavNeeds,
    '/factory/links' => l.fxNavLinks,
    _ => l.fxNavOverview,
  };
}

const factoryDests = [
  FactoryDest('/factory', Icons.dashboard_outlined, Icons.dashboard),
  FactoryDest('/factory/new', Icons.add_circle_outline, Icons.add_circle),
  FactoryDest('/factory/needs', Icons.front_hand_outlined, Icons.front_hand),
  FactoryDest('/factory/links', Icons.link, Icons.link),
];

/// The top of the Fabbrica: where you are and where else you can go, the two
/// store accounts at a glance, pause, and one menu for everything you can choose
/// (your apps, light or dark, language, settings). A thin line under it shows how
/// far the whole factory has got.
class FactoryTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const FactoryTopBar({super.key, required this.location});
  final String location;

  static const double _height = 64;
  static const double _line = 3;

  @override
  Size get preferredSize => const Size.fromHeight(_height + _line);

  int get _index {
    final i = factoryDests.indexWhere((d) => d.path == location);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(factoryProvider).value;
    final accounts = ref.watch(storeAccountsProvider).value;
    final wide = Breakpoints.isMedium(context);
    final needs = data?.needs.length ?? 0;
    final working = data != null && data.summary.total > 0 && data.summary.running + data.summary.queued > 0;

    return AppBar(
      toolbarHeight: _height,
      automaticallyImplyLeading: false,
      leading: BackButton(key: const Key('factoryBack'), onPressed: () => context.go('/projects')),
      titleSpacing: 0,
      title: Row(
        children: [
          const ExcludeSemantics(child: EmberMark(size: 30, animate: false)),
          Gap.hSm,
          // Wide: the title keeps its own width and the tabs get all the rest (two flexible children would split it half and half).
          if (wide) Text(l.fxTitle, maxLines: 1) else Flexible(child: Text(l.fxTitle, overflow: TextOverflow.ellipsis)),
          if (wide) ...[
            const SizedBox(width: Gap.xl),
            // Wider than the room there is: it slides sideways instead of overflowing.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (i, d) in factoryDests.indexed)
                      _TabPill(
                        key: Key('factoryTab$i'),
                        dest: d,
                        selected: i == _index,
                        // Only the place you are in spells its name out until there is plenty of room.
                        showLabel: i == _index || Breakpoints.isExpanded(context),
                        badge: d.path == '/factory/needs' ? needs : 0,
                        onTap: () => context.go(d.path),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        const ConnectionBadge(hideWhenConnected: true),
        if (accounts != null) ...[
          _StoreChip(key: const Key('storeChipGoogle'), icon: Icons.android, name: l.fxcGoogleName, account: accounts.googlePlay),
          _StoreChip(key: const Key('storeChipApple'), icon: Icons.apple, name: l.fxcAppleName, account: accounts.apple),
        ],
        if (data != null) _PauseButton(paused: data.paused, wide: wide, onPressed: () => ref.read(factoryProvider.notifier).setPaused(!data.paused)),
        const _OptionsMenu(),
        Gap.hXs,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_line),
        child: working
            ? Semantics(
                label: l.fxProgress((data.summary.progress * 100).round()),
                child: LinearProgressIndicator(key: const Key('factoryTopProgress'), minHeight: _line, value: data.summary.progress.clamp(0.0, 1.0)),
              )
            : const SizedBox(height: _line, child: Divider(height: 1)),
      ),
    );
  }
}

/// A place in the top bar: icon, and its name when there is room, on a soft pill when it is the one you are in.
class _TabPill extends StatelessWidget {
  const _TabPill({super.key, required this.dest, required this.selected, required this.showLabel, required this.badge, required this.onTap});
  final FactoryDest dest;
  final bool selected;
  final bool showLabel;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = context.scheme;
    final label = dest.label(l);
    final icon = Icon(selected ? dest.selectedIcon : dest.icon, size: 22, color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: Gap.xs),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Tooltip(
          message: label,
          child: Material(
            color: selected ? scheme.primaryContainer : scheme.primaryContainer.withValues(alpha: 0),
            borderRadius: Radii.pillAll,
            child: InkWell(
              borderRadius: Radii.pillAll,
              onTap: onTap,
              child: AnimatedSize(
                duration: Motion.of(context, Motion.fast),
                curve: Motion.curve,
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: showLabel ? Gap.md : Gap.sm, vertical: Gap.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      badge > 0 ? Badge(label: Text('$badge'), child: icon) : icon,
                      if (showLabel) ...[
                        Gap.hSm,
                        Text(label, style: context.text.labelLarge?.copyWith(color: selected ? scheme.onPrimaryContainer : scheme.onSurface, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One store account at a glance: its mark with a dot — green when connected, amber when it cannot be reached, red when it needs connecting again, grey when nothing is connected. A tap goes to the page where it is connected.
class _StoreChip extends StatelessWidget {
  const _StoreChip({super.key, required this.icon, required this.name, required this.account});
  final IconData icon;
  final String name;
  final StoreAccount account;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = context.scheme;
    final dot = switch (account.state) {
      StoreState.connected => context.ember.success,
      StoreState.unreachable => context.ember.warning,
      StoreState.invalid => scheme.error,
      StoreState.missing => scheme.outline,
    };
    final text = '$name · ${storeStateLabel(l, account.state)}';
    return Tooltip(
      message: text,
      child: Semantics(
        button: true,
        label: text,
        excludeSemantics: true,
        onTap: () => context.go('/factory/links'),
        child: InkResponse(
          radius: 24,
          onTap: () => context.go('/factory/links'),
          child: SizedBox.square(
            dimension: kTapTarget,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 24, color: account.connected ? scheme.onSurface : scheme.onSurfaceVariant),
                PositionedDirectional(
                  top: 10,
                  end: 8,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle, border: Border.all(color: scheme.surface, width: 2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.paused, required this.wide, required this.onPressed});
  final bool paused;
  final bool wide;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = paused ? l.fxResume : l.fxPause;
    final icon = Icon(paused ? Icons.play_arrow : Icons.pause);
    if (!wide) return IconButton(key: const Key('factoryPause'), tooltip: label, icon: icon, onPressed: onPressed);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Gap.xs),
      child: FilledButton.tonalIcon(key: const Key('factoryPause'), onPressed: onPressed, icon: icon, label: Text(label)),
    );
  }
}

/// Everything that can be chosen, in one menu: your apps, light or dark, the language, the settings.
class _OptionsMenu extends ConsumerWidget {
  const _OptionsMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider).languageCode;
    PopupMenuItem<String> heading(String text) => PopupMenuItem<String>(
      enabled: false,
      height: 32,
      child: Text(text.toUpperCase(), style: context.text.labelSmall?.copyWith(letterSpacing: 1.2, color: context.scheme.primary, fontWeight: FontWeight.w700)),
    );
    return PopupMenuButton<String>(
      key: const Key('factoryTopMenu'),
      tooltip: l.more,
      icon: const Icon(Icons.tune),
      onSelected: (v) {
        if (v == 'projects') {
          context.go('/projects');
        } else if (v == 'settings') {
          unawaited(context.push('/settings'));
        } else if (v.startsWith('theme:')) {
          unawaited(ref.read(themeModeProvider.notifier).set(ThemeMode.values.byName(v.substring(6))));
        } else if (v.startsWith('lang:')) {
          unawaited(ref.read(localeProvider.notifier).set(v.substring(5)));
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(key: const Key('menuProjects'), value: 'projects', child: ListTile(leading: const Icon(Icons.apps_outlined), title: Text(l.projects), contentPadding: EdgeInsets.zero)),
        const PopupMenuDivider(),
        heading(l.settingsAppearance),
        for (final (m, label) in [(ThemeMode.system, l.themeSystem), (ThemeMode.light, l.themeLight), (ThemeMode.dark, l.themeDark)])
          CheckedPopupMenuItem(key: Key('menuTheme_${m.name}'), value: 'theme:${m.name}', checked: m == mode, child: Text(label)),
        const PopupMenuDivider(),
        heading(l.language),
        for (final (code, name) in appLanguages) CheckedPopupMenuItem(key: Key('menuLang_$code'), value: 'lang:$code', checked: code == locale, child: Text(name)),
        const PopupMenuDivider(),
        PopupMenuItem(key: const Key('menuSettings'), value: 'settings', child: ListTile(leading: const Icon(Icons.settings_outlined), title: Text(l.settings), contentPadding: EdgeInsets.zero)),
      ],
    );
  }
}

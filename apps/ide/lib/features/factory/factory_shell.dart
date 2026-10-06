import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../../widgets/connection_badge.dart';
import 'factory_controller.dart';

class _Dest {
  const _Dest(this.path, this.icon, this.selectedIcon);
  final String path;
  final IconData icon;
  final IconData selectedIcon;
}

const _dests = [
  _Dest('/factory', Icons.dashboard_outlined, Icons.dashboard),
  _Dest('/factory/new', Icons.add_circle_outline, Icons.add_circle),
  _Dest('/factory/needs', Icons.front_hand_outlined, Icons.front_hand),
  _Dest('/factory/links', Icons.link, Icons.link),
];

/// The frame of the Fabbrica: a rail beside the page from 840 px, a bar under
/// it below. The page itself is [child].
class FactoryShell extends ConsumerWidget {
  const FactoryShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  int get _index {
    final i = _dests.indexWhere((d) => d.path == location);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(factoryProvider).value;
    final needs = data?.needs.length ?? 0;
    final labels = [l.fxNavOverview, l.fxNavNew, l.fxNavNeeds, l.fxNavLinks];

    Widget icon(int i, {bool selected = false}) {
      final d = _dests[i];
      final base = Icon(selected ? d.selectedIcon : d.icon);
      // The number of things waiting for the owner, on the "Needs you" entry.
      return i == 2 && needs > 0 ? Badge(label: Text('$needs'), child: base) : base;
    }

    void go(int i) => context.go(_dests[i].path);
    final wide = Breakpoints.isMedium(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/projects')),
        title: Text(l.fxTitle),
        actions: [
          const ConnectionBadge(hideWhenConnected: true),
          if (data != null)
            IconButton(
              key: const Key('factoryPause'),
              tooltip: data.paused ? l.fxResume : l.fxPause,
              icon: Icon(data.paused ? Icons.play_arrow : Icons.pause),
              onPressed: () => ref.read(factoryProvider.notifier).setPaused(!data.paused),
            ),
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          Gap.hXs,
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: go,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final (i, label) in labels.indexed)
                      NavigationRailDestination(
                        icon: icon(i),
                        selectedIcon: icon(i, selected: true),
                        label: Text(label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: go,
              destinations: [
                for (final (i, label) in labels.indexed)
                  NavigationDestination(icon: icon(i), selectedIcon: icon(i, selected: true), label: label),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'factory_controller.dart';
import 'factory_topbar.dart';

/// The frame of the Fabbrica: the top bar always, and from 840 px the places
/// are tabs in it; below that they are a bar under the page, where a thumb reaches.
class FactoryShell extends ConsumerWidget {
  const FactoryShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  int get _index {
    final i = factoryDests.indexWhere((d) => d.path == location);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final needs = ref.watch(factoryProvider).value?.needs.length ?? 0;

    Widget icon(int i, {bool selected = false}) {
      final d = factoryDests[i];
      final base = Icon(selected ? d.selectedIcon : d.icon);
      // The number of things waiting for the owner, on the "Needs you" entry.
      return d.path == '/factory/needs' && needs > 0 ? Badge(label: Text('$needs'), child: base) : base;
    }

    return Scaffold(
      appBar: FactoryTopBar(location: location),
      body: child,
      bottomNavigationBar: Breakpoints.isMedium(context)
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => context.go(factoryDests[i].path),
              destinations: [
                for (final (i, d) in factoryDests.indexed) NavigationDestination(icon: icon(i), selectedIcon: icon(i, selected: true), label: d.label(l)),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_builder.dart';

/// The iPhone side of a finished app: build the IPA, then App Store Connect.
/// Apple only allows the build on a Mac, so elsewhere the card says so plainly
/// instead of letting the build fail deep inside Xcode.
class IosCard extends StatelessWidget {
  const IosCard({super.key, required this.builder});

  final AppBuilder builder;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final needsMac = builder.iosError?.contains('Mac') ?? false;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [const Icon(Icons.phone_iphone), const SizedBox(width: 8), Text(l.iosTitle, style: theme.textTheme.titleMedium)]),
            const SizedBox(height: 4),
            Text(l.iosHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(l.iosAppleAccount, style: theme.textTheme.bodySmall),
            if (builder.iosBuilding) ...[
              const SizedBox(height: 12),
              Row(children: [const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Expanded(child: Text(l.iosBuilding))]),
            ],
            if (builder.iosStatus == 'ready') ...[
              const SizedBox(height: 12),
              Row(children: [Icon(Icons.check_circle, color: theme.colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text(l.iosReady))]),
            ],
            if (builder.iosError != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                needsMac ? l.iosNeedsMac : builder.iosError!,
                style: TextStyle(color: needsMac ? null : theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const Key('buildIos'),
                onPressed: builder.iosBuilding || builder.running ? null : builder.buildIos,
                icon: const Icon(Icons.apple),
                label: Text(l.iosBuild),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Android or iPhone: which store this page is working on.
class PlatformTabs extends StatelessWidget {
  const PlatformTabs({super.key, required this.ios, required this.onChanged});

  final bool ios;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SegmentedButton<bool>(
        key: const Key('platformTabs'),
        segments: [
          ButtonSegment(value: false, icon: const Icon(Icons.android), label: Text(l.platformAndroid)),
          ButtonSegment(value: true, icon: const Icon(Icons.apple), label: Text(l.platformIos)),
        ],
        selected: {ios},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

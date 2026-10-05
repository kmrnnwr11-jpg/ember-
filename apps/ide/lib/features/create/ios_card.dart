import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
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
    final needsMac = builder.iosError?.contains('Mac') ?? false;

    return SectionCard(
      icon: Icons.phone_iphone_outlined,
      title: l.iosTitle,
      hint: l.iosHint,
      children: [
        Gap.vXs,
        Text(l.iosAppleAccount, style: context.text.bodySmall),
        if (builder.iosBuilding) ...[
          Gap.vMd,
          BusyRow(l.iosBuilding),
        ],
        if (builder.iosStatus == 'ready') ...[
          Gap.vMd,
          StatusRow(done: true, text: l.iosReady),
        ],
        if (builder.iosError != null) ...[
          Gap.vMd,
          InlineMessage(needsMac ? l.iosNeedsMac : builder.iosError!, error: !needsMac),
        ],
        Gap.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            key: const Key('buildIos'),
            onPressed: builder.iosBuilding || builder.running ? null : builder.buildIos,
            icon: const Icon(Icons.apple),
            label: Text(l.iosBuild),
          ),
        ),
      ],
    );
  }
}

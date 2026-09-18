import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'app_builder.dart';

/// AdMob: the app ships with Google's test ads; this card collects the real IDs and lets Ember wire them in.
class AdsCard extends StatefulWidget {
  const AdsCard({super.key, required this.builder});
  final AppBuilder builder;

  @override
  State<AdsCard> createState() => _AdsCardState();
}

class _AdsCardState extends State<AdsCard> {
  static final _appIdRe = RegExp(r'^ca-app-pub-\d{16}~\d{10}$');
  static final _unitRe = RegExp(r'^ca-app-pub-\d{16}/\d{10}$');
  final _appId = TextEditingController();
  late final Map<String, TextEditingController> _units = {
    for (final f in const ['banner', 'interstitial', 'rewarded'])
      if (widget.builder.ads?[f] == true) f: TextEditingController(),
  };
  String? _error;

  @override
  void dispose() {
    _appId.dispose();
    for (final c in _units.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Adds ads to an app that was built without them, with Google's test ids first.
  void _addAds() {
    final l = AppLocalizations.of(context);
    widget.builder.improve(
      'Add AdMob ads to this app with the google_mobile_ads package. Use ONLY Google\'s official TEST ad unit ids for now, '
      'in a single file lib/config/ads_config.dart, and set the test application id in AndroidManifest.xml and Info.plist. '
      'Show a banner at the bottom of the main screen and an interstitial after a meaningful action, never on first launch '
      'and never more than once a minute. Initialise the SDK at startup. '
      'End your reply with the line EMBER_ADS: banner,interstitial',
      display: l.adsAddChat,
    );
  }

  void _apply() {
    final l = AppLocalizations.of(context);
    final app = _appId.text.trim();
    final units = {for (final e in _units.entries) e.key: e.value.text.trim()};
    if (!_appIdRe.hasMatch(app) || units.values.any((u) => !_unitRe.hasMatch(u))) {
      setState(() => _error = l.adsInvalid);
      return;
    }
    setState(() => _error = null);
    widget.builder.improve(
      'Replace the AdMob TEST ids with these real ids, in lib/config/ads_config.dart, AndroidManifest.xml and Info.plist. '
      'Keep test ids in debug builds (kDebugMode) and use the real ones in release builds. '
      'App id: $app. ${units.entries.map((e) => '${e.key} ad unit: ${e.value}').join('. ')}.',
      display: l.adsChat,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(l.adsTitle, style: theme.textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 4),
            Text(widget.builder.ads == null ? l.adsAddHint : l.adsHint, style: theme.textTheme.bodySmall),
            if (widget.builder.ads == null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: widget.builder.running ? null : _addAds,
                  icon: const Icon(Icons.campaign),
                  label: Text(l.adsAdd),
                ),
              ),
            ],
            if (widget.builder.ads != null) ...[
              const SizedBox(height: 8),
              Text(l.adsSteps, style: theme.textTheme.bodySmall),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://admob.google.com/v2/apps/list'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l.adsOpenAdmob),
                ),
              ),
              TextField(controller: _appId, decoration: InputDecoration(labelText: l.adsAppId, hintText: 'ca-app-pub-0000000000000000~0000000000', isDense: true, border: const OutlineInputBorder())),
              for (final e in _units.entries) ...[
                const SizedBox(height: 8),
                TextField(controller: e.value, decoration: InputDecoration(labelText: l.adsUnitId(e.key), hintText: 'ca-app-pub-0000000000000000/0000000000', isDense: true, border: const OutlineInputBorder())),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(onPressed: widget.builder.running ? null : _apply, icon: const Icon(Icons.check), label: Text(l.adsApply)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

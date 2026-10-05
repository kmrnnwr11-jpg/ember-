import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
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
  /// One box per ad format. Ember's apps carry all three, so all three are asked
  /// for: an empty one is simply left alone.
  final Map<String, TextEditingController> _units = {
    for (final f in const ['banner', 'interstitial', 'rewarded']) f: TextEditingController(),
  };
  String? _error;

  /// The user said no to ads for this app: stop offering until they reopen it.
  bool _declined = false;

  @override
  void dispose() {
    _appId.dispose();
    for (final c in _units.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// As many ads as the app can carry without Google turning them off.
  ///
  /// Google suspends accounts for accidental clicks and for ads that get in the
  /// way, so the limits below are the line: earn from every screen, never trick
  /// anyone into a tap.
  static const _adsPolicy =
      'Add AdMob ads with the google_mobile_ads package, earning as much as the policy allows and no more. '
      'Use ONLY Google official TEST ad unit ids for now, gathered in one file lib/config/ads_config.dart, '
      'and the test application id in AndroidManifest.xml and Info.plist. Initialise the SDK at startup. '
      'Place: an adaptive banner at the bottom of each main screen; an interstitial after a completed action '
      '(a saved photo, a finished game, a closed detail page). Add a rewarded ad only where the user gets '
      'something for watching it, and never force it. '
      'Respect these limits, which are what keeps an account alive: no ad on the first launch or the splash; '
      'at most one interstitial per minute and never two in a row; keep every ad at least 40 logical pixels away '
      'from buttons, and never under a finger that is about to tap; no ad over content the user is reading or '
      'during a video or a call; never ask anyone to click an ad, and never click them yourself while testing. '
      'End your reply with the line EMBER_ADS: banner,interstitial';

  /// AdMob shows two codes on the same screen, and they are easy to swap: the
  /// app id carries a "~", an ad unit a "/". Put whatever was pasted where it
  /// belongs instead of complaining about it.
  void _sort(String value, TextEditingController typedIn) {
    final id = value.trim();
    if (!id.startsWith('ca-app-pub-')) return;
    final isAppId = id.contains('~');
    if (isAppId && typedIn != _appId) {
      typedIn.clear();
      setState(() => _appId.text = id);
    } else if (!isAppId && typedIn == _appId) {
      final free = _units.values.firstWhere((c) => c.text.trim().isEmpty, orElse: () => _units.values.first);
      _appId.clear();
      setState(() => free.text = id);
    }
  }

  /// Adds ads to an app that was built without them, with Google's test ids first.
  void _addAds() {
    widget.builder.improve(_adsPolicy, display: AppLocalizations.of(context).adsAddChat);
  }

  /// Takes the ads back out, for an app that should not carry them.
  void _removeAds() {
    widget.builder.improve(
      'Remove AdMob from this app completely: the google_mobile_ads dependency, the ads configuration file, '
      'every banner and interstitial, the SDK initialisation and the application id in AndroidManifest.xml and Info.plist. '
      'Leave the app working exactly as before, with the space the banners used given back to the content.',
      display: AppLocalizations.of(context).adsRemoveChat,
    );
  }

  void _apply() {
    final l = AppLocalizations.of(context);
    final app = _appId.text.trim();
    // Only the formats the user actually created in AdMob; the rest keep test ids.
    final units = {
      for (final e in _units.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    };
    if (!_appIdRe.hasMatch(app) || units.isEmpty || units.values.any((u) => !_unitRe.hasMatch(u))) {
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
    return SectionCard(
      icon: Icons.campaign_outlined,
      title: l.adsTitle,
      hint: widget.builder.ads == null ? l.adsAddHint : l.adsHint,
      children: [
        if (widget.builder.ads == null) ...[
          Gap.vMd,
          if (_declined)
            Text(l.adsDeclined, style: context.text.bodySmall)
          else
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                FilledButton.icon(
                  onPressed: widget.builder.running ? null : _addAds,
                  icon: const Icon(Icons.campaign_outlined),
                  label: Text(l.adsYes),
                ),
                OutlinedButton(onPressed: () => setState(() => _declined = true), child: Text(l.adsNo)),
              ],
            ),
        ],
        if (widget.builder.ads != null || !_declined) ...[
          Gap.vSm,
          DefaultTextStyle.merge(style: context.text.bodySmall, child: StepsList.parse(l.adsSteps)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://admob.google.com/v2/apps/list'), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(l.adsOpenAdmob),
            ),
          ),
          TextField(
            controller: _appId,
            onChanged: (v) => _sort(v, _appId),
            decoration: InputDecoration(
              labelText: l.adsAppId,
              hintText: 'ca-app-pub-0000000000000000~0000000000',
              helperText: l.adsAppIdHelp,
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.android, size: 20),
              isDense: true,
            ),
          ),
          for (final e in _units.entries) ...[
            Gap.vMd,
            TextField(
              controller: e.value,
              onChanged: (v) => _sort(v, e.value),
              decoration: InputDecoration(
                labelText: l.adsUnitId(e.key),
                hintText: 'ca-app-pub-0000000000000000/0000000000',
                helperText: l.adsUnitHelp,
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.crop_16_9_outlined, size: 20),
                isDense: true,
              ),
            ),
          ],
          if (_error != null) ...[
            Gap.vSm,
            InlineMessage(_error!, error: true),
          ],
          Gap.vMd,
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              FilledButton.icon(onPressed: widget.builder.running ? null : _apply, icon: const Icon(Icons.check), label: Text(l.adsApply)),
              TextButton(onPressed: widget.builder.running ? null : _removeAds, child: Text(l.adsRemove)),
            ],
          ),
        ],
      ],
    );
  }
}

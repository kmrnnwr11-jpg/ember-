import 'package:flutter/material.dart';

import 'package:ide_core/ide_core.dart' show RunnerException;

import '../../core/runner_api.dart';
import '../../l10n/app_localizations.dart';

/// A Play Store app the user wants to take as a model.
class ReferenceApp {
  const ReferenceApp({required this.id, required this.title, required this.developer, required this.icon, required this.url, this.summary = '', this.description = ''});

  factory ReferenceApp.fromJson(Map<String, dynamic> j) => ReferenceApp(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    developer: j['developer'] as String? ?? '',
    icon: j['icon'] as String? ?? '',
    url: j['url'] as String? ?? '',
    summary: j['summary'] as String? ?? '',
    description: j['description'] as String? ?? '',
  );

  final String id;
  final String title;
  final String developer;
  final String icon;
  final String url;
  final String summary;
  final String description;

  /// Instructions appended to the build/mockup prompt (hidden from the chat).
  String brief() => '''


REFERENCE APP — the user wants an app like this Play Store app. Study its listing below and build the same complete product: every feature, screen, flow and user role it describes, working for real (not placeholders). Use your own app name, branding, texts and graphics: never copy its name, logo, trademarks, screenshots or description text.
Name: $title${developer.isEmpty ? '' : ' (by $developer)'}
Play Store: $url
Listing:
$description

If that app is free and ad-supported, this one earns the same way: add AdMob with google_mobile_ads using Google's TEST ad unit ids, a banner on the main screen and an interstitial after a completed action — never on first launch, never more than once a minute, never next to a button the user is about to press. Then end your reply with the line EMBER_ADS: banner,interstitial''';
}

/// Detects "an app like X" in a request and returns X, or a Play Store id from a link.
String? referenceQuery(String prompt) {
  final link = RegExp(r'play\.google\.com/store/apps/details\?id=([A-Za-z][\w.]+)').firstMatch(prompt);
  if (link != null) return 'id:${link.group(1)}';
  final m = RegExp(
    r"(?:\b(?:come|simile\s+a|uguale\s+a|identica\s+a|clone\s+di|copia\s+di|stile|like|similar\s+to|same\s+as|clone\s+of|como|parecida\s+a|comme|semblable\s+à|مثل)\s+)(?:(?:l'|la\s+|il\s+|lo\s+|the\s+|an?\s+|la\s+app\s+)?(?:app(?:licazione)?\s+)?)([\p{L}\p{N}][\p{L}\p{N} &'.+-]{1,40})",
    caseSensitive: false,
    unicode: true,
  ).firstMatch(prompt);
  if (m == null) return null;
  // Stop at the words that start the rest of the sentence.
  final stop = RegExp(
    r"\s+(?:che|con|su|sul|per|e|ma|dove|in|di|del|della|nel|that|with|on|for|and|but|where|in|of|que|con|en|para|y|qui|avec|sur|pour|et)\b.*$",
    caseSensitive: false,
    unicode: true,
  );
  final name = m.group(1)!.replaceFirst(stop, '').replaceAll(RegExp(r'[.,;:!?]+$'), '').trim();
  const generic = {'questa', 'quella', 'this', 'that', 'prima', 'before', 'sopra', 'above', 'un', 'una', 'a', 'app'};
  if (name.length < 2 || generic.contains(name.toLowerCase())) return null;
  return name;
}

/// Looks the reference up on the Play Store and lets the user confirm which app they mean.
/// Returns null when there is no reference or the user picks "none of these".
Future<ReferenceApp?> pickReferenceApp(BuildContext context, RunnerApi api, String prompt) async {
  final query = referenceQuery(prompt);
  if (query == null) return null;
  final l = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (query.startsWith('id:')) {
      return ReferenceApp.fromJson(await api.playApp(query.substring(3), lang: lang));
    }
    messenger.showSnackBar(SnackBar(content: Text(l.researchingApp(query)), duration: const Duration(seconds: 3)));
    final found = await api.searchPlayApps(query, lang: lang);
    if (found.isEmpty || !context.mounted) return null;
    final picked = await showModalBottomSheet<ReferenceApp>(
      context: context,
      isScrollControlled: true,
      builder: (d) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(l.pickReferenceApp, style: Theme.of(d).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(l.pickReferenceAppHint, style: Theme.of(d).textTheme.bodySmall),
            ),
            for (final a in found.map(ReferenceApp.fromJson))
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: a.icon.isEmpty
                      ? const SizedBox.square(dimension: 44, child: Icon(Icons.apps))
                      : Image.network(a.icon, width: 44, height: 44, errorBuilder: (_, _, _) => const Icon(Icons.apps)),
                ),
                title: Text(a.title),
                subtitle: Text(a.developer.isEmpty ? a.summary : '${a.developer} · ${a.summary}', maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(d, a),
              ),
            TextButton(onPressed: () => Navigator.pop(d), child: Text(l.referenceNone)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return null;
    return ReferenceApp.fromJson(await api.playApp(picked.id, lang: lang));
  } on RunnerException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.error(e.message))));
    return null;
  }
}

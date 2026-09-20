import 'package:flutter/material.dart';

import 'package:ide_core/ide_core.dart' show RunnerException;

import '../../core/runner_api.dart';
import '../../l10n/app_localizations.dart';

/// A Play Store app the user wants to take as a model.
class ReferenceApp {
  const ReferenceApp({
    required this.id,
    required this.title,
    required this.developer,
    required this.icon,
    required this.url,
    this.summary = '',
    this.description = '',
    this.ads = false,
    this.purchases = false,
    this.priceRange = '',
  });

  factory ReferenceApp.fromJson(Map<String, dynamic> j) {
    final money = (j['money'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ReferenceApp(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      developer: j['developer'] as String? ?? '',
      icon: j['icon'] as String? ?? '',
      url: j['url'] as String? ?? '',
      summary: j['summary'] as String? ?? '',
      description: j['description'] as String? ?? '',
      ads: money['ads'] == true,
      purchases: money['purchases'] == true,
      priceRange: '${money['priceRange'] ?? ''}',
    );
  }

  final String id;
  final String title;
  final String developer;
  final String icon;
  final String url;
  final String summary;
  final String description;

  /// How the model app earns, as its Play Store listing declares it.
  final bool ads;
  final bool purchases;
  final String priceRange;

  /// The same way of earning, written as an instruction for the engine.
  String get _money {
    final parts = <String>[];
    if (ads) {
      parts.add(
        'That app earns from ads, so this one does too: add google_mobile_ads with Google TEST ad unit ids — a banner on the main screens, '
        'an interstitial after a completed action, and a rewarded ad wherever the user can gain something by watching one. '
        'Never on first launch, at most one interstitial a minute, never under a button the user is about to press.',
      );
    }
    if (purchases) {
      parts.add(
        'That app also sells things${priceRange.isEmpty ? '' : ' ($priceRange)'}, so add in_app_purchase with the products that fit it — '
        'typically removing the ads, and a subscription for the extras. Declare each product with EMBER_PRODUCTS.',
      );
    }
    if (ads) parts.add('End your reply with the line EMBER_ADS: banner,interstitial,rewarded');
    return parts.isEmpty
        ? 'That app shows no ads and sells nothing, so leave this one free of both.'
        : parts.join('\n');
  }

  /// Every subject the listing names, in its own order: "Alphabets: …",
  /// "• Puzzles", "- Timer". This is the checklist the built app must cover;
  /// without it an engine copies the first few and calls the app done.
  List<String> topics() {
    final out = <String>[];
    for (final raw in description.split('\n')) {
      final line = raw.trim().replaceFirst(RegExp(r'^[•\-*✓✔●▪️👉👍🔹🎯⭐️\d.)]+\s*'), '').trim();
      if (line.length < 3 || line.length > 120) continue;
      // A subject reads as "Name: what it does", or as a short bullet on its own.
      final head = RegExp(r'^([\p{L}\p{N}][\p{L}\p{N} &/+-]{2,40}):', unicode: true).firstMatch(line);
      final name = head?.group(1)?.trim() ?? (raw.trimLeft().startsWith(RegExp(r'[•\-*✓✔●▪️]')) ? line.split(RegExp(r'[.:;]')).first.trim() : null);
      if (name == null || name.length < 3) continue;
      if (!out.any((t) => t.toLowerCase() == name.toLowerCase())) out.add(name);
    }
    return out.take(30).toList();
  }

  /// "over 150 games", "50+ filters": the size the listing promises.
  String get _size {
    final m = RegExp(r'(?:over|more than|oltre|più di|más de|plus de)\s*([\d.,]+)\s*([\p{L}]+)', unicode: true, caseSensitive: false).firstMatch(description) ??
        RegExp(r'([\d.,]{2,6})\+?\s*(games|giochi|levels|livelli|filters|filtri|effects|effetti|stickers|templates|modelli|tools|strumenti|sounds|suoni)', unicode: true, caseSensitive: false).firstMatch(description);
    return m == null ? '' : '${m.group(1)} ${m.group(2)}';
  }

  /// Apps for small children look nothing like apps for grown-ups, and a
  /// listing says plainly which one it is.
  bool get isForKids => RegExp(
        r'\b(kids?|toddlers?|preschool|kindergarten|children|nursery|baby|babies|bambin\w*|infanzia|prescolare|niños|enfants|kinder)\b',
        caseSensitive: false,
      ).hasMatch('$title $description');

  /// Who the app is for, read from its own listing. What a banking app must
  /// look like and what a toddler's app must look like have nothing in common,
  /// and the mockups have to belong to the same world as the app being copied.
  String get audience {
    final text = '$title $description'.toLowerCase();
    bool has(String words) => RegExp('\\b(?:$words)\\b', caseSensitive: false).hasMatch(text);
    if (isForKids) return 'kids';
    if (has('game|games|puzzle|arcade|gioco|giochi|juego|jeu|level|levels')) return 'game';
    if (has('bank|banking|invoice|tax|isee|finance|financial|wallet|payment|fattur\\w*|conto|business|crm|enterprise')) return 'serious';
    if (has('photo|camera|video|editor|filter|filtri|collage|selfie|beauty|reel')) return 'creative';
    if (has('dating|chat|match|friends|incontri|social|community|profile')) return 'social';
    if (has('fitness|workout|meditation|health|diet|yoga|salute|benessere|sleep')) return 'calm';
    return 'general';
  }

  /// How the mockups must look to belong to the same world as the reference.
  /// The link the user pasted decides the look, not a generic style list.
  String visualDirection() {
    final world = switch (audience) {
      'kids' =>
        'This is an app for small children, so it must look like one: a home screen of big full-colour tiles, '
            'each tile a different strong colour with a drawn illustration inside and its name on a coloured band. '
            'Drawn backgrounds (sky, meadow, ice), a friendly animal mascot on every screen, fat rounded letters and '
            'numbers, buttons a three-year-old can hit. Draw people, animals and objects as inline SVG illustrations '
            'with outlines and flat colour — not line icons, not emoji. No white minimalism, no thin lines, no small '
            'grey text, no tidy adult dashboard.',
      'game' =>
        'This is a game: a playful screen, big play buttons, scores, coins, levels and rewards on show, drawn artwork '
            'and characters rather than icons, deep saturated colours, no business-app layout.',
      'serious' =>
        'This is a money/work app: sober and trustworthy, clear figures, strong hierarchy, restrained palette, '
            'tables and cards that read at a glance, nothing cartoonish.',
      'creative' =>
        'This is a photo/video app: dark working surface so the picture is the brightest thing on screen, thumbnails '
            'and filter strips, bold controls, colour used as accent only.',
      'social' =>
        'This is a people app: faces and profile pictures fill the screen, big cards, rounded avatars, warm accents, '
            'chat bubbles and prominent action buttons.',
      'calm' => 'This is a health/wellbeing app: calm and airy, soft palette, breathing room, gentle progress rings and charts.',
      _ => '',
    };
    if (world.isEmpty && description.trim().isEmpty) return '';
    return '''
AUDIENCE: $audience
THE MOCKUPS MUST LOOK LIKE THE APP BEING COPIED — the user pasted its Play Store link, so its world sets the look.
${world.isEmpty ? '' : '$world\n'}Read the listing below and design for the same people, the same job and the same feel: the same kind of home screen, the same amount of colour, the same size of buttons, the same kind of imagery.
Use your own palette, your own wording and your own drawings: same world, not a copy.
The app being copied: $title${developer.isEmpty ? '' : ' by $developer'}
$description''';
  }

  /// Instructions appended to the build/mockup prompt (hidden from the chat).
  String brief() {
    final list = topics();
    final checklist = list.isEmpty
        ? ''
        : '''

EVERY SUBJECT THE LISTING NAMES — build them all, none left out (${list.length}):
${[for (var i = 0; i < list.length; i++) '${i + 1}. ${list[i]}'].join('\n')}
Each one gets its own screen reachable from the home screen, with real content and at least two things to do in it (learn / play, browse / use), not a placeholder and not a screen that only shows a title.
If the work is long, still cover them all: fewer frills per subject, never a missing subject.''';
    final size = _size.isEmpty ? '' : '\nThat app advertises $_size: aim for that order of magnitude of real content, not three examples per subject.';

    return '''


REFERENCE APP — the user wants this Play Store app rebuilt. Match it feature by feature: the same subjects, the same screens, the same order of the screens, the same way of moving between them, all working for real (not placeholders).
Name: $title${developer.isEmpty ? '' : ' (by $developer)'}
Play Store: $url
Listing:
$description$checklist$size

LOOK — an app people pay attention to is drawn, not typed:
- Draw the pictures in code: CustomPainter / shapes / gradients, or inline SVG-like vector paths. Give every item its own drawing.
- Emoji may season a label, never stand in for the artwork: a screen whose content is a row of emoji is a failed screen.
- No downloaded images and no network pictures: everything ships inside the app.
- Sound and speech where the reference has them (flutter_tts for speech), with a way to turn them off.
- Movement where the reference has movement: if its screens are animated, animate yours — characters that react to a tap, things that slide, bounce, pop and celebrate a right answer. A still screen where the reference moves is not the same app.
- The screenshots of the reference are saved in the project folder `reference/`: look at every one of them and rebuild what they show — the layout, the order of the screens, what sits where, how many items a screen holds.

STAYING LEGAL — Google removes copies and can close the developer account:
- Your own app name, your own icon, your own colours, your own wording. Never the reference's name, logo, characters, screenshots or description text, not even translated.
- Same purpose and same features, different skin: pick a different colour palette and a different mascot/illustration style, and lay out the home screen your own way. Around 5% different by design, 100% the same usefulness.
- Never mention the reference app, its developer or its brand anywhere in the app, its store listing or its code.

HOW IT EARNS — copy this too, it is part of the app:
$_money''';
  }
}

/// A website the user wants turned into an app, read from its own pages.
class ReferenceSite {
  const ReferenceSite({
    required this.url,
    required this.title,
    required this.description,
    this.features = const [],
    this.pages = const [],
    this.prices = const [],
    this.colors = const [],
    this.shotsSaved = 0,
  });

  factory ReferenceSite.fromJson(Map<String, dynamic> j, {int shotsSaved = 0}) {
    final site = (j['site'] as Map?)?.cast<String, dynamic>() ?? j;
    List<String> list(String key) => [for (final v in (site[key] as List? ?? const [])) '$v'];
    return ReferenceSite(
      url: '${site['url'] ?? ''}',
      title: '${site['title'] ?? ''}',
      description: '${site['description'] ?? ''}',
      features: list('features'),
      prices: list('prices'),
      colors: list('colors'),
      pages: [
        for (final p in (site['pages'] as List? ?? const []))
          (url: '${(p as Map)['url']}', label: '${p['label']}'),
      ],
      shotsSaved: (j['shotsSaved'] as num?)?.toInt() ?? shotsSaved,
    );
  }

  final String url;
  final String title;
  final String description;

  /// What the site says it does: headings, buttons, tool names.
  final List<String> features;
  final List<({String url, String label})> pages;
  final List<String> prices;
  final List<String> colors;

  /// Pages photographed into the project's `reference/` folder.
  final int shotsSaved;

  /// Instructions appended to the build prompt: the whole site, as an app.
  String brief() {
    final tools = <String>{
      for (final f in features.take(25)) '- $f',
      for (final p in pages.take(20)) '- ${p.label}',
    }.toList();

    return '''


REFERENCE WEBSITE — the user wants this website rebuilt as a mobile app. Everything the site does, the app does, working offline on the phone where that is possible.
Site: ${title.isEmpty ? url : title}
Address: $url
${description.isEmpty ? '' : 'What it says it is: $description\n'}
EVERYTHING IT OFFERS — build them all, none left out (${tools.length}):
${tools.join('\n')}
Each of these is a real, working feature with its own screen, not a menu entry that opens a placeholder. A tool that processes files does the processing on the phone, with a native file picker, progress, a result the user can save or share, and an honest message when something cannot be done on a phone.
${prices.isEmpty ? '' : 'HOW IT EARNS — the site charges ${prices.take(4).join(', ')}: put the same kind of free tier and paid upgrade in the app, with in_app_purchase and EMBER_PRODUCTS.\n'}${shotsSaved > 0 ? 'The site\'s pages are photographed in the project folder `reference/`: look at every one and rebuild what they show — the order of things, what sits where, how a task starts and ends.\n' : ''}${colors.isEmpty ? '' : 'Its colours are ${colors.take(4).join(', ')}: take them as a starting point and depart from them — your own palette, near enough to feel related, different enough to be yours.\n'}
STAYING LEGAL — same purpose, your own skin: your own app name, your own logo, your own wording. Never the site's name, logo, trademarks or copied text, and never claim to be them or to be official.''';
  }
}

/// A website link in the request (not a Play Store one), or null.
String? referenceSiteUrl(String prompt) {
  final m = RegExp(r'https?://[^\s<>"]+').firstMatch(prompt);
  final url = m?.group(0);
  if (url == null || url.contains('play.google.com') || url.contains('apps.apple.com')) return null;
  return url;
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

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/runner_api.dart';
import '../../l10n/app_localizations.dart';
import '../mockups/mockup_controller.dart' show CompleteText;
import 'listing_ai.dart';
import 'listing_languages.dart';

/// What Google Play actually received, in plain words.
String uploadSummary(AppLocalizations l, Map<String, dynamic> result) {
  final u = (result['uploaded'] as Map?) ?? const {};
  final shots = (u['screenshots'] as num?)?.toInt() ?? 0;
  return [
    u['listing'] == true ? l.upListing((u['languages'] as List? ?? const []).join(', ')) : l.upNoListing,
    u['icon'] == true ? l.upIcon : l.upNoIcon,
    u['featureGraphic'] == true ? l.upFeature : l.upNoFeature,
    shots > 0 ? l.upShots(shots) : l.upNoShots,
  ].join('\n');
}

/// The publishing work of one app, alive as long as Ember runs. Writing the
/// listing, translating it into every language and uploading it take minutes:
/// the user goes to another screen meanwhile, and the work must not stop
/// there. The screen shows the job and gives it its texts; reopened, it shows
/// where the job is.
class PublishJob extends ChangeNotifier {
  PublishJob._();

  static final Map<String, PublishJob> _all = {};
  static PublishJob of(String projectId) => _all.putIfAbsent(projectId, PublishJob._);

  final Set<String> languages = {...playStoreLanguages.keys};

  /// The listing in each language, as {language: {title, shortDescription, fullDescription}}.
  Map<String, Map<String, String>> translations = {};

  /// The English text the translations were written from. When the title or
  /// a description changes, the translations still carry the old words (the
  /// old app name in 82 languages): they are written again.
  String? translatedFrom;
  bool generating = false;
  bool translating = false;
  bool publishing = false;
  String? error;
  Map<String, dynamic>? result;

  /// The saved listing was read into this job once; later opens keep the job's.
  bool loaded = false;

  /// Taken while the screen was open, used after it closed.
  RunnerApi? api;
  CompleteText? complete;

  bool get busy => generating || translating || publishing;

  /// Whether the translations were written from an English text that is no
  /// longer the one on screen ([source]).
  bool staleFor(String source) => translations.isNotEmpty && translatedFrom != null && translatedFrom != source;

  /// Reads the languages and their pages as they were saved with the listing.
  /// [source] and [title] are the English text on screen now.
  void loadSaved(String saved, {required String source, required String title}) {
    if (saved.isEmpty) return;
    try {
      final j = jsonDecode(saved) as Map<String, dynamic>;
      final langs = (j['languages'] as List?)?.cast<String>();
      if (langs != null) {
        // A listing saved when Ember offered fewer languages gets the new
        // ones too (they are translated next time); a language the user
        // switched off among those offered back then stays off.
        languages
          ..clear()
          ..addAll(langs)
          ..addAll(playStoreLanguages.keys.where((l) => !playLanguagesOfferedFirst.contains(l)));
      }
      translations = {
        for (final e in ((j['pages'] as Map?) ?? const {}).entries) '${e.key}': (e.value as Map).map((k, v) => MapEntry('$k', '$v')),
      };
      // Saved before Ember remembered the source: take them as matching it.
      translatedFrom = j['from'] as String? ?? source;
      // The name is the same in every language (older listings translated it).
      final name = title.trim();
      if (name.isNotEmpty) {
        for (final page in translations.values) {
          page['title'] = name;
        }
      }
    } catch (_) {
      // An unreadable old value just means translating again.
    }
  }

  /// What is saved with the listing, read back by [loadSaved].
  String savedForm() => jsonEncode({'languages': languages.toList(), 'pages': translations, 'from': translatedFrom});

  /// What Google Play is sent: the English page, the page of every language
  /// that is on and written, and the new version unless [listingOnly].
  Map<String, dynamic> uploadRequest({
    required String serviceAccount,
    required String track,
    required String title,
    required String short,
    required String full,
    required String notes,
    required String email,
    required bool listingOnly,
  }) => {
    'serviceAccount': serviceAccount,
    'track': track,
    'status': 'completed',
    'listing': {
      'language': playMainLanguage,
      if (title.isNotEmpty) 'title': title,
      if (short.isNotEmpty) 'shortDescription': short,
      if (full.isNotEmpty) 'fullDescription': full,
    },
    'translations': [
      for (final lang in languages)
        if (translations[lang] != null) {'language': lang, ...fitToStore(translations[lang]!)},
    ],
    if (notes.isNotEmpty) 'releaseNotes': {'language': playMainLanguage, 'text': notes},
    if (email.isNotEmpty) 'contactEmail': email,
    // Only the store page of an app already on Google Play: no new version.
    if (listingOnly) 'listingOnly': true,
  };

  void changed() => notifyListeners();
}

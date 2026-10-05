import 'dart:convert';

import '../../../l10n/app_localizations.dart';

/// The listing the user already wrote for Google, in Apple's words: the main
/// page, the translated ones and the privacy address. [state] is the store
/// state of the project as the Runner returns it.
(Map<String, dynamic>?, List<Map<String, dynamic>>, String?) appStoreListing(Map<String, dynamic> state) {
  final listing = state['listing'] as Map<String, dynamic>?;
  if (listing == null) return (null, <Map<String, dynamic>>[], null);

  Map<String, dynamic> page(String language, Map<String, dynamic> from) => {
    'language': language,
    'title': '${from['title'] ?? ''}',
    'subtitle': '${from['shortDescription'] ?? ''}',
    'description': '${from['fullDescription'] ?? ''}',
    'releaseNotes': '${from['releaseNotes'] ?? ''}',
  };

  final main = page('en-US', listing); // the main listing is written in English, like on Play
  final others = <Map<String, dynamic>>[];
  try {
    final j = jsonDecode('${listing['translations'] ?? ''}') as Map<String, dynamic>;
    for (final e in ((j['pages'] as Map?) ?? const {}).entries) {
      others.add(page('${e.key}', (e.value as Map).cast<String, dynamic>()));
    }
  } catch (_) {
    // No translations saved yet: the main language is enough.
  }
  return (main, others, '${listing['privacyUrl'] ?? ''}');
}

/// What the one-press publish sends to the Runner. Empty fields are left out,
/// so Apple keeps what it already has.
Map<String, dynamic> appStorePublishRequest({
  required Map<String, dynamic> state,
  required bool uploadBuild,
  required bool submit,
  required String? category,
  required bool free,
  required bool screenshots,
  required String marketingUrl,
  required String reviewEmail,
  required String reviewPhone,
  required String reviewNotes,
  required String demoUser,
  required String demoPassword,
}) {
  final (listing, translations, privacyUrl) = appStoreListing(state);
  final review = <String, dynamic>{
    if (reviewEmail.trim().isNotEmpty) 'email': reviewEmail.trim(),
    if (reviewPhone.trim().isNotEmpty) 'phone': reviewPhone.trim(),
    if (reviewNotes.trim().isNotEmpty) 'notes': reviewNotes.trim(),
    if (demoUser.trim().isNotEmpty) 'demoUser': demoUser.trim(),
    if (demoPassword.trim().isNotEmpty) 'demoPassword': demoPassword.trim(),
  };
  return {
    'listing': ?listing,
    if (translations.isNotEmpty) 'translations': translations,
    'privacyPolicyUrl': ?(privacyUrl?.isNotEmpty ?? false ? privacyUrl : null),
    'uploadBuild': uploadBuild,
    'submit': submit,
    'category': ?category,
    'free': free,
    'screenshots': screenshots,
    if (marketingUrl.trim().startsWith('https://')) 'marketingUrl': marketingUrl.trim(),
    if (review.isNotEmpty) 'review': review,
  };
}

/// A short, human list of the chores Ember filled on Apple in one publish.
List<String> appStoreDoneSummary(AppLocalizations l, Map<String, dynamic> res) {
  final out = <String>[];
  if (res['exportCompliance'] == true) out.add(l.asDoneExport);
  if (res['ageRated'] == true) out.add(l.asDoneAge);
  if (res['categorized'] == true) out.add(l.asDoneCategory);
  if (res['reviewInfoSet'] == true) out.add(l.asDoneReview);
  if (res['pricedFree'] == true) out.add(l.asDoneFree);
  if (res['privacy'] is Map && (res['privacy'] as Map)['categories'] != null) out.add(l.asDonePrivacy);
  final shots = res['screenshots'];
  if (shots is Map && shots.isNotEmpty) {
    final total = shots.values.fold<int>(0, (a, b) => a + (b is int ? b : 0));
    if (total > 0) out.add(l.asDoneShots(total));
  }
  return out;
}

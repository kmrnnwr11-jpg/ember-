import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../ai/ai_settings.dart';
import '../mockups/mockup_controller.dart' show CompleteText, apiCompleter, claudeCodeCompleter;

/// Google's limits are hard: a translated title of 31 characters stops the
/// whole upload. Better a title one word shorter than a publish that fails.
Map<String, String> fitToStore(Map<String, String> page) {
  String cut(String? text, int max) {
    final String t = (text ?? '').trim();
    if (t.length <= max) return t;
    final String short = t.substring(0, max);
    final int space = short.lastIndexOf(' ');
    return (space > max - 12 ? short.substring(0, space) : short).trim();
  }

  return <String, String>{
    'title': cut(page['title'], 30),
    'shortDescription': cut(page['shortDescription'], 80),
    'fullDescription': cut(page['fullDescription'], 4000),
  };
}

const storeKitSystemPrompt = '''
You prepare everything needed to publish an Android app on Google Play, for a non-technical owner.
Reply with ONE JSON object only (no markdown fences), with these keys.

THE STORE TEXTS ARE WRITTEN IN ENGLISH. The title, the short description, the
full description and the release notes are English and nothing else: English is
the listing's main language and what Google shows wherever there is no page in
the reader's own. Do not write them in the owner's language, however the app
itself is written and whatever language this instruction is answered in — a
listing that arrives in the wrong language has to be rewritten by hand before
it can be published.
Only the guides and the privacy policy follow the owner's language.
{
 "title": "max 30 chars",
 "shortDescription": "max 80 chars",
 "fullDescription": "max 4000 chars, engaging, with feature bullets using • and line breaks",
 "releaseNotes": "max 500 chars",
 "privacyPolicyMarkdown": "complete privacy policy in Markdown (who we are placeholder [NOME TITOLARE] and [EMAIL], data collected, purposes, third-party services actually used by the app e.g. Firebase/Google Sign-In/Agora, retention, user rights under GDPR, contacts, date)",
 "dataSafetyGuide": "Markdown checklist answering Play Console 'Data safety' questions based on what the app really uses: data types collected/shared, purposes, encryption in transit, account deletion method",
 "contentRatingGuide": "Markdown list of suggested answers for the IARC content rating questionnaire",
 "otherDeclarationsGuide": "Markdown: target audience and content, ads (yes/no), app access instructions for reviewers if login is required (test account placeholder), government/financial/health declarations if relevant"
}
Be accurate: only declare data the app actually handles based on the description and files. Never invent certifications.''';

const translateSystemPrompt = 'You translate app store listings for Google Play. You answer with JSON only.';

/// The model answered with something that is not the JSON it was asked for.
/// The screen says so in the user's language.
class BadAiAnswer implements Exception {
  const BadAiAnswer();

  @override
  String toString() => 'BadAiAnswer';
}

/// The JSON object inside a model's answer, whatever it wrote around it.
Map<String, dynamic> aiJsonObject(String answer) {
  final text = answer.trim();
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) throw const BadAiAnswer();
  return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
}

/// What the writer is asked for one app.
///
/// The name is stated as a fact before anything else: left to infer it
/// from the package, the writer invented one from the folder name and an
/// app called PrintGo was published as StampaFacile.
/// A title the user typed is theirs: the writer keeps it word for word
/// and names the app as it does. Generating again used to put the
/// project's name back over it.
String storeKitPrompt({required String typedTitle, required String? appLabel, required String? packageName, required String appDescription}) {
  final named = typedTitle.isNotEmpty ? typedTitle.split(':').first.trim() : (appLabel ?? '').trim();
  final naming = named.isEmpty
      ? ''
      : 'The app is called "$named". Use exactly this name in the title '
          'and wherever the listing names the app. Do not translate it, '
          'shorten it, or invent another one.\n'
          '${typedTitle.isNotEmpty ? 'The store title is exactly "$typedTitle": return it unchanged as "title".\n' : ''}\n';
  return '${naming}Package name: $packageName\n\nApp description and features:\n$appDescription';
}

/// How many languages one call translates.
///
/// A few languages per call: 25 full listings in one answer are far past
/// what a model writes in one go, and one cut answer lost them all.
const translateGroupSize = 4;

/// How many of those calls run at the same time.
const translateGroupsAtOnce = 3;

/// [wanted] in groups of [translateGroupSize].
List<List<String>> translateBatches(List<String> wanted) {
  const group = translateGroupSize;
  return [for (var i = 0; i < wanted.length; i += group) wanted.sublist(i, i + group > wanted.length ? wanted.length : i + group)];
}

String translatePrompt({required List<String> langs, required String title, required String short, required String full}) => [
  'Translate this Google Play store listing into these languages: ${langs.join(', ')}.',
  'The title is the app name: it stays exactly "$title" in every language. Translate only the descriptions.',
  'Limits: shortDescription 80 characters, fullDescription 4000. Write naturally for each market, not word for word.',
  'Reply with JSON only: {"<language code>": {"shortDescription": "...", "fullDescription": "..."}}',
  '',
  'shortDescription: $short',
  'fullDescription:',
  full,
].join('\n');

/// The pages a translation call wrote, for the languages it was asked for.
Map<String, Map<String, String>> translatedPages(String answer, {required List<String> langs, required String title}) {
  final j = aiJsonObject(answer);
  final pages = <String, Map<String, String>>{};
  for (final entry in j.entries) {
    if (!langs.contains(entry.key)) continue;
    final v = (entry.value as Map).cast<String, dynamic>();
    // The name is the same on every store page: the one the user wrote.
    pages[entry.key] = {
      'title': title,
      'shortDescription': '${v['shortDescription'] ?? ''}',
      'fullDescription': '${v['fullDescription'] ?? ''}',
    };
  }
  return pages;
}

/// Whether this app was built with ads and with purchases, as recorded by
/// the build itself rather than guessed from its description.
Future<({bool ads, bool purchases})> whatWasBuilt(String projectId) async {
  try {
    final raw = await Settings.instance.read('ember_session_$projectId');
    if (raw == null) return (ads: false, purchases: false);
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final ads = m['ads'];
    final products = m['products'];
    return (
      ads: ads is Map && ads.values.any((v) => v == true),
      purchases: products is List && products.isNotEmpty,
    );
  } catch (_) {
    return (ads: false, purchases: false);
  }
}

/// The AI that writes and translates the listing: Claude Code when the
/// computer has it, otherwise the first fast model the user can use.
/// [noAi] is what to say when there is none.
Future<CompleteText> listingCompleter(WidgetRef ref, {required String noAi}) async {
  final health = await ref.read(runnerHealthProvider.future);
  if ((health['engines'] as Map?)?['claudeCode'] == true) {
    final socket = ref.read(runnerSocketProvider);
    return claudeCodeCompleter((t, p) => socket.request(t, p, timeout: const Duration(minutes: 6)));
  }
  final settings = await ref.read(aiSettingsProvider.future);
  final catalog = await ref.read(aiCatalogProvider.future);
  final model = catalog.firstWhere(
    (m) => m.tags.contains('fast') && canUseProvider(settings, m.provider, health),
    orElse: () => catalog.firstWhere((m) => canUseProvider(settings, m.provider, health), orElse: () => throw AiException(noAi)),
  );
  return apiCompleter(ref.read(aiProviderFactory), model);
}

import 'dart:convert';

import '../mockups/mockup_controller.dart' show PanelMember;

/// The four models agree on how the app should be designed, before a line of
/// it is written.
///
/// They already drew the mockups together and the icon together, but the app
/// itself was then written by one engine alone, with nobody having said
/// anything about its screens, its templates or its colours until it was
/// finished — and by then a defect costs a rebuild. Here they say it first,
/// and what they agree on goes into the instructions the engine builds from.
///
/// Writing the code stays with one engine: several models editing the same
/// files is how you get an app that contradicts itself.
const _system = '''
You are a senior product designer advising the engineer who is about to build a mobile app, and you answer with JSON only.
Give instructions that change what gets built, not encouragement. Each rule must be something the engineer either does or
does not do, and a reviewer could check afterwards.
Cover, in this order of importance:
1. VARIETY where the app offers choices: if it ships templates, themes or styles, say how they must differ in STRUCTURE —
   layout, where things sit, what is emphasised — not merely in colour. "N layouts x M palettes" presented as N*M designs is
   the defect to forbid by name.
2. The screens the app needs, and what must be on each one.
3. Colour: the one colour this subject owns, how it is used, what the neutrals are.
4. Typography: sizes and weights that make a hierarchy, not one size everywhere.
5. What would make it look built in 2026 rather than 2018.
Say nothing about frameworks, packages or file layout: that is the engineer's business.''';

String _ask(String request, String reference) => '''
The app to be built:
$request
${reference.trim().isEmpty ? '' : '\nWhat it is modelled on:\n${reference.trim()}\n'}
Answer with a JSON array only, no prose around it, at most 8 entries, most important first:
["one instruction, one sentence, concrete enough to check", "..."]''';

/// Pulls the list out of a model's answer, however it wrapped it.
List<String> parseRules(String text) {
  final start = text.indexOf('[');
  final end = text.lastIndexOf(']');
  if (start < 0 || end <= start) return const [];
  try {
    final raw = jsonDecode(text.substring(start, end + 1));
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is String && e.trim().length > 15) e.trim(),
    ];
  } catch (_) {
    return const [];
  }
}

/// The words that carry the meaning of a rule.
Set<String> _keywords(String rule) => rule
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9àèéìòù ]'), ' ')
    .split(RegExp(r'\s+'))
    .where((w) => w.length > 4)
    .toSet();

/// Two models say the same thing in their own words; agreement is what matters,
/// so rules count as one when most of their meaningful words overlap.
bool sameRule(String a, String b) {
  final A = _keywords(a);
  final B = _keywords(b);
  if (A.isEmpty || B.isEmpty) return a.toLowerCase() == b.toLowerCase();
  var shared = 0;
  for (final w in A) {
    if (B.contains(w)) shared++;
  }
  return shared / (A.length < B.length ? A.length : B.length) >= 0.5;
}

/// Merges what they said into one brief, agreement first.
///
/// A rule more than one of them arrived at independently is the strongest
/// signal there is, so it leads — and it says who agreed, because an
/// instruction with three names behind it is harder to skip than one without.
String mergeRules(List<({String label, List<String> rules})> answers, {int max = 12}) {
  final merged = <({String rule, List<String> by})>[];
  for (final a in answers) {
    for (final r in a.rules) {
      final hit = merged.indexWhere((m) => sameRule(m.rule, r));
      if (hit >= 0) {
        if (!merged[hit].by.contains(a.label)) merged[hit].by.add(a.label);
      } else {
        merged.add((rule: r, by: [a.label]));
      }
    }
  }
  if (merged.isEmpty) return '';
  merged.sort((x, y) => y.by.length.compareTo(x.by.length));
  final lines = [
    for (final m in merged.take(max))
      '- ${m.rule}${m.by.length > 1 ? ' (su cui concordano ${m.by.join(', ')})' : ''}',
  ];
  return '\n\nDESIGN AGREED BY THE PANEL — these are not suggestions, build to them:\n${lines.join('\n')}';
}

/// Asks every model how the app should be designed and merges their answers
/// into one brief. A model that is down simply does not speak; the brief is
/// empty only when none of them answered, and the build then goes on as before.
Future<String> designCouncil(
  List<PanelMember> members, {
  required String request,
  String reference = '',
  void Function(String status)? onProgress,
}) async {
  if (members.length < 2) return '';
  onProgress?.call('I ${members.length} AI si stanno mettendo d\'accordo sul design…');
  final answers = await Future.wait([
    for (final m in members)
      m.complete(_system, _ask(request, reference)).then(
            (r) => (label: m.label, rules: parseRules(r.text)),
            onError: (_) => (label: m.label, rules: const <String>[]),
          ),
  ]);
  return mergeRules([for (final a in answers) if (a.rules.isNotEmpty) a]);
}

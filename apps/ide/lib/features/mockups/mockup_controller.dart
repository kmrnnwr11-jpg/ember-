import 'dart:async';
import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/foundation.dart';
import 'package:ide_core/ide_core.dart';

import '../../l10n/app_localizations.dart';
import '../create/app_builder.dart' show BuildEngine;

/// A visual direction the AI must follow for one mockup.
class MockupStyle {
  const MockupStyle(this.id, this.name, this.direction);
  final String id;
  final String name;
  final String direction;
}

/// Pool of clearly different styles; each "Nuovi mockup" takes the next five.
const mockupStylePool = <MockupStyle>[
  MockupStyle('minimal', 'Light minimal', 'Minimal light: lots of white space, one accent color, thin dividers, simple line icons, clean sans-serif (Inter).'),
  MockupStyle('dark', 'Dark premium', 'Dark premium: near-black background, rich gradients with gold or electric accent, glowing highlights, elegant typography (Manrope).'),
  MockupStyle('playful', 'Colorful & playful', 'Playful colorful: bright multi-color palette, big rounded shapes, chunky buttons, friendly emoji/illustration accents (Nunito).'),
  MockupStyle('glass', 'Glassmorphism', 'Glassmorphism: vivid blurred gradient background, frosted translucent cards (backdrop-filter blur), white text, soft shadows (Poppins).'),
  MockupStyle('material', 'Material 3', 'Material 3 classic: tonal surfaces from one seed color, FAB, top app bar, navigation bar, 16px radius cards (Roboto).'),
  MockupStyle('neumorph', 'Neumorphism', 'Soft neumorphism: monochrome soft gray-blue background, extruded/inset elements with dual soft shadows, subtle accent (DM Sans).'),
  MockupStyle('luxury', 'Elegant luxury', 'Luxury editorial: cream and deep green or burgundy, serif headings (Playfair Display), fine gold lines, generous spacing.'),
  MockupStyle('brutal', 'Bold brutalist', 'Neo-brutalism: high-contrast flat colors, thick black borders, hard offset shadows, oversized bold type (Space Grotesk).'),
  MockupStyle('pastel', 'Soft pastel', 'Soft pastel: light pastel palette (peach, lilac, mint), pill buttons, rounded 24px cards, airy and calm (Quicksand).'),
  MockupStyle('tech', 'Futuristic tech', 'Futuristic tech: deep navy, neon cyan/magenta accents, grid lines, monospace details, sharp geometric cards (Sora + JetBrains Mono).'),
  MockupStyle('nature', 'Nature', 'Organic nature: earthy greens and sand tones, organic rounded shapes, photo-like placeholders, warm friendly type (Lora + Nunito Sans).'),
  MockupStyle('ios', 'iOS style', 'iOS native look: SF-like system font stack, grouped inset lists, large titles, blur tab bar, system blue accents.'),
  MockupStyle('retro', '80s retro', 'Retro 80s: sunset gradient purple-pink-orange, chrome headings, bold outlines, playful vintage type (Righteous).'),
  MockupStyle('mono', 'Monochrome', 'Monochrome black & white with a single strong red accent, strict grid, bold typography (Archivo).'),
  MockupStyle('corporate', 'Professional', 'Professional corporate: navy and teal, data cards, clear hierarchy, trustworthy and precise (IBM Plex Sans).'),
];

/// What "modern" means in 2026, spelled out — otherwise a model reaches for
/// the look it saw most during training, which is the look of five years ago.
const modern2026Brief = '''
THIS MUST LOOK LIKE A 2026 APP, NOT A 2020 ONE. What that means concretely:
- Large, confident type: the screen title is 28-34px and heavy; secondary text is quiet grey, never black.
- Generous breathing room: 20-24px side margins, 16-20px between cards. Cramped padding is the clearest sign of an old design.
- Soft, large radii (20-28px on cards, full pills on buttons) used consistently — not 4px corners, not a different radius on every element.
- Depth comes from a barely-there tinted shadow and a hairline border, never from a hard grey drop shadow.
- One accent colour, used sparingly on what matters; everything else is a neutral tinted slightly toward that accent.
- Line icons on a 24px grid, 1.5-2px strokes. No emoji in the interface, no gloss, no bevels, no gradients on text.
- A real hierarchy: one thing on each screen is obviously the most important and is the largest, most saturated element.
Avoid: heavy drop shadows, thick coloured borders around everything, purple-to-blue gradient heroes, centred everything,
a card around every single item, and the 2010s "bevel and shine" look.''';

const mockupSystemPrompt = '''
You are a senior mobile UI designer. You produce ONE high-fidelity mobile app mockup as a single self-contained HTML file.

$modern2026Brief

Rules:
- Output EXACTLY three things and nothing else:
  1) First line: STYLE: {"name": "...", "palette": ["#hex", "#hex", "#hex", "#hex"], "font": "...", "tagline": "one short sentence in the user's language explaining the style"}
  2) Second line: DESIGN: one paragraph, max 60 words, saying how the screens are laid out, where the hierarchy sits, how the icons are drawn, and what makes this look current. Other designers read this line to judge your work, so describe decisions, not adjectives.
  3) A fenced block ```html mockup.html ... ``` with the complete HTML document.
- The HTML must work offline: inline <style>, no JavaScript frameworks, no external images (use CSS gradients, shapes and inline SVG as imagery). Google Fonts <link> is allowed with a system font fallback.
- Icons: draw them as inline SVG in the current line style — a 24px grid, 1.5-2px strokes, round caps, no fill, inheriting the text colour. This is what a phone looks like today. Never use emoji as an interface icon: an emoji in a toolbar is the mark of a mockup, not of an app. Emoji are allowed only inside fake content, where a person would have typed one.
- Designed for a 390px-wide phone viewport (<meta name="viewport" content="width=device-width, initial-scale=1">). No horizontal scrolling.
- Keep the whole file under 700 lines: a page cut off in the middle is useless, so prefer fewer decorative flourishes and finish the document.
- Show the app's 3 most important screens stacked vertically (e.g. onboarding/home + 2 key screens). Each screen is a full-width section about 844px tall, looking like a real app screen (status bar area, headers, content, bottom navigation where it makes sense), separated by a thin label with the screen name.
- Realistic fake content in the same language as the app description. Polished spacing, hierarchy and consistent components.
- Follow the requested visual style strictly so different styles look clearly different.
- COLOUR COMES FROM THE SUBJECT, not from habit: use the colour people already associate with this kind of app (PDF and documents red, money and banking green, water and travel blue, food warm orange, night and sleep deep indigo, health teal) and build the palette around it.''';

/// The styles worth showing for an app like this one. A children's app has no
/// business being offered a dark premium direction, and a banking app has no
/// business being offered a retro one: the pasted link decides the order.
List<MockupStyle> stylePoolFor(String styleBrief) {
  final audience = RegExp(r'^AUDIENCE:\s*(\w+)', multiLine: true).firstMatch(styleBrief)?.group(1);
  final wanted = switch (audience) {
    'kids' => ['playful', 'pastel', 'retro', 'brutal', 'nature'],
    'game' => ['playful', 'retro', 'tech', 'brutal', 'glass'],
    'serious' => ['corporate', 'material', 'minimal', 'mono', 'ios'],
    'creative' => ['dark', 'glass', 'tech', 'mono', 'brutal'],
    'social' => ['playful', 'glass', 'material', 'pastel', 'ios'],
    'calm' => ['pastel', 'nature', 'minimal', 'luxury', 'ios'],
    _ => const <String>[],
  };
  if (wanted.isEmpty) return mockupStylePool;
  final picked = [for (final id in wanted) ...mockupStylePool.where((s) => s.id == id)];
  return [...picked, ...mockupStylePool.where((s) => !picked.contains(s))];
}

/// A mockup is drawn from a brief, not from an encyclopaedia: a reference
/// listing or a whole website runs to tens of thousands of characters, and the
/// model then answers with a cut, unusable page.
const maxMockupDescription = 4000;

String shortDescription(String description) =>
    description.length <= maxMockupDescription
        ? description
        : '${description.substring(0, maxMockupDescription)}\n…(the rest of the brief goes to the build, not to the drawing)';

/// The colour always comes from the app's subject; what changes between
/// proposals is HOW that one subject colour is used, so the set stays varied
/// without ever drifting to a colour that fights the subject.
const mockupAccents = [
  'as one bold solid accent on neutral surfaces',
  'in a rich two-tone gradient of the same colour',
  'as a soft light tint across the surfaces',
  'as a deep, saturated, high-contrast tone',
  'paired with a small warm complementary highlight',
  'as duotone — two shades of the same colour',
  'as a vivid accent over a mostly monochrome layout',
  'with a subtle pastel version of itself',
];

/// Styles that read naturally on a dark background; the other styles fill the
/// light slots. A set is always half light, half dark (§ "4 dark + 4 normali").
const _darkStyleIds = {'dark', 'glass', 'tech', 'retro', 'mono'};

/// …and its own skeleton, because a different colour on the same layout is not
/// a different proposal. These decide where things sit and how they are drawn.
const mockupLayouts = [
  'Layout: a grid of square tiles, two or three per row, each tile a filled colour block with its icon drawn large inside. Bottom navigation bar. Icons: solid, filled shapes.',
  'Layout: a vertical list of wide rows, each with a round icon on the left, title and one line of description, a chevron on the right. Top app bar with a search field. Icons: thin outline, 1.5px strokes.',
  'Layout: one big hero card for the main action, then a horizontal carousel of secondary cards under it. No bottom bar; a floating action button instead. Icons: duotone, two shades of the accent.',
  'Layout: sectioned cards with clear headings, generous padding, hairline dividers between rows, a segmented control at the top. Icons: rounded, hand-drawn feel.',
  'Layout: a dashboard of small stat tiles at the top, then a dense two-column grid of actions. Side drawer instead of a bottom bar. Icons: geometric, built from circles and squares.',
  'Layout: full-bleed panels one per screen, big type, the action as a wide pill button at the bottom, a page indicator. Icons: minimal glyphs, almost text.',
  'Layout: a sticky toolbar with tabs at the top, cards with a coloured left stripe, a compact list below. Icons: badge-style, icon inside a rounded square.',
];

String mockupUserPrompt(String appDescription, MockupStyle style, {String? previousHtml, String? change, String styleBrief = '', String? accent, String? layout, String? mode}) {
  final b = StringBuffer()
    ..writeln('App description:')
    ..writeln(shortDescription(appDescription))
    ..writeln()
    ..writeln('Visual style: ${style.name} — ${style.direction}');
  if (mode != null) {
    b.writeln(
      mode == 'dark'
          ? 'Theme: DARK — a near-black or very dark background, light text, and the subject colour glowing on top. This mockup MUST be dark.'
          : 'Theme: LIGHT — a light/white background with dark text and the subject colour as the accent. This mockup MUST be light.',
    );
  }
  if (accent != null) {
    b.writeln(
      'COLOUR — this is the most important rule: build the whole mockup around the ONE colour people already associate with '
      "this app's subject (PDF and documents → red, water, weather and travel → blue, money and banking → green, food → warm "
      'orange, night and sleep → deep indigo, health → teal, nature → green). That subject colour is the dominant colour of the '
      'app. For variety between proposals use it $accent here — but NEVER swap it for an unrelated colour.',
    );
  }
  if (layout != null) {
    b.writeln('$layout\nFollow this arrangement: the proposals must differ in how the screens are built and how the icons are drawn, not only in colour.');
  }
  if (styleBrief.trim().isNotEmpty) {
    b
      ..writeln()
      ..writeln('WHO IT IS FOR — this outranks the visual style above wherever the two disagree:')
      ..writeln(styleBrief.trim());
  }
  if (previousHtml != null && change != null) {
    b
      ..writeln()
      ..writeln('This is the current mockup:')
      ..writeln('```html mockup.html')
      ..writeln(previousHtml)
      ..writeln('```')
      ..writeln('Apply this change requested by the user and output the full updated mockup: $change');
  }
  return b.toString();
}


/// The panel decides what the eight proposals should be, before drawing any.
///
/// The set used to come from a fixed list of fifteen looks — minimal, dark
/// premium, glassmorphism, 80s retro — handed out in rotation. Every app got
/// the same fifteen, whatever it was for, and a pasted Play Store link changed
/// only the order in which they arrived. So the proposals were about the list,
/// not about the app.
///
/// Now the models look at the app first and say which directions suit THIS
/// one: with a reference app, every direction stays in its world and brings it
/// up to date; without one, they are what a designer would actually try for
/// this subject.
const directionSystem = '''
You are a design director choosing the visual directions for a mobile app's first mockups, and you answer with JSON only.
You give eight directions a designer could draw from without asking you anything else. Each must be a different idea of what
the app looks like, not the same idea in another colour: they differ in structure, in what dominates the screen, in how dense
or airy it is, in how the icons are drawn, and in mood.
Two rules above all:
- The subject decides the colour. Build every direction around the colour people already associate with this kind of app
  (documents red, water and travel blue, money green, food warm orange, night deep indigo, health teal); never swap it for an
  unrelated one.
- If you are shown an app to take as a model, every direction stays recognisably in that app's world — same purpose, same
  kind of screens, same audience — brought up to 2026. You are not inventing a different product.''';

String directionAsk(String about, String styleBrief) {
  final who = styleBrief.trim().isEmpty
      ? ''
      : '\nWho it is for (this outranks taste):\n${styleBrief.trim()}\n';
  return 'The app:\n$about\n$who'
      '\nAnswer with a JSON array only, no prose around it, exactly 8 entries:\n'
      '[{"name":"two or three words naming the direction","direction":"one or two sentences a designer can draw from: '
      'layout, what dominates, typography, how the icons are drawn, the mood","dark":true}]\n'
      'Set "dark" true for a direction built on a dark ground, false for a light one. Offer both, about half and half.';
}

/// One agreed direction: a style to draw, and whether it sits on a dark ground.
typedef Direction = ({MockupStyle style, bool dark});

/// Reads the directions out of a model's answer, however it wrapped them.
List<Direction> parseDirections(String text) {
  final start = text.indexOf('[');
  final end = text.lastIndexOf(']');
  if (start < 0 || end <= start) return const [];
  try {
    final raw = jsonDecode(text.substring(start, end + 1));
    if (raw is! List) return const [];
    final out = <Direction>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final name = '${e['name'] ?? ''}'.trim();
      final direction = '${e['direction'] ?? ''}'.trim();
      if (name.isEmpty || direction.length < 20) continue;
      final id = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
      out.add((style: MockupStyle(id, name, direction), dark: e['dark'] == true));
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// The words that carry the meaning of a direction.
Set<String> _directionWords(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9àèéìòù ]'), ' ')
    .split(RegExp(r'\s+'))
    .where((w) => w.length > 4)
    .toSet();

/// Two models propose the same direction in their own words, so they count as
/// one when most of their meaningful words overlap.
bool sameDirection(String a, String b) {
  final wa = _directionWords(a);
  final wb = _directionWords(b);
  if (wa.isEmpty || wb.isEmpty) return a.toLowerCase() == b.toLowerCase();
  var shared = 0;
  for (final w in wa) {
    if (wb.contains(w)) shared++;
  }
  return shared / (wa.length < wb.length ? wa.length : wb.length) >= 0.5;
}

/// Merges the proposals into one set of [count], agreement first, keeping the
/// light and dark halves balanced so the user always sees both.
List<Direction> mergeDirections(
  List<({String label, List<Direction> list})> answers, {
  int count = 8,
}) {
  final merged = <({MockupStyle style, bool dark, List<String> by})>[];
  for (final a in answers) {
    for (final d in a.list) {
      final hit = merged.indexWhere((m) =>
          sameDirection(m.style.name, d.style.name) ||
          sameDirection(m.style.direction, d.style.direction));
      if (hit >= 0) {
        if (!merged[hit].by.contains(a.label)) merged[hit].by.add(a.label);
      } else {
        merged.add((style: d.style, dark: d.dark, by: <String>[a.label]));
      }
    }
  }
  merged.sort((x, y) => y.by.length.compareTo(x.by.length));
  final darks = merged.where((m) => m.dark).toList();
  final lights = merged.where((m) => !m.dark).toList();
  final out = <Direction>[];
  // Alternate light and dark, best agreed first in each half; when one half
  // runs out the other fills the rest rather than leaving a gap.
  for (var i = 0; out.length < count && (i < darks.length || i < lights.length); i++) {
    if (i < lights.length) out.add((style: lights[i].style, dark: false));
    if (out.length < count && i < darks.length) out.add((style: darks[i].style, dark: true));
  }
  return out;
}

enum MockupStatus { loading, ready, failed }

class Mockup {
  Mockup(this.style);

  final MockupStyle style;
  MockupStatus status = MockupStatus.loading;
  String? html;
  String name = '';
  List<String> palette = const [];
  String font = '';
  String tagline = '';
  String? error;

  /// Which model drew it, when several share the work.
  String authorId = '';
  String authorLabel = '';

  /// How the author described its own design, and what the other models said
  /// about it: filled by the panel rounds, empty when one model works alone.
  String design = '';
  double? score;
  List<String> notes = const [];
  bool refined = false;

  /// What the other designers are shown when they judge this proposal. The page
  /// itself is far too long to pass around, and its opening is mostly markup:
  /// the author's own description of what it did is the honest summary.
  String critiqueSummary(int n) => [
    'PROPOSAL $n — by $authorLabel',
    'Style: $name (${style.id}) · font: $font · palette: ${palette.join(', ')}',
    if (design.isNotEmpty) 'The designer describes it as: $design',
    if (tagline.isNotEmpty) 'Tagline: $tagline',
  ].join('\n');

  /// Parses the model output (STYLE line + html block). Returns false if unusable.
  bool apply(String text) {
    final styleLine = RegExp(r'^\s*STYLE:\s*(\{.*\})\s*$', multiLine: true).firstMatch(text);
    if (styleLine != null) {
      try {
        final j = jsonDecode(styleLine.group(1)!) as Map<String, dynamic>;
        name = (j['name'] as String?) ?? style.name;
        palette = [for (final c in (j['palette'] as List? ?? const [])) '$c'];
        font = (j['font'] as String?) ?? '';
        tagline = (j['tagline'] as String?) ?? '';
      } catch (_) {
        name = style.name;
      }
    } else {
      name = style.name;
    }
    final designLine = RegExp(r'^\s*DESIGN:\s*(.+)$', multiLine: true).firstMatch(text);
    if (designLine != null) design = designLine.group(1)!.trim();
    final code = CodeBlocks.parse(text).whereType<CodeSegment>().where((c) => c.complete && (c.language == 'html' || c.code.contains('<html'))).firstOrNull;
    final raw = code?.code ?? (text.contains('<html') ? text.substring(text.contains('<!DOCTYPE') ? text.indexOf('<!DOCTYPE') : text.indexOf('<html')) : null);
    if (raw == null || !raw.contains('</html>')) return false;
    html = raw;
    return true;
  }

  /// Design brief passed to the app builder when this mockup is chosen.
  String designBrief() => '''

APPROVED DESIGN (the user chose this mockup): reproduce its visual style faithfully in Flutter — same color palette ${palette.join(', ')}, typography ($font), shapes, spacing, component styles and screen layouts. Style: $name. ${style.direction}
Reference mockup HTML:
```html
$html
```''';
}

typedef CompleteText = Future<({String text, double? costUsd})> Function(String system, String prompt);

/// One model sitting at the design table. Several of them draw the set, then
/// read each other's work and say what is wrong with it.
typedef PanelMember = ({String id, String label, CompleteText complete});

const _critiqueSystem = '''
You are a senior mobile design director reviewing proposals from other designers, and you answer with JSON only.
You are hard to please but fair, and you never praise: your job is to name the one thing that would most improve each proposal.
Judge only what a 2026 design director would judge: hierarchy (is one thing clearly the most important?), typography (is the
title big and confident, is secondary text quiet?), spacing (is it generous or cramped?), colour discipline (one accent, tinted
neutrals, and does the colour fit the subject?), and whether it looks current or dated.
Never suggest adding emoji, heavy shadows, thick borders or gradient heroes. Never ask for a different subject colour.''';

String _critiquePrompt(String appDescription, String summaries, String ownLabel) => '''
The app: ${shortDescription(appDescription)}

These are the proposals on the table:

$summaries

Score every proposal from 1 to 10 and give ONE concrete, specific instruction that would most improve it — something a
designer can act on ("make the balance the largest element on the home screen and drop the card around it"), never vague
advice ("improve the hierarchy"). You are $ownLabel; judge your own proposals by the same standard as the others.
Answer with a JSON array only, one entry per proposal, no prose around it:
[{"n": 1, "score": 7, "fix": "the one instruction"}]''';

/// Reads the scores out of a critic's answer, however it wrapped them.
List<({int n, double score, String fix})> parseCritique(String text) {
  final start = text.indexOf('[');
  final end = text.lastIndexOf(']');
  if (start < 0 || end <= start) return const [];
  try {
    final raw = jsonDecode(text.substring(start, end + 1));
    if (raw is! List) return const [];
    final out = <({int n, double score, String fix})>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final n = int.tryParse('${e['n']}');
      final score = double.tryParse('${e['score']}');
      final fix = '${e['fix'] ?? ''}'.trim();
      if (n != null && score != null) out.add((n: n, score: score.clamp(1, 10).toDouble(), fix: fix));
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// Generates and manages mockup sets for one app description (§1B step 3).
class MockupController extends ChangeNotifier {
  MockupController({
    required this.description,
    required this.engine,
    required CompleteText complete,
    this.model,
    this.styleBrief = '',
    this.panel = const [],
  }) : _complete = complete;

  /// The models that share the drawing and then review each other. Empty or a
  /// single member means the old behaviour: one model draws, nobody reviews.
  final List<PanelMember> panel;

  final String description;

  /// Who the app is for, when the reference app makes that plain: it decides
  /// which styles are offered and overrides them where they disagree.
  final String styleBrief;
  final BuildEngine engine;
  final AiModel? model;
  final CompleteText _complete;

  /// The same engine the mockups were drawn with, for the app's name.
  CompleteText get completeText => _complete;

  /// All generated sets; the last one is the current set ("Precedenti" = earlier ones).
  final List<List<Mockup>> sets = [];
  int viewingSet = 0;
  int _poolOffset = 0;
  double costUsd = 0;

  List<Mockup> get current => sets.isEmpty ? const [] : sets[viewingSet];
  bool get loading => current.any((m) => m.status == MockupStatus.loading);

  /// How many proposals a set holds, and how many are drawn at once. A set is
  /// always 8: four light and four dark. Four at a time keeps it quick without
  /// asking a free tier for eight long answers in the same second.
  /// How many proposals one set holds: two for every model drawing, so each
  /// one shows both a light and a dark idea and nobody's taste fills the page.
  /// Eight when there is no panel and one engine draws alone.
  int get setSize => panel.length > 1 ? panel.length * 2 : 8;
  static const _atOnce = 4;

  /// Asks every model which directions suit this app and merges the answers.
  /// Returns empty when nobody usable answered, and the caller then falls back
  /// to the old fixed pool rather than showing nothing.
  Future<List<Direction>> _agreeDirections() async {
    panelStatus = 'I ${panel.length} AI stanno decidendo insieme le 8 direzioni…';
    notifyListeners();
    final answers = await Future.wait([
      for (final m in panel)
        m.complete(directionSystem, directionAsk(shortDescription(description), styleBrief)).then(
              (r) {
                costUsd += r.costUsd ?? 0;
                return (label: m.label, list: parseDirections(r.text));
              },
              onError: (_) => (label: m.label, list: const <Direction>[]),
            ),
    ]);
    final merged = mergeDirections([for (final a in answers) if (a.list.isNotEmpty) a], count: setSize);
    panelStatus = '';
    notifyListeners();
    return merged;
  }

  /// The eight proposals for this app.
  ///
  /// With a panel, the models first agree on what the eight directions should
  /// be — looking at the reference app when one was pasted — and only then
  /// draw them, two each. Alone, a model still gets the old fixed pool: it is
  /// not much, but it is better than a blank screen.
  Future<void> generateSet() async {
    final agreed = panel.length > 1 ? await _agreeDirections() : const <Direction>[];
    final chosenDirections = agreed.length >= 2 ? agreed : _poolDirections();
    if (agreed.isNotEmpty && agreed.length < setSize) {
      // Fewer than eight agreed: repeat them rather than pad with the old pool,
      // so every proposal still belongs to this app.
      while (chosenDirections.length < setSize) {
        chosenDirections.add(chosenDirections[chosenDirections.length % agreed.length]);
      }
    }

    final set = <Mockup>[];
    final prompts = <String>[];
    for (var i = 0; i < setSize; i++) {
      final d = chosenDirections[i % chosenDirections.length];
      final m = Mockup(d.style);
      // Round-robin, so every model draws both a light and a dark proposal and
      // the set cannot come out as one model's taste repeated eight times.
      if (panel.isNotEmpty) {
        final author = panel[i % panel.length];
        m
          ..authorId = author.id
          ..authorLabel = author.label;
      }
      set.add(m);
      prompts.add(
        mockupUserPrompt(
          description,
          d.style,
          styleBrief: styleBrief,
          mode: d.dark ? 'dark' : 'light',
        ),
      );
    }
    _poolOffset += setSize;
    sets.add(set);
    viewingSet = sets.length - 1;
    notifyListeners();
    for (var i = 0; i < set.length; i += _atOnce) {
      await Future.wait([for (final (j, m) in set.skip(i).take(_atOnce).indexed) _generate(m, prompts[i + j])]);
    }
    if (panel.length > 1) await _panelRounds(set, prompts);
  }

  /// The old fixed pool, kept only for the case where no panel can answer.
  List<Direction> _poolDirections() {
    final pool = stylePoolFor(styleBrief);
    final darks = pool.where((s) => _darkStyleIds.contains(s.id)).toList();
    final lights = pool.where((s) => !_darkStyleIds.contains(s.id)).toList();
    final d = darks.isEmpty ? pool : darks;
    final l = lights.isEmpty ? pool : lights;
    return <Direction>[
      for (var i = 0; i < setSize; i++)
        i.isOdd
            ? (style: d[(_poolOffset ~/ 2 + i ~/ 2) % d.length], dark: true)
            : (style: l[(_poolOffset ~/ 2 + i ~/ 2) % l.length], dark: false),
    ];
  }

  /// What the panel is doing right now, for the screen to show. Empty when it
  /// is not sitting.
  String panelStatus = '';

  /// The designers read each other's proposals, score them and say the one
  /// thing that would most improve each — then every one of them redraws its
  /// own proposals with the notes the others wrote. Nobody marks their own
  /// homework alone: a note only counts when it comes from a different model.
  Future<void> _panelRounds(List<Mockup> set, List<String> prompts) async {
    final ready = [for (final (i, m) in set.indexed) if (m.status == MockupStatus.ready && m.html != null) (i: i, m: m)];
    if (ready.length < 2) return;

    panelStatus = 'I ${panel.length} designer si confrontano sui ${ready.length} mockup…';
    notifyListeners();

    final summaries = [for (final (k, r) in ready.indexed) r.m.critiqueSummary(k + 1)].join('\n\n');
    // Every member critiques the whole table at once; one that is down or
    // answers nonsense simply does not vote.
    final votes = await Future.wait([
      for (final member in panel)
        member.complete(_critiqueSystem, _critiquePrompt(description, summaries, member.label)).then(
              (r) {
                costUsd += r.costUsd ?? 0;
                return (by: member.id, list: parseCritique(r.text));
              },
              onError: (_) => (by: member.id, list: const <({int n, double score, String fix})>[]),
            ),
    ]);

    for (final (k, r) in ready.indexed) {
      final scores = <double>[];
      final notes = <String>[];
      for (final v in votes) {
        final entry = v.list.where((e) => e.n == k + 1).firstOrNull;
        if (entry == null) continue;
        scores.add(entry.score);
        // A designer's opinion of their own work is not a second opinion.
        if (v.by != r.m.authorId && entry.fix.isNotEmpty) notes.add('${_labelOf(v.by)}: ${entry.fix}');
      }
      if (scores.isNotEmpty) r.m.score = scores.reduce((a, b) => a + b) / scores.length;
      r.m.notes = notes;
    }
    notifyListeners();

    final toRedraw = [for (final r in ready) if (r.m.notes.isNotEmpty) r];
    if (toRedraw.isEmpty) {
      panelStatus = '';
      notifyListeners();
      return;
    }
    panelStatus = 'Ogni designer sta rifacendo il suo mockup con le note degli altri…';
    notifyListeners();
    for (var i = 0; i < toRedraw.length; i += _atOnce) {
      await Future.wait([
        for (final r in toRedraw.skip(i).take(_atOnce))
          _generate(
            r.m,
            '${prompts[r.i]}\n\n'
            'THE DESIGN PANEL HAS REVIEWED YOUR PROPOSAL. It scored ${r.m.score?.toStringAsFixed(1) ?? '?'}/10.\n'
            'Apply these notes from the other designers, keep everything that already works, and output the complete updated mockup:\n'
            '${r.m.notes.map((n) => '- $n').join('\n')}',
            fallbackHtml: r.m.html,
          ).then((_) => r.m.refined = true),
      ]);
    }
    panelStatus = '';
    notifyListeners();
  }

  String _labelOf(String id) => panel.where((p) => p.id == id).firstOrNull?.label ?? id;

  /// The model that drew this mockup redraws it: a proposal keeps one author,
  /// so an edit never turns into a second model's taste over the first's.
  CompleteText _completerFor(Mockup m) =>
      panel.where((p) => p.id == m.authorId).firstOrNull?.complete ?? _complete;

  /// Regenerates one mockup applying the user's change ("Modifica questo").
  Future<void> edit(Mockup m, String change) async {
    final previous = m.html;
    m
      ..status = MockupStatus.loading
      ..error = null;
    notifyListeners();
    await _generate(m, mockupUserPrompt(description, m.style, previousHtml: previous, change: change, styleBrief: styleBrief), fallbackHtml: previous);
  }

  Future<void> retry(Mockup m) => _generate(m, mockupUserPrompt(description, m.style, styleBrief: styleBrief));

  Future<void> _generate(Mockup m, String prompt, {String? fallbackHtml, bool retry = true}) async {
    m
      ..status = MockupStatus.loading
      ..error = null;
    notifyListeners();
    try {
      final res = await _completerFor(m)(mockupSystemPrompt, prompt);
      costUsd += res.costUsd ?? 0;
      if (m.apply(res.text)) {
        m.status = MockupStatus.ready;
      } else if (retry) {
        // A cut or malformed page is usually a one-off: ask again, once,
        // insisting on the part that was missing.
        return _generate(
          m,
          '$prompt\n\nThe previous answer was cut off. Answer again, complete, ending with the closing html tag, and keep the page compact.',
          fallbackHtml: fallbackHtml,
          retry: false,
        );
      } else {
        m
          ..html = fallbackHtml
          ..status = fallbackHtml == null ? MockupStatus.failed : MockupStatus.ready
          ..error = 'Il modello non ha restituito un mockup valido';
      }
    } catch (e) {
      m
        ..html = fallbackHtml
        ..status = fallbackHtml == null ? MockupStatus.failed : MockupStatus.ready
        ..error = e is AiException ? e.message : (e is RunnerException ? e.message : e.toString());
    }
    notifyListeners();
  }

  void showSet(int index) {
    viewingSet = index;
    notifyListeners();
  }
}

/// Text completion through an API provider (Gemini, Claude, ChatGPT, Grok).
CompleteText apiCompleter(Future<AiProvider> Function(AiModel) resolve, AiModel model, {int maxTokens = 32000}) => (system, prompt) async {
  final provider = await resolve(model);
  final buf = StringBuffer();
  var input = 0, output = 0;
  await for (final e in provider.chat(model: model.id, system: system, maxTokens: maxTokens, messages: [AiMessage.user(prompt)])) {
    switch (e) {
      case AiTextDelta(:final text):
        buf.write(text);
      case AiUsage(:final inputTokens, :final outputTokens):
        if (inputTokens > 0) input = inputTokens;
        if (outputTokens > 0) output = outputTokens;
      case AiError(:final message, :final statusCode):
        throw AiException(message, statusCode: statusCode);
      default:
    }
  }
  return (text: buf.toString(), costUsd: model.estimateCost(input, output));
};

/// Text completion through the Runner's Claude Code login.
CompleteText claudeCodeCompleter(Future<Map<String, dynamic>> Function(String type, Map<String, dynamic> payload) request) =>
    (system, prompt) async {
      final res = await request(MsgType.agentComplete, {'system': system, 'prompt': prompt, 'quality': 'fast'});
      return (text: res['text'] as String, costUsd: (res['costUsd'] as num?)?.toDouble());
    };

/// Localized display name of a style from [mockupStylePool].
String mockupStyleLabel(AppLocalizations l, String id) => switch (id) {
  'minimal' => l.styleMinimal,
  'dark' => l.styleDark,
  'playful' => l.stylePlayful,
  'glass' => l.styleGlass,
  'material' => l.styleMaterial,
  'neumorph' => l.styleNeumorph,
  'luxury' => l.styleLuxury,
  'brutal' => l.styleBrutal,
  'pastel' => l.stylePastel,
  'tech' => l.styleTech,
  'nature' => l.styleNature,
  'ios' => l.styleIos,
  'retro' => l.styleRetro,
  'mono' => l.styleMono,
  'corporate' => l.styleCorporate,
  _ => id,
};

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

const mockupSystemPrompt = '''
You are a senior mobile UI designer. You produce ONE high-fidelity mobile app mockup as a single self-contained HTML file.
Rules:
- Output EXACTLY two things and nothing else:
  1) First line: STYLE: {"name": "...", "palette": ["#hex", "#hex", "#hex", "#hex"], "font": "...", "tagline": "one short sentence in the user's language explaining the style"}
  2) A fenced block ```html mockup.html ... ``` with the complete HTML document.
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

/// Generates and manages mockup sets for one app description (§1B step 3).
class MockupController extends ChangeNotifier {
  MockupController({required this.description, required this.engine, required CompleteText complete, this.model, this.styleBrief = ''})
    : _complete = complete;

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
  static const setSize = 8;
  static const _atOnce = 4;

  /// Generates a set of 8 proposals — 4 light, 4 dark — each built around the
  /// app's subject colour, with its own style and layout.
  Future<void> generateSet() async {
    final pool = stylePoolFor(styleBrief);
    final darkPool = pool.where((s) => _darkStyleIds.contains(s.id)).toList();
    final lightPool = pool.where((s) => !_darkStyleIds.contains(s.id)).toList();
    // Fall back to the whole pool if a subset came out empty, so we never crash.
    final darks = darkPool.isEmpty ? pool : darkPool;
    final lights = lightPool.isEmpty ? pool : lightPool;

    final set = <Mockup>[];
    final prompts = <String>[];
    for (var i = 0; i < setSize; i++) {
      final dark = i.isOdd; // alternate → 4 light (even i) + 4 dark (odd i)
      final chosen = dark ? darks[(_poolOffset ~/ 2 + i ~/ 2) % darks.length] : lights[(_poolOffset ~/ 2 + i ~/ 2) % lights.length];
      set.add(Mockup(chosen));
      prompts.add(
        mockupUserPrompt(
          description,
          chosen,
          styleBrief: styleBrief,
          mode: dark ? 'dark' : 'light',
          accent: mockupAccents[(_poolOffset + i) % mockupAccents.length],
          layout: mockupLayouts[(_poolOffset + i) % mockupLayouts.length],
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
  }

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
      final res = await _complete(mockupSystemPrompt, prompt);
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

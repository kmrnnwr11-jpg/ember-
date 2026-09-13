import 'dart:async';
import 'dart:convert';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/foundation.dart';
import 'package:ide_core/ide_core.dart';

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
  MockupStyle('minimal', 'Minimal chiaro', 'Minimal light: lots of white space, one accent color, thin dividers, simple line icons, clean sans-serif (Inter).'),
  MockupStyle('dark', 'Dark premium', 'Dark premium: near-black background, rich gradients with gold or electric accent, glowing highlights, elegant typography (Manrope).'),
  MockupStyle('playful', 'Colorato & giocoso', 'Playful colorful: bright multi-color palette, big rounded shapes, chunky buttons, friendly emoji/illustration accents (Nunito).'),
  MockupStyle('glass', 'Glassmorphism', 'Glassmorphism: vivid blurred gradient background, frosted translucent cards (backdrop-filter blur), white text, soft shadows (Poppins).'),
  MockupStyle('material', 'Material 3', 'Material 3 classic: tonal surfaces from one seed color, FAB, top app bar, navigation bar, 16px radius cards (Roboto).'),
  MockupStyle('neumorph', 'Neumorphism', 'Soft neumorphism: monochrome soft gray-blue background, extruded/inset elements with dual soft shadows, subtle accent (DM Sans).'),
  MockupStyle('luxury', 'Lusso elegante', 'Luxury editorial: cream and deep green or burgundy, serif headings (Playfair Display), fine gold lines, generous spacing.'),
  MockupStyle('brutal', 'Bold brutalista', 'Neo-brutalism: high-contrast flat colors, thick black borders, hard offset shadows, oversized bold type (Space Grotesk).'),
  MockupStyle('pastel', 'Pastello morbido', 'Soft pastel: light pastel palette (peach, lilac, mint), pill buttons, rounded 24px cards, airy and calm (Quicksand).'),
  MockupStyle('tech', 'Tech futuristico', 'Futuristic tech: deep navy, neon cyan/magenta accents, grid lines, monospace details, sharp geometric cards (Sora + JetBrains Mono).'),
  MockupStyle('nature', 'Natura', 'Organic nature: earthy greens and sand tones, organic rounded shapes, photo-like placeholders, warm friendly type (Lora + Nunito Sans).'),
  MockupStyle('ios', 'Stile iOS', 'iOS native look: SF-like system font stack, grouped inset lists, large titles, blur tab bar, system blue accents.'),
  MockupStyle('retro', 'Retro anni 80', 'Retro 80s: sunset gradient purple-pink-orange, chrome headings, bold outlines, playful vintage type (Righteous).'),
  MockupStyle('mono', 'Monocromatico', 'Monochrome black & white with a single strong red accent, strict grid, bold typography (Archivo).'),
  MockupStyle('corporate', 'Professionale', 'Professional corporate: navy and teal, data cards, clear hierarchy, trustworthy and precise (IBM Plex Sans).'),
];

const mockupSystemPrompt = '''
You are a senior mobile UI designer. You produce ONE high-fidelity mobile app mockup as a single self-contained HTML file.
Rules:
- Output EXACTLY two things and nothing else:
  1) First line: STYLE: {"name": "...", "palette": ["#hex", "#hex", "#hex", "#hex"], "font": "...", "tagline": "one short sentence in the user's language explaining the style"}
  2) A fenced block ```html mockup.html ... ``` with the complete HTML document.
- The HTML must work offline: inline <style>, no JavaScript frameworks, no external images (use CSS gradients, shapes, inline SVG and emoji as imagery). Google Fonts <link> is allowed with a system font fallback.
- Designed for a 390px-wide phone viewport (<meta name="viewport" content="width=device-width, initial-scale=1">). No horizontal scrolling.
- Show the app's 3 most important screens stacked vertically (e.g. onboarding/home + 2 key screens). Each screen is a full-width section about 844px tall, looking like a real app screen (status bar area, headers, content, bottom navigation where it makes sense), separated by a thin label with the screen name.
- Realistic fake content in the same language as the app description. Polished spacing, hierarchy and consistent components.
- Follow the requested visual style strictly so different styles look clearly different.''';

String mockupUserPrompt(String appDescription, MockupStyle style, {String? previousHtml, String? change}) {
  final b = StringBuffer()
    ..writeln('App description:')
    ..writeln(appDescription)
    ..writeln()
    ..writeln('Visual style: ${style.name} — ${style.direction}');
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
  MockupController({required this.description, required this.engine, required CompleteText complete, this.model})
    : _complete = complete;

  final String description;
  final BuildEngine engine;
  final AiModel? model;
  final CompleteText _complete;

  /// All generated sets; the last one is the current set ("Precedenti" = earlier ones).
  final List<List<Mockup>> sets = [];
  int viewingSet = 0;
  int _poolOffset = 0;
  double costUsd = 0;

  List<Mockup> get current => sets.isEmpty ? const [] : sets[viewingSet];
  bool get loading => current.any((m) => m.status == MockupStatus.loading);

  /// Generates 5 new, different styles in parallel (keeps previous sets).
  Future<void> generateSet() async {
    final styles = [for (var i = 0; i < 5; i++) mockupStylePool[(_poolOffset + i) % mockupStylePool.length]];
    _poolOffset += 5;
    final set = [for (final s in styles) Mockup(s)];
    sets.add(set);
    viewingSet = sets.length - 1;
    notifyListeners();
    await Future.wait([for (final m in set) _generate(m, mockupUserPrompt(description, m.style))]);
  }

  /// Regenerates one mockup applying the user's change ("Modifica questo").
  Future<void> edit(Mockup m, String change) async {
    final previous = m.html;
    m
      ..status = MockupStatus.loading
      ..error = null;
    notifyListeners();
    await _generate(m, mockupUserPrompt(description, m.style, previousHtml: previous, change: change), fallbackHtml: previous);
  }

  Future<void> retry(Mockup m) => _generate(m, mockupUserPrompt(description, m.style));

  Future<void> _generate(Mockup m, String prompt, {String? fallbackHtml}) async {
    m
      ..status = MockupStatus.loading
      ..error = null;
    notifyListeners();
    try {
      final res = await _complete(mockupSystemPrompt, prompt);
      costUsd += res.costUsd ?? 0;
      if (m.apply(res.text)) {
        m.status = MockupStatus.ready;
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
CompleteText apiCompleter(Future<AiProvider> Function(AiModel) resolve, AiModel model) => (system, prompt) async {
  final provider = await resolve(model);
  final buf = StringBuffer();
  var input = 0, output = 0;
  await for (final e in provider.chat(model: model.id, system: system, maxTokens: 16000, messages: [AiMessage.user(prompt)])) {
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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/ember_logo.dart';
import 'app_builder.dart';

/// Dramatic "the machine is doing the impossible" view shown while an app is being built:
/// code rain, a pulsing energy core, code typing itself and a glitching status line.
class ForgeView extends StatefulWidget {
  const ForgeView({super.key, required this.builder, required this.status});
  final AppBuilder builder;
  final String status;

  @override
  State<ForgeView> createState() => _ForgeViewState();
}

class _ForgeViewState extends State<ForgeView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _t = ValueNotifier<double>(0);
  final _rng = math.Random();
  final _rain = _Rain();
  final _typed = <String>[];
  String _typing = '';
  String _source = '';
  int _cursor = 0;
  double _nextChar = 0;

  static const _fakeCode = [
    'final core = await Engine.ignite(seed: 0x7F3A);',
    'class NeuralScaffold extends StatelessWidget {',
    '  Widget build(ctx) => Scaffold(body: _synth(ctx));',
    'stream.transform(Quantum.fold).listen(_render);',
    'for (final node in graph.nodes) node.bind(state);',
    'Firebase.initializeApp(options: AppConfig.firebase);',
    'return Router(routes: _compile(schema));',
    'assert(entropy < threshold, "collapse");',
    'await db.collection("users").doc(uid).set(profile);',
    'Theme.of(ctx).colorScheme.copyWith(primary: accent);',
    'const matrix = Matrix4.identity()..rotateZ(pi / 7);',
    'emit(Compiled(hash: sha256(bytes).toString()));',
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final t = elapsed.inMicroseconds / 1e6;
      final dt = t - _t.value;
      _t.value = t;
      _rain.step(dt, _rng);
      _nextChar -= dt;
      while (_nextChar <= 0) {
        _nextChar += 0.018 + _rng.nextDouble() * 0.02;
        _typeOne();
      }
    })..start();
  }

  void _typeOne() {
    if (_cursor >= _source.length) {
      if (_typing.isNotEmpty) {
        _typed.add(_typing);
        if (_typed.length > 14) _typed.removeAt(0);
      }
      _typing = '';
      _cursor = 0;
      _source = _nextLine();
      return;
    }
    _typing += _source[_cursor++];
  }

  /// Real generated code when available, otherwise plausible lines tagged with real file names.
  String _nextLine() {
    final live = widget.builder.liveText.toString();
    if (live.length > 200) {
      final lines = live.substring(math.max(0, live.length - 3000)).split('\n').where((l) => l.trim().length > 6).toList();
      if (lines.isNotEmpty) return lines[_rng.nextInt(lines.length)];
    }
    final files = widget.builder.writtenFiles.toList();
    if (files.isNotEmpty && _rng.nextDouble() < 0.25) return '// ⟶ ${files[_rng.nextInt(files.length)]}';
    return _fakeCode[_rng.nextInt(_fakeCode.length)];
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final b = widget.builder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 460,
        color: const Color(0xFF070102),
        child: ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, t, _) => Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _RainPainter(_rain, t)),
              CustomPaint(painter: _CorePainter(t)),
              // Scan line.
              Positioned(
                left: 0,
                right: 0,
                top: ((t * 0.35) % 1) * 460,
                child: Container(height: 2, color: const Color(0x33FF1A2E)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const EmberMark(size: 40),
                        const SizedBox(width: 10),
                        Expanded(child: _Glitch(text: l.forgeTitle.toUpperCase(), t: t, size: 22)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '> ${widget.status}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFFF8A95), fontSize: 13),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xAA000000),
                        border: Border.all(color: const Color(0x55FF1A2E)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < _typed.length; i++)
                            Text(
                              _typed[i],
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color.lerp(const Color(0x22FF2A3D), const Color(0xAAFF2A3D), i / 14),
                              ),
                            ),
                          Text(
                            '$_typing${(t * 3).floor().isEven ? '█' : ' '}',
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFFFD6DB), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          l.forgeFiles(b.writtenFiles.length),
                          style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFFF1A2E), fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              color: const Color(0xFFFF1A2E),
                              backgroundColor: const Color(0x22FF1A2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF5C7A), side: const BorderSide(color: Color(0x88FF5C7A))),
                          onPressed: b.cancel,
                          icon: const Icon(Icons.stop, size: 18),
                          label: Text(l.stop),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Drop {
  _Drop(this.x, this.y, this.speed, this.chars);
  double x, y, speed;
  List<String> chars;
}

class _Rain {
  static const glyphs = '01アイウエオカキクケコサシスセソ{}<>=/*+;#λΣΩ∆';
  final drops = <_Drop>[];

  void step(double dt, math.Random rng) {
    if (drops.length < 70) {
      drops.add(_Drop(rng.nextDouble(), -rng.nextDouble(), 0.15 + rng.nextDouble() * 0.45,
          List.generate(6 + rng.nextInt(14), (_) => glyphs[rng.nextInt(glyphs.length)])));
    }
    for (final d in drops) {
      d.y += d.speed * dt;
      if (rng.nextDouble() < 0.08) d.chars[rng.nextInt(d.chars.length)] = glyphs[rng.nextInt(glyphs.length)];
      if (d.y > 1.6) {
        d.y = -rng.nextDouble() * 0.5;
        d.x = rng.nextDouble();
      }
    }
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.rain, this.t);
  final _Rain rain;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 14.0;
    for (final d in rain.drops) {
      for (var i = 0; i < d.chars.length; i++) {
        final y = d.y * size.height - i * step;
        if (y < -step || y > size.height) continue;
        final head = i == 0;
        final alpha = head ? 1.0 : (1 - i / d.chars.length) * 0.45;
        final tp = TextPainter(
          text: TextSpan(
            text: d.chars[i],
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: (head ? const Color(0xFFFFE0E4) : const Color(0xFFFF1A2E)).withValues(alpha: alpha),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(d.x * size.width, y));
      }
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => true;
}

class _CorePainter extends CustomPainter {
  _CorePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    final pulse = 0.5 + 0.5 * math.sin(t * 3.2);
    final r = 48 + pulse * 10;
    canvas.drawCircle(
      c,
      r * 2.4,
      Paint()
        ..shader = RadialGradient(colors: [const Color(0x55FF1A2E), const Color(0x00FF1A2E)]).createShader(Rect.fromCircle(center: c, radius: r * 2.4)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: const [Color(0xFFFFE0E4), Color(0xFFFF3A4A), Color(0x00FF0020)], stops: const [0, 0.35, 1])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Orbiting rings.
    for (var i = 0; i < 3; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFF1A2E).withValues(alpha: 0.5 - i * 0.12);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(t * (0.8 + i * 0.55) * (i.isEven ? 1 : -1));
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r + 22 + i * 18), 0, math.pi * 1.3, false, paint);
      canvas.restore();
    }
    // Lightning sparks.
    final rng = math.Random((t * 12).floor());
    final spark = Paint()
      ..color = const Color(0xCCFFB0B8)
      ..strokeWidth = 1.2;
    for (var k = 0; k < 3; k++) {
      var p = c;
      final a = rng.nextDouble() * math.pi * 2;
      for (var s = 0; s < 6; s++) {
        final len = r + s * 14.0;
        final q = c + Offset(math.cos(a + (rng.nextDouble() - 0.5) * 0.4), math.sin(a + (rng.nextDouble() - 0.5) * 0.4)) * len;
        canvas.drawLine(p, q, spark);
        p = q;
      }
    }
  }

  @override
  bool shouldRepaint(_CorePainter old) => true;
}

/// Text that occasionally tears into RGB-shifted copies.
class _Glitch extends StatelessWidget {
  const _Glitch({required this.text, required this.t, required this.size});
  final String text;
  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    final burst = math.sin(t * 17) > 0.93;
    final dx = burst ? (math.sin(t * 91) * 4) : 0.0;
    TextStyle style(Color c) => TextStyle(fontFamily: 'monospace', fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 3, color: c);
    return Stack(
      children: [
        if (burst) Transform.translate(offset: Offset(dx, 0), child: Text(text, style: style(const Color(0xAAFF0055)))),
        if (burst) Transform.translate(offset: Offset(-dx, 1), child: Text(text, style: style(const Color(0xAA00E5FF)))),
        Text(text, style: style(const Color(0xFFFFEFF1)).copyWith(shadows: const [Shadow(color: Color(0xFFFF1A2E), blurRadius: 14)])),
      ],
    );
  }
}

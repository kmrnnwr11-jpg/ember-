import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/theme.dart';

/// The Ember mark: a phone with a red eye rising from a ring of fire.
class EmberMark extends StatefulWidget {
  const EmberMark({super.key, this.size = 48, this.animate = true});
  final double size;
  final bool animate;

  @override
  State<EmberMark> createState() => _EmberMarkState();
}

class _EmberMarkState extends State<EmberMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(painter: EmberMarkPainter(reduce ? 0 : _c.value)),
        ),
      ),
    );
  }
}

/// Paints the mark in a 120×120 design space; [t] is the animation phase 0..1.
class EmberMarkPainter extends CustomPainter {
  EmberMarkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 120);
    final wave = math.sin(t * math.pi * 2 * 3);

    // Ring of fire (magic circle seen in perspective).
    final ring = Rect.fromCenter(center: const Offset(60, 98), width: 104, height: 28);
    canvas.drawOval(ring, Paint()..color = emberRed.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawOval(ring, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = emberRed);
    final tri = Path()
      ..moveTo(60, 86)
      ..lineTo(92, 108)
      ..lineTo(28, 108)
      ..close();
    canvas.drawPath(tri, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = emberRed.withValues(alpha: 0.7));

    // Flame.
    final s = 1 + wave * 0.06;
    canvas.save();
    canvas.translate(60, 98);
    canvas.scale(s, 1 + wave * 0.1);
    canvas.translate(-60, -98);
    final flame = Path()
      ..moveTo(60, 100)
      ..cubicTo(40, 92, 44, 72, 54, 62)
      ..cubicTo(52, 74, 62, 76, 62, 66)
      ..cubicTo(72, 74, 76, 90, 60, 100)
      ..close();
    canvas.drawPath(flame, Paint()..color = const Color(0xFFFF5A1A).withValues(alpha: 0.9)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    canvas.restore();

    // Phone rising and sinking slowly.
    final dy = math.sin(t * math.pi * 2) * 4;
    final phone = RRect.fromRectAndRadius(Rect.fromLTWH(44, 10 + dy, 32, 58), const Radius.circular(6));
    canvas.drawRRect(phone, Paint()..color = const Color(0xFF0A0D10));
    canvas.drawRRect(phone, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = emberRed);

    // Red eye that blinks now and then.
    final blink = (t * 6) % 1 > 0.94 ? 0.1 : 1.0;
    final eye = Offset(60, 38 + dy);
    canvas.drawCircle(eye, 12, Paint()..color = emberRed.withValues(alpha: 0.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.save();
    canvas.translate(eye.dx, eye.dy);
    canvas.scale(1, blink);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 18, height: 12), Paint()..color = emberRed);
    canvas.drawCircle(Offset.zero, 3.2, Paint()..color = Colors.black);
    canvas.restore();
  }

  @override
  bool shouldRepaint(EmberMarkPainter old) => old.t != t;
}

/// "EMBER" in the display face, with the optional tagline under it.
class EmberWordmark extends StatelessWidget {
  const EmberWordmark({super.key, this.size = 28, this.subtitle = true, this.center = false});
  final double size;
  final bool subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'EMBER',
          style: TextStyle(
            fontFamily: 'ChakraPetch',
            fontWeight: FontWeight.w700,
            fontSize: size,
            height: 1.1,
            color: scheme.onSurface,
            letterSpacing: size * 0.22,
          ),
        ),
        if (subtitle)
          Text(
            AppLocalizations.of(context).brandTagline,
            style: TextStyle(
              fontSize: size * 0.34,
              letterSpacing: size * 0.1,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Mark + wordmark side by side (like the lockup of option 20).
class EmberLockup extends StatelessWidget {
  const EmberLockup({super.key, this.size = 28, this.subtitle = true});
  final double size;
  final bool subtitle;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      EmberMark(size: size * 1.7),
      SizedBox(width: size * 0.4),
      EmberWordmark(size: size, subtitle: subtitle),
    ],
  );
}

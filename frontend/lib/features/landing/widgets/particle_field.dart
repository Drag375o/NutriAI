import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/theme/colors.dart';

/// A drifting field of points connected by lines, reacting to the pointer.
///
/// Drawn with CustomPaint rather than pulled from a package: the whole
/// thing is a few hundred lines of arithmetic, and a dependency would
/// bring its own visual opinions along with it.
class ParticleField extends StatefulWidget {
  const ParticleField({super.key, this.density = 11000});

  /// One point per this many square pixels. Lower is denser.
  final double density;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  final List<_Point> _points = [];
  final _random = Random();

  Size _size = Size.zero;
  Offset _pointer = const Offset(-999, -999);

  @override
  void initState() {
    super.initState();
    // A Ticker rather than a repeating timer: it stops automatically when
    // the route is not visible, so the field costs nothing in a background
    // tab or behind another screen.
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration _) {
    if (_size.isEmpty) return;
    setState(_step);
  }

  void _seed(Size size) {
    _size = size;
    _points.clear();

    final count = (size.width * size.height / widget.density).round();

    for (var i = 0; i < count; i++) {
      _points.add(
        _Point(
          position: Offset(
            _random.nextDouble() * size.width,
            _random.nextDouble() * size.height,
          ),
          velocity: Offset(
            (_random.nextDouble() - 0.5) * 0.28,
            (_random.nextDouble() - 0.5) * 0.28,
          ),
          // Roughly one in seven is larger and takes the accent colour, so
          // turmeric appears as punctuation rather than as a scheme.
          warm: _random.nextDouble() < 0.14,
        ),
      );
    }
  }

  void _step() {
    for (final point in _points) {
      var next = point.position + point.velocity;

      // Wrap rather than bounce: a bounce makes the edges of the field
      // visible, which gives away that it is a box.
      next = Offset(
        next.dx < 0
            ? _size.width
            : next.dx > _size.width
                ? 0
                : next.dx,
        next.dy < 0
            ? _size.height
            : next.dy > _size.height
                ? 0
                : next.dy,
      );

      // Push away from the pointer, more strongly the closer it is.
      final away = next - _pointer;
      final distance = away.distance;

      if (distance < _pushRadius && distance > 0.1) {
        next += (away / distance) * (_pushRadius - distance) * 0.014;
      }

      point.position = next;
    }
  }

  static const _pushRadius = 130.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = p.brightness == Brightness.dark;

    return MouseRegion(
      onHover: (event) => _pointer = event.localPosition,
      onExit: (_) => _pointer = const Offset(-999, -999),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          // Reseed on a resize, so density stays even rather than leaving
          // a sparse band where the window grew.
          if (size != _size) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _seed(size));
            });
          }

          return CustomPaint(
            painter: _FieldPainter(
              points: _points,
              // On paper the lines are ink at low opacity; on the dark
              // ground they are linen. Same drawing, inverted weight.
              line: dark
                  ? const Color(0xFFB4AA98)
                  : const Color(0xFF1C1A15),
              dot: dark
                  ? const Color(0xFFCDC4B2)
                  : const Color(0xFF3A3630),
              accent: p.turmeric,
              // Ink on paper reads much heavier than linen on near-black,
              // so light mode needs roughly half the opacity.
              strength: dark ? 1.0 : 0.55,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Point {
  _Point({
    required this.position,
    required this.velocity,
    required this.warm,
  });

  Offset position;
  final Offset velocity;
  final bool warm;

  double get radius => warm ? 2.6 : 1.4;
}

class _FieldPainter extends CustomPainter {
  const _FieldPainter({
    required this.points,
    required this.line,
    required this.dot,
    required this.accent,
    required this.strength,
  });

  final List<_Point> points;
  final Color line;
  final Color dot;
  final Color accent;
  final double strength;

  /// Beyond this, two points are not joined.
  static const _linkRadius = 108.0;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()..strokeWidth = 0.6;

    // Every pair is tested, which is fine at this count — around seventy
    // points is two and a half thousand comparisons a frame, well inside
    // budget. A spatial grid would be needed past a few hundred.
    for (var a = 0; a < points.length; a++) {
      for (var b = a + 1; b < points.length; b++) {
        final distance = (points[a].position - points[b].position).distance;
        if (distance >= _linkRadius) continue;

        // Lines fade out with distance, so connections appear and vanish
        // rather than snapping on.
        stroke.color = line.withValues(
          alpha: (1 - distance / _linkRadius) * 0.3 * strength,
        );
        canvas.drawLine(points[a].position, points[b].position, stroke);
      }
    }

    final fill = Paint();

    for (final point in points) {
      fill.color = point.warm
          ? accent.withValues(alpha: strength)
          : dot.withValues(alpha: 0.55 * strength);
      canvas.drawCircle(point.position, point.radius, fill);
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) => true;
}
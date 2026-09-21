import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../data/weight_models.dart';

/// A weight line over time, with the target drawn as a marker.
///
/// Painted directly rather than with a charting package: the shape is one
/// line and two labels, and a package would bring its own visual language
/// along with a dependency.
class WeightChart extends StatelessWidget {
  const WeightChart({
    super.key,
    required this.entries,
    this.target,
    this.height = 220,
  });

  final List<WeightEntry> entries;
  final double? target;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // An infinite height means the parent is sizing this, so the SizedBox
    // passes null and lets it fill whatever it is given.
    final boxHeight = height.isFinite ? height : null;

    if (entries.length < 2) {
      return SizedBox(
        height: boxHeight,
        child: Center(
          child: Text(
            entries.isEmpty
                ? 'No weight recorded yet.'
                : 'One more entry and a line appears here.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return SizedBox(
      height: boxHeight,
      child: CustomPaint(
        painter: _WeightPainter(
          entries: entries,
          target: target,
          line: p.ember,
          grid: p.hair,
          fill: p.ember.withValues(alpha: 0.08),
          targetColour: p.turmeric,
          labelStyle: AppTypography.mono(color: p.muted, size: 9.5),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WeightPainter extends CustomPainter {
  _WeightPainter({
    required this.entries,
    required this.target,
    required this.line,
    required this.grid,
    required this.fill,
    required this.targetColour,
    required this.labelStyle,
  });

  final List<WeightEntry> entries;
  final double? target;
  final Color line;
  final Color grid;
  final Color fill;
  final Color targetColour;
  final TextStyle labelStyle;

  // Room for the axis labels drawn outside the plot area.
  static const _leftPad = 40.0;
  static const _bottomPad = 22.0;
  static const _topPad = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plotWidth = size.width - _leftPad;
    final plotHeight = size.height - _bottomPad - _topPad;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    final weights = entries.map((e) => e.weightKg).toList();
    var minY = weights.reduce((a, b) => a < b ? a : b);
    var maxY = weights.reduce((a, b) => a > b ? a : b);

    // The target belongs inside the visible range, or its marker would sit
    // off the edge of the chart.
    if (target != null) {
      if (target! < minY) minY = target!;
      if (target! > maxY) maxY = target!;
    }

    // A flat line would divide by zero, and a hairline range makes normal
    // fluctuation look dramatic. Both are fixed by a minimum span.
    final span = (maxY - minY).abs() < 1 ? 1.0 : maxY - minY;
    final padding = span * 0.15;
    minY -= padding;
    maxY += padding;

    double yFor(double weight) =>
        _topPad + plotHeight * (1 - (weight - minY) / (maxY - minY));

    double xFor(int index) =>
        _leftPad + plotWidth * (index / (entries.length - 1));

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 0.5;

    // Three gridlines: top, middle, bottom. More would be noise at this size.
    for (var i = 0; i <= 2; i++) {
      final value = maxY - (maxY - minY) * (i / 2);
      final y = yFor(value);
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width, y), gridPaint);
      _label(canvas, value.toStringAsFixed(1), Offset(0, y - 6));
    }

    // Target marker, dashed so it reads as a goal rather than a reading.
    if (target != null) {
      final y = yFor(target!);
      final dash = Paint()
        ..color = targetColour
        ..strokeWidth = 1;

      for (var x = _leftPad; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(x + 4, y), dash);
      }
    }

    final path = Path();
    final area = Path();

    for (var i = 0; i < entries.length; i++) {
      final point = Offset(xFor(i), yFor(entries[i].weightKg));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
        area.moveTo(point.dx, _topPad + plotHeight);
        area.lineTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
        area.lineTo(point.dx, point.dy);
      }
    }

    area.lineTo(xFor(entries.length - 1), _topPad + plotHeight);
    area.close();

    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // The most recent point is marked, since it is the number that matters.
    final last = Offset(
      xFor(entries.length - 1),
      yFor(entries.last.weightKg),
    );
    canvas.drawCircle(last, 3.5, Paint()..color = line);

    _label(canvas, _formatDate(entries.first.recordedOn),
        Offset(_leftPad, size.height - 14));
    _label(
      canvas,
      _formatDate(entries.last.recordedOn),
      Offset(size.width - 44, size.height - 14),
    );
  }

  void _label(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  bool shouldRepaint(_WeightPainter old) =>
      old.entries != entries || old.target != target || old.line != line;
}
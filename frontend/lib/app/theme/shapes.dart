import 'package:flutter/material.dart';

import 'spacing.dart';

/// A rectangle with two opposite corners cut flat, like a stamped label.
///
/// Used on primary buttons and nothing else, so it stays a signature
/// rather than a texture.
class ChamferedBorder extends OutlinedBorder {
  const ChamferedBorder({
    super.side = BorderSide.none,
    this.cut = AppRadii.chamfer,
  });

  /// How far in from each cut corner the flat edge starts.
  final double cut;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ChamferedBorder copyWith({BorderSide? side, double? cut}) {
    return ChamferedBorder(side: side ?? this.side, cut: cut ?? this.cut);
  }

  @override
  ShapeBorder scale(double t) =>
      ChamferedBorder(side: side.scale(t), cut: cut * t);

  Path _build(Rect rect, double inset) {
    final r = rect.deflate(inset);
    final c = cut.clamp(0.0, r.shortestSide / 2);
    return Path()
      ..moveTo(r.left + c, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.bottom - c)
      ..lineTo(r.right - c, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + c)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _build(rect, 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _build(rect, side.width);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      _build(rect, side.width / 2),
      side.toPaint()..style = PaintingStyle.stroke,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChamferedBorder && other.side == side && other.cut == cut;

  @override
  int get hashCode => Object.hash(side, cut);
}
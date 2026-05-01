import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Spoked-O brand mark — Option 1 from the designer's logo proposals.
///
/// A bicycle wheel: outer circle, hub, and 3–8 spokes. Spoke count adapts
/// to size for legibility (denser at large sizes, simpler at favicon scale).
///
/// Tints with [color] or the ambient [IconTheme.color].
class BrandMark extends StatelessWidget {
  final double size;
  final Color? color;

  const BrandMark({super.key, this.size = 28, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ??
        IconTheme.of(context).color ??
        Theme.of(context).iconTheme.color ??
        Colors.white;

    final spokes = size < 22 ? 3 : (size < 36 ? 6 : 8);

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SpokedOPainter(color: tint, spokeCount: spokes),
      ),
    );
  }
}

class _SpokedOPainter extends CustomPainter {
  final Color color;
  final int spokeCount;

  _SpokedOPainter({required this.color, required this.spokeCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = (size.width * 0.07).clamp(1.4, 3.0);
    final spokeWidth = (size.width * 0.045).clamp(1.0, 2.0);
    final radius = size.width / 2 - strokeWidth;
    final hubRadius = (size.width * 0.085).clamp(2.0, 4.5);

    final rim = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final spokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = spokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final hub = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, rim);

    final r = radius * 0.95;
    for (int i = 0; i < spokeCount; i++) {
      final angle = (i * math.pi) / spokeCount; // half-circle is enough — diameters
      final dx = r * math.cos(angle);
      final dy = r * math.sin(angle);
      canvas.drawLine(
        Offset(center.dx - dx, center.dy - dy),
        Offset(center.dx + dx, center.dy + dy),
        spokePaint,
      );
    }

    canvas.drawCircle(center, hubRadius, hub);
  }

  @override
  bool shouldRepaint(_SpokedOPainter old) =>
      old.color != color || old.spokeCount != spokeCount;
}

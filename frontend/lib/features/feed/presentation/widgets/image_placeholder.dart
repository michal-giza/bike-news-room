import 'package:flutter/material.dart';

import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/url/safe_url.dart';
import '../../domain/entities/article.dart';

/// The "abstract striped" image placeholder from the design — used when the
/// article has no image_url. Stripes are tinted with the discipline hue.
class ImagePlaceholder extends StatelessWidget {
  final Article article;
  final double radius;
  final BoxFit fit;

  const ImagePlaceholder({
    super.key,
    required this.article,
    this.radius = BnrRadius.r2,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final disc = BnrColors.disciplineColor(article.discipline);
    final ext = context.bnr;

    // Real image takes priority — but only http(s) URLs. RSS feeds occasionally
    // emit `data:` or relative URLs; we'd rather fall back to the striped
    // placeholder than render arbitrary content.
    if (isSafeWebUrl(article.imageUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          article.imageUrl!,
          fit: fit,
          errorBuilder: (_, __, ___) => _stripes(disc, ext),
          loadingBuilder: (_, child, prog) =>
              prog == null ? child : _stripes(disc, ext),
        ),
      );
    }
    return _stripes(disc, ext);
  }

  Widget _stripes(Color disc, BnrThemeExt ext) {
    final angles = [125, 145, 165, 100, 80];
    final angle = (angles[article.id % angles.length]).toDouble();
    final label = '${article.discipline?.toUpperCase() ?? "—"} · ${article.id}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base bg
          Container(color: ext.bg2),
          // Radial halo of discipline color
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.5, -0.5),
                radius: 1.0,
                colors: [disc.withValues(alpha: 0.35), Colors.transparent],
              ),
            ),
          ),
          // Striped pattern
          CustomPaint(
            painter: _StripePainter(
              color: disc.withValues(alpha: 0.18),
              angleDegrees: angle,
            ),
          ),
          // Bottom-left mono label
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color color;
  final double angleDegrees;

  _StripePainter({required this.color, required this.angleDegrees});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2;
    canvas.save();
    final radians = angleDegrees * 3.14159265 / 180;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(radians);
    canvas.translate(-size.width, -size.height);

    const spacing = 8.0;
    for (double y = 0; y < size.width * 2 + size.height * 2; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width * 2, y), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter old) =>
      old.color != color || old.angleDegrees != angleDegrees;
}

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../preferences/domain/entities/user_preferences.dart';

/// Greyboxed placeholder version of `ArticleCard` for the loading state.
///
/// Why bother: showing the actual layout (image left, two text lines, meta
/// row) makes the page feel ~30% faster to perceive than a spinner — the
/// brain stops asking "is anything happening?" because the silhouette of
/// real cards is already there.
class ArticleCardSkeleton extends StatefulWidget {
  final CardDensity density;
  const ArticleCardSkeleton({super.key, required this.density});

  @override
  State<ArticleCardSkeleton> createState() => _ArticleCardSkeletonState();
}

class _ArticleCardSkeletonState extends State<ArticleCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // Subtle shimmer — opacity oscillates between 0.55 and 1.0 across
        // the cycle. We use opacity rather than a moving gradient because
        // it's cheaper on Flutter Web (one repaint, no shader rebuild).
        final t = (1 - (_ctrl.value * 2 - 1).abs()).clamp(0.55, 1.0);
        final block = ext.bg2.withValues(alpha: t);
        return _layout(context, block);
      },
    );
  }

  Widget _layout(BuildContext context, Color block) {
    final ext = context.bnr;
    return switch (widget.density) {
      CardDensity.compact => _compact(ext, block),
      CardDensity.comfort => _comfort(ext, block),
      CardDensity.large => _large(ext, block),
    };
  }

  Widget _comfort(BnrThemeExt ext, Color block) {
    return Container(
      margin: const EdgeInsets.only(bottom: BnrSpacing.s3),
      padding: const EdgeInsets.all(BnrSpacing.s4),
      decoration: BoxDecoration(
        color: ext.bg1,
        border: Border.all(color: ext.lineSoft),
        borderRadius: BorderRadius.circular(BnrRadius.r3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 132, height: 88,
            decoration: BoxDecoration(
              color: block,
              borderRadius: BorderRadius.circular(BnrRadius.r2),
            ),
          ),
          const SizedBox(width: BnrSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(block, height: 10, widthFactor: 0.4),
                const SizedBox(height: BnrSpacing.s2),
                _bar(block, height: 18, widthFactor: 0.95),
                const SizedBox(height: 6),
                _bar(block, height: 18, widthFactor: 0.65),
                const SizedBox(height: BnrSpacing.s2),
                _bar(block, height: 12, widthFactor: 0.85),
                const SizedBox(height: 4),
                _bar(block, height: 12, widthFactor: 0.55),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compact(BnrThemeExt ext, Color block) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BnrSpacing.s4,
        vertical: BnrSpacing.s3,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ext.lineSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(block, height: 10, widthFactor: 0.35),
          const SizedBox(height: 6),
          _bar(block, height: 14, widthFactor: 0.92),
          const SizedBox(height: 4),
          _bar(block, height: 14, widthFactor: 0.55),
        ],
      ),
    );
  }

  Widget _large(BnrThemeExt ext, Color block) {
    return Container(
      margin: const EdgeInsets.only(bottom: BnrSpacing.s5),
      decoration: BoxDecoration(
        color: ext.bg1,
        border: Border.all(color: ext.lineSoft),
        borderRadius: BorderRadius.circular(BnrRadius.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: ColoredBox(color: block)),
          Padding(
            padding: const EdgeInsets.all(BnrSpacing.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(block, height: 10, widthFactor: 0.35),
                const SizedBox(height: BnrSpacing.s3),
                _bar(block, height: 22, widthFactor: 0.85),
                const SizedBox(height: 6),
                _bar(block, height: 22, widthFactor: 0.5),
                const SizedBox(height: BnrSpacing.s3),
                _bar(block, height: 14, widthFactor: 0.95),
                const SizedBox(height: 4),
                _bar(block, height: 14, widthFactor: 0.7),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(Color color, {required double height, required double widthFactor}) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

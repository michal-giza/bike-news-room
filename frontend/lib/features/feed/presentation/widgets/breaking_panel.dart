import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/article.dart';
import 'live_dot.dart';
import 'time_ago.dart';

/// "Breaking now" panel built from real article data.
///
/// Replaces the static demo `LiveRaceBanner`. We don't have a live-tracking
/// data source yet — until we do, this is the next best thing: surface the
/// freshest results-category articles from the last hour as a hero panel.
///
/// Hidden when there's nothing breaking, so it never lies.
class BreakingPanel extends StatelessWidget {
  final List<Article> articles;
  final String Function(int feedId) sourceNameOf;
  final void Function(Article article) onTapArticle;

  const BreakingPanel({
    super.key,
    required this.articles,
    required this.sourceNameOf,
    required this.onTapArticle,
  });

  /// Pick at most 4 articles that look "breaking": published in the last
  /// 60 minutes, prioritising results, then transfers, then everything else.
  static List<Article> selectBreaking(List<Article> all) {
    final now = DateTime.now();
    final fresh = all
        .where((a) => now.difference(a.publishedAt).inMinutes <= 60)
        .toList();
    fresh.sort((a, b) {
      // Results-category bubbles up.
      int rank(Article x) {
        if (x.category == 'results') return 0;
        if (x.category == 'transfers') return 1;
        if (x.category == 'events') return 2;
        return 3;
      }

      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return fresh.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    if (articles.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: BnrSpacing.s5),
      decoration: BoxDecoration(
        color: ext.bg1,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BnrColors.live.withValues(alpha: 0.10),
            ext.bg1,
            ext.bg1,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        border: Border.all(
          color: BnrColors.live.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(BnrRadius.r3),
      ),
      child: Stack(
        children: [
          // Right-edge accent
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: BnrColors.live),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _head(),
                const SizedBox(height: 14),
                ...articles.asMap().entries.map((e) => _row(
                      context,
                      article: e.value,
                      isFirst: e.key == 0,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _head() {
    return Row(
      children: [
        const LiveDot(),
        const SizedBox(width: 8),
        Text(
          'BREAKING · LAST HOUR',
          style: AppTheme.mono(
            size: 11,
            color: BnrColors.live,
            weight: FontWeight.w600,
            letterSpacing: 0.18,
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required Article article,
    required bool isFirst,
  }) {
    final ext = context.bnr;

    return InkWell(
      onTap: () => onTapArticle(article),
      borderRadius: BorderRadius.circular(BnrRadius.r2),
      child: Container(
        margin: EdgeInsets.only(top: isFirst ? 0 : 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            top: isFirst
                ? BorderSide.none
                : BorderSide(color: ext.lineSoft, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sourceNameOf(article.feedId).toUpperCase(),
                        style: AppTheme.mono(
                          size: 10,
                          color: ext.fg1,
                          weight: FontWeight.w600,
                          letterSpacing: 0.12,
                        ),
                      ),
                      if (article.discipline != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 2,
                          height: 2,
                          decoration: BoxDecoration(
                            color: ext.fg3,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          article.discipline!.toUpperCase(),
                          style: AppTheme.mono(
                            size: 10,
                            color: BnrColors.disciplineColor(article.discipline),
                            weight: FontWeight.w600,
                            letterSpacing: 0.12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.serif(
                      size: isFirst ? 18 : 15,
                      weight: isFirst ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.012,
                      color: ext.fg0,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TimeAgo(time: article.publishedAt),
          ],
        ),
      ),
    );
  }
}

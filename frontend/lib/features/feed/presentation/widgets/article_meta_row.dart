import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/article.dart';
import 'live_dot.dart';
import 'time_ago.dart';

/// The mono-uppercase meta line that sits above every card title:
///   `LIVE   CYCLINGNEWS   ·   ROAD   ·   18M AGO   ·   EU`
class ArticleMetaRow extends StatelessWidget {
  final Article article;
  final String? sourceName;

  const ArticleMetaRow({
    super.key,
    required this.article,
    this.sourceName,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final disc = BnrColors.disciplineColor(article.discipline);
    final isLive = article.isLive;

    final children = <Widget>[];

    if (isLive) {
      children.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LiveDot(),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: AppTheme.mono(
              size: 11,
              color: BnrColors.live,
              weight: FontWeight.w600,
              letterSpacing: 0.06,
            ),
          ),
        ],
      ));
    }

    if (sourceName != null && sourceName!.isNotEmpty) {
      children.add(Text(
        sourceName!.toUpperCase(),
        style: AppTheme.mono(
          size: 11,
          color: ext.fg1,
          weight: FontWeight.w500,
          letterSpacing: 0.06,
        ),
      ));
    }

    if (article.discipline != null) {
      children.add(_dot(ext.fg3));
      children.add(Text(
        article.discipline!.toUpperCase(),
        style: AppTheme.mono(
          size: 11,
          color: disc,
          weight: FontWeight.w600,
          letterSpacing: 0.06,
        ),
      ));
    }

    children.add(_dot(ext.fg3));
    children.add(TimeAgo(time: article.publishedAt));

    if (article.region != null && article.region != 'world') {
      children.add(_dot(ext.fg3));
      children.add(Text(
        article.region!.toUpperCase(),
        style: AppTheme.mono(
          size: 11,
          color: ext.fg2,
          letterSpacing: 0.06,
        ),
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget _dot(Color color) => Container(
        width: 2,
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
}

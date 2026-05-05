import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../preferences/domain/entities/user_preferences.dart';
import '../../domain/entities/article.dart';
import 'article_meta_row.dart';
import 'cluster_row.dart';
import 'image_placeholder.dart';

/// Article card with three density variants (compact, comfort, large).
///
/// Comfort is the default — image left, body right, dense.
/// Compact is a row-based list with no image.
/// Large is a full-bleed image with hero treatment.
class ArticleCard extends StatefulWidget {
  final Article article;
  final CardDensity density;
  final bool selected;
  final bool read;
  final bool bookmarked;
  final String? sourceName;
  /// Names of any watched riders/teams that match this article. When non-empty,
  /// a "WATCHING · {first name}" badge is shown above the title.
  final List<String> watchedNames;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onHide;
  final VoidCallback? onShare;

  const ArticleCard({
    super.key,
    required this.article,
    required this.density,
    this.selected = false,
    this.read = false,
    this.bookmarked = false,
    this.sourceName,
    this.watchedNames = const [],
    this.onTap,
    this.onBookmark,
    this.onHide,
    this.onShare,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // Per-article ValueKey so integration tests can locate a specific
      // card when the feed renders multiple. The id-based key is stable
      // across rebuilds and locale switches.
      key: ValueKey('articleCard_${widget.article.id}'),
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: BnrMotion.m2,
          curve: BnrMotion.ease,
          transform: Matrix4.translationValues(0, _hover ? -1 : 0, 0),
          child: switch (widget.density) {
            CardDensity.compact => _buildCompact(context),
            CardDensity.comfort => _buildComfort(context),
            CardDensity.large => _buildLarge(context),
          },
        ),
      ),
    );
  }

  // ─────────────── Comfort (default) ───────────────
  Widget _buildComfort(BuildContext context) {
    final ext = context.bnr;
    final disc = BnrColors.disciplineColor(widget.article.discipline);

    return Container(
      margin: const EdgeInsets.only(bottom: BnrSpacing.s3),
      decoration: BoxDecoration(
        color: _hover || widget.selected ? ext.bg2 : ext.bg1,
        border: Border.all(
          color: _hover || widget.selected ? ext.line : ext.lineSoft,
        ),
        borderRadius: BorderRadius.circular(BnrRadius.r3),
        boxShadow: _hover
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Discipline accent bar (left)
          if (_hover || widget.selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: widget.selected ? 3 : 2,
                color: disc.withValues(alpha: widget.selected ? 1 : 0.6),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(BnrSpacing.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 132,
                  height: 88,
                  child: ImagePlaceholder(article: widget.article),
                ),
                const SizedBox(width: BnrSpacing.s4),
                Expanded(child: _buildBody(context, large: false)),
              ],
            ),
          ),
          if (_hover) _buildActions(ext),
        ],
      ),
    );
  }

  // ─────────────── Compact (list row) ───────────────
  Widget _buildCompact(BuildContext context) {
    final ext = context.bnr;
    final disc = BnrColors.disciplineColor(widget.article.discipline);

    return Container(
      decoration: BoxDecoration(
        color: _hover || widget.selected ? ext.bg2 : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: ext.lineSoft),
        ),
      ),
      child: Stack(
        children: [
          if (_hover || widget.selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: widget.selected ? 3 : 2,
                color: disc,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BnrSpacing.s4,
              vertical: BnrSpacing.s3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArticleMetaRow(
                  article: widget.article,
                  sourceName: widget.sourceName,
                ),
                const SizedBox(height: BnrSpacing.s1),
                Text(
                  widget.article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    letterSpacing: -0.005,
                    color: widget.read ? ext.fg2 : ext.fg0,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── Large (hero) ───────────────
  Widget _buildLarge(BuildContext context) {
    final ext = context.bnr;
    final disc = BnrColors.disciplineColor(widget.article.discipline);

    return Container(
      margin: const EdgeInsets.only(bottom: BnrSpacing.s5),
      decoration: BoxDecoration(
        color: _hover ? ext.bg2 : ext.bg1,
        border: Border.all(color: _hover ? ext.line : ext.lineSoft),
        borderRadius: BorderRadius.circular(BnrRadius.r3),
        boxShadow: _hover
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(BnrRadius.r3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ImagePlaceholder(
                    article: widget.article,
                    radius: 0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BnrSpacing.s5,
                    BnrSpacing.s5,
                    BnrSpacing.s5,
                    BnrSpacing.s6,
                  ),
                  child: _buildBody(context, large: true),
                ),
              ],
            ),
          ),
          if (_hover) _buildActions(ext),
          if (_hover || widget.selected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: widget.selected ? 3 : 2, color: disc),
            ),
        ],
      ),
    );
  }

  // ─────────────── Card body (title + desc) ───────────────
  Widget _buildBody(BuildContext context, {required bool large}) {
    final ext = context.bnr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArticleMetaRow(
          article: widget.article,
          sourceName: widget.sourceName,
        ),
        if (widget.watchedNames.isNotEmpty) ...[
          const SizedBox(height: BnrSpacing.s1),
          _watchingBadge(context),
        ],
        const SizedBox(height: BnrSpacing.s2),
        Text(
          widget.article.title,
          maxLines: large ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.serif(
            size: large ? 22 : 17,
            weight: FontWeight.w600,
            letterSpacing: large ? -0.018 : -0.012,
            color: widget.read ? ext.fg2 : ext.fg0,
            height: large ? 1.18 : 1.25,
          ),
        ),
        if (widget.article.description != null &&
            widget.article.description!.isNotEmpty) ...[
          const SizedBox(height: BnrSpacing.s2),
          Text(
            widget.article.description!,
            maxLines: large ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.sans(
              size: large ? 15 : 13,
              color: ext.fg1,
              height: large ? 1.55 : 1.45,
            ),
          ),
        ],
        if (widget.article.clusterCount > 0)
          ClusterRow(count: widget.article.clusterCount),
      ],
    );
  }

  Widget _watchingBadge(BuildContext context) {
    final ext = context.bnr;
    final discColor = BnrColors.disciplineColor(widget.article.discipline);
    final label = widget.watchedNames.length > 1
        ? '${widget.watchedNames.first} · +${widget.watchedNames.length - 1}'
        : widget.watchedNames.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: discColor.withValues(alpha: 0.14),
        border: Border.all(color: discColor.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(BnrRadius.r1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 11, color: discColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'WATCHING · ${label.toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.mono(
                size: 10,
                color: ext.fg0,
                weight: FontWeight.w600,
                letterSpacing: 0.10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── Hover actions (bookmark / hide / share) ───────────────
  Widget _buildActions(BnrThemeExt ext) {
    return Positioned(
      top: BnrSpacing.s2,
      right: BnrSpacing.s2,
      child: AnimatedOpacity(
        duration: BnrMotion.m2,
        opacity: _hover ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: ext.bg1.withValues(alpha: 0.85),
            border: Border.all(color: ext.line),
            borderRadius: BorderRadius.circular(BnrRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionBtn(
                icon: widget.bookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                onTap: widget.onBookmark,
                active: widget.bookmarked,
              ),
              _actionBtn(
                icon: Icons.visibility_off_outlined,
                onTap: widget.onHide,
              ),
              _actionBtn(
                icon: Icons.share_outlined,
                onTap: widget.onShare,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    VoidCallback? onTap,
    bool active = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BnrRadius.pill),
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(
            icon,
            size: 14,
            color: active ? BnrColors.accent : context.bnr.fg1,
          ),
        ),
      ),
    );
  }
}

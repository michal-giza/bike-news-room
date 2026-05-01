import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/url/safe_url.dart';
import '../../domain/entities/article.dart';
import '../widgets/article_meta_row.dart';
import '../widgets/image_placeholder.dart';

/// Bottom-sheet style modal for desktop and mobile. Shows the article hero,
/// AI summary block, description, and a "Read on [source]" CTA.
class ArticleDetailModal extends StatelessWidget {
  final Article article;
  final String? sourceName;
  final bool bookmarked;
  final VoidCallback? onBookmark;

  const ArticleDetailModal({
    super.key,
    required this.article,
    this.sourceName,
    this.bookmarked = false,
    this.onBookmark,
  });

  static Future<void> show(
    BuildContext context, {
    required Article article,
    String? sourceName,
    bool bookmarked = false,
    VoidCallback? onBookmark,
  }) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      barrierLabel: 'close',
      transitionDuration: BnrMotion.m3,
      pageBuilder: (_, __, ___) => ArticleDetailModal(
        article: article,
        sourceName: sourceName,
        bookmarked: bookmarked,
        onBookmark: onBookmark,
      ),
      transitionBuilder: (context, anim, _, child) {
        final tween = Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: BnrMotion.ease),
        );
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: tween.animate(anim).drive(
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ),
                ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 720;
    final maxModalWidth = isCompact ? size.width : 820.0;
    // Mobile: bottom-sheet style (no top corners). Desktop: centred card.
    final radius = isCompact
        ? const BorderRadius.only(
            topLeft: Radius.circular(BnrRadius.r4),
            topRight: Radius.circular(BnrRadius.r4),
          )
        : BorderRadius.circular(BnrRadius.r4);
    final maxModalHeight = isCompact ? size.height * 0.95 : size.height * 0.92;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: ColoredBox(
        color: Colors.transparent,
        child: Align(
          alignment: isCompact ? Alignment.bottomCenter : Alignment.center,
          child: GestureDetector(
            onTap: () {}, // swallow taps inside the modal
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxModalWidth,
                maxHeight: maxModalHeight,
              ),
              // Material is required for default text style + InkWell
              // and to suppress the yellow-underline debug rendering of
              // raw `Text` widgets inside an unstyled overlay.
              child: Material(
                color: ext.bg1,
                borderRadius: radius,
                clipBehavior: Clip.antiAlias,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: ext.fg0,
                    decoration: TextDecoration.none,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _header(context),
                      Flexible(child: _body(context, isCompact: isCompact)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final ext = context.bnr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: ext.bg1,
        border: Border(bottom: BorderSide(color: ext.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ArticleMetaRow(
              article: article,
              sourceName: sourceName,
            ),
          ),
          IconButton(
            icon: Icon(
              bookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 18,
              color: bookmarked ? BnrColors.accent : ext.fg1,
            ),
            tooltip: 'Bookmark',
            onPressed: onBookmark,
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, size: 18, color: ext.fg1),
            tooltip: 'Share',
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: ext.fg1),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, {required bool isCompact}) {
    final ext = context.bnr;
    final hPad = isCompact ? BnrSpacing.s4 : BnrSpacing.s8;
    final titleSize = isCompact ? 24.0 : 32.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        hPad,
        BnrSpacing.s5,
        hPad,
        BnrSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ImagePlaceholder(article: article, radius: BnrRadius.r3),
          ),
          const SizedBox(height: BnrSpacing.s5),
          Text(
            article.title,
            style: AppTheme.serif(
              size: titleSize,
              weight: FontWeight.w600,
              letterSpacing: -0.025,
              color: ext.fg0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: BnrSpacing.s3),
          _byline(context),
          const SizedBox(height: BnrSpacing.s5),
          if (article.description != null && article.description!.isNotEmpty)
            _summaryBlock(context, article.description!),
          // Description body (de-duplicated — only show below summary if it
          // adds substantial extra content, which after HTML stripping it
          // rarely does for RSS feeds. Skip the duplicate.)
          const SizedBox(height: BnrSpacing.s6),
          _readOnSourceButton(context),
        ],
      ),
    );
  }

  Widget _byline(BuildContext context) {
    final ext = context.bnr;
    final dateFmt =
        '${article.publishedAt.toLocal().year}-${_pad(article.publishedAt.toLocal().month)}-${_pad(article.publishedAt.toLocal().day)}';
    return Wrap(
      spacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          sourceName ?? 'Source',
          style: AppTheme.mono(size: 12, color: ext.fg1, letterSpacing: 0.04),
        ),
        Text('·', style: TextStyle(color: ext.fg3)),
        Text(
          dateFmt,
          style: AppTheme.mono(size: 12, color: ext.fg2),
        ),
        if (article.language != null) ...[
          Text('·', style: TextStyle(color: ext.fg3)),
          Text(
            article.language!.toUpperCase(),
            style: AppTheme.mono(size: 12, color: ext.fg2),
          ),
        ],
      ],
    );
  }

  /// Lead/summary block — uses the article's own description (the lead
  /// paragraph the publisher already wrote). The label was previously
  /// "AI SUMMARY" which was misleading: nothing in the pipeline calls an
  /// AI. Renamed to "SUMMARY" until/unless we wire up a real generator.
  Widget _summaryBlock(BuildContext context, String summary) {
    final ext = context.bnr;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: ext.bg2,
        border: Border(left: BorderSide(color: BnrColors.accent, width: 2)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(BnrRadius.r2),
          bottomRight: Radius.circular(BnrRadius.r2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: BnrColors.accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SUMMARY',
                style: AppTheme.mono(
                  size: 10,
                  color: BnrColors.accent,
                  weight: FontWeight.w600,
                  letterSpacing: 0.18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: AppTheme.sans(
              size: 14,
              color: ext.fg0,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnSourceButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: BnrColors.accent,
        foregroundColor: BnrColors.accentInk,
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BnrRadius.r2),
        ),
        textStyle: AppTheme.sans(weight: FontWeight.w600, size: 14),
      ),
      onPressed: () => _launch(article.url),
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(
        'Read on ${sourceName ?? "source"}',
        style: AppTheme.sans(
          weight: FontWeight.w600,
          size: 14,
          color: BnrColors.accentInk,
        ),
      ),
    );
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static Future<void> _launch(String url) async {
    final uri = safeUri(url);
    if (uri == null) return; // reject javascript:, data:, mailto:, malformed, etc.
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

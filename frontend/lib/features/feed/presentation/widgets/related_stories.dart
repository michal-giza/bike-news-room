import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/url/safe_url.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/article_model.dart';
import '../../domain/entities/article.dart';

/// "Other publications covering this story" — pulls the dedup cluster for
/// the current article. Only renders if `clusterCount > 0`, so it stays
/// invisible for unique stories.
class RelatedStories extends StatefulWidget {
  final Article article;
  const RelatedStories({super.key, required this.article});

  @override
  State<RelatedStories> createState() => _RelatedStoriesState();
}

class _RelatedStoriesState extends State<RelatedStories> {
  List<Article> _related = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.article.clusterCount <= 0) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final dio = getIt<ApiClient>().dio;
      final r = await dio.get<dynamic>(
        '/api/articles/${widget.article.id}/cluster',
      );
      final list = (r.data as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ArticleModel.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _related = list;
        _loading = false;
      });
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _related.isEmpty) return const SizedBox.shrink();
    final ext = context.bnr;
    return Padding(
      padding: const EdgeInsets.only(top: BnrSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).alsoCoveredBy,
            style: AppTheme.mono(
              size: 11,
              color: ext.fg2,
              letterSpacing: 0.18,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: BnrSpacing.s3),
          for (final a in _related) _RelatedRow(article: a),
        ],
      ),
    );
  }
}

class _RelatedRow extends StatelessWidget {
  final Article article;
  const _RelatedRow({required this.article});

  Future<void> _open() async {
    final uri = safeUri(article.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(BnrRadius.r2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BnrSpacing.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.north_east, size: 14, color: ext.fg2),
            const SizedBox(width: BnrSpacing.s3),
            Expanded(
              child: Text(
                article.title,
                style: AppTheme.sans(
                  size: 14,
                  color: ext.fg1,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

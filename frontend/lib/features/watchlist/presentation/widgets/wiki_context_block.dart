import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/datasources/wiki_context_remote_data_source.dart';

/// One-paragraph context block for an entity (rider / team / race).
/// Pure presentation — fetches its own data via the supplied
/// [WikiContextRemoteDataSource]. Self-hides if Wikipedia has no
/// article (the parent doesn't need to special-case the absence).
///
/// Stateful + StatefulWidget so the FutureBuilder re-runs when [title]
/// changes (e.g. when the user navigates between rider detail pages).
class WikiContextBlock extends StatefulWidget {
  /// Wikipedia title to look up. Usually the entity's display name —
  /// "Tadej Pogačar", "Tour de France". The backend handles the
  /// title normalisation + locale fallback.
  final String title;

  /// User's locale (e.g. `pl`). Backend tries this first then falls
  /// back to `en` if the requested locale has no article. Pass `null`
  /// to default to English server-side.
  final String? lang;

  /// Data source — injected so unit tests can use a fake without
  /// involving Dio / get_it.
  final WikiContextRemoteDataSource source;

  const WikiContextBlock({
    super.key,
    required this.title,
    required this.source,
    this.lang,
  });

  @override
  State<WikiContextBlock> createState() => _WikiContextBlockState();
}

class _WikiContextBlockState extends State<WikiContextBlock> {
  late Future<WikiContext?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.source.fetch(
      title: widget.title,
      lang: widget.lang ?? 'en',
    );
  }

  @override
  void didUpdateWidget(WikiContextBlock old) {
    super.didUpdateWidget(old);
    if (old.title != widget.title || old.lang != widget.lang) {
      setState(() {
        _future = widget.source.fetch(
          title: widget.title,
          lang: widget.lang ?? 'en',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return FutureBuilder<WikiContext?>(
      future: _future,
      builder: (context, snap) {
        // Self-hide while loading — parents already render an article
        // list above, no need to layer a loading skeleton on top.
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final ctx = snap.data;
        if (ctx == null) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.only(bottom: BnrSpacing.s4),
          padding: const EdgeInsets.all(BnrSpacing.s4),
          decoration: BoxDecoration(
            color: ext.bg1,
            border: Border.all(color: ext.lineSoft),
            borderRadius: BorderRadius.circular(BnrRadius.r2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ctx.thumbnailUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(BnrRadius.r1),
                  child: Image.network(
                    ctx.thumbnailUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 64, height: 64),
                  ),
                ),
                const SizedBox(width: BnrSpacing.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctx.title,
                      style: AppTheme.serif(
                        size: 16,
                        weight: FontWeight.w600,
                        color: ext.fg0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ctx.extract,
                      style: AppTheme.sans(
                        size: 13,
                        color: ext.fg1,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      key: const ValueKey('wikiContextSource'),
                      onTap: () => launchUrl(
                        Uri.parse(ctx.sourceUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        AppLocalizations.of(context).wikiSourceLink,
                        style: AppTheme.mono(
                          size: 11,
                          color: BnrColors.accent,
                          letterSpacing: 0.06,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

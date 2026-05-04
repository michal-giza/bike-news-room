import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/sharing/article_url.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/url/safe_url.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/article.dart';

/// One-tap share row inside the article-detail modal.
///
/// Each platform handles "share" differently:
///   - X / Bluesky / Reddit / Telegram / WhatsApp: open the platform's
///     share-intent URL in a new tab (works everywhere).
///   - **Copy link**: clipboard, with a one-shot "copied" snackbar.
///   - **Native share** (mobile-first): `share_plus` opens the OS share
///     sheet — only shown on mobile, where it actually feels native. On
///     web we'd duplicate Copy + the platform buttons.
///
/// Each button is small + iconographic so the row stays under one line on
/// narrow phones; the platform name is in the tooltip.
class ShareRow extends StatelessWidget {
  final Article article;
  const ShareRow({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    final url = articleShareUrl(article.id);
    // Tweet-length safe; X used to enforce 280 hard, now displays the URL
    // separately, but a clean prefix scans better in the timeline anyway.
    final text = article.title;

    return Container(
      margin: const EdgeInsets.only(top: BnrSpacing.s4),
      padding: const EdgeInsets.symmetric(
        horizontal: BnrSpacing.s4,
        vertical: BnrSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: ext.bg2,
        border: Border.all(color: ext.lineSoft),
        borderRadius: BorderRadius.circular(BnrRadius.r2),
      ),
      child: Row(
        children: [
          Text(
            l.shareNative.toUpperCase(),
            style: AppTheme.mono(
              size: 10,
              color: ext.fg2,
              letterSpacing: 0.18,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: BnrSpacing.s4),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _btn(
                  context,
                  icon: Icons.bookmark_outline,
                  label: l.shareCopy,
                  onTap: () => _copyLink(context, url),
                ),
                _btn(
                  context,
                  // No official X/Bluesky icon in Material; use a label-shaped
                  // glyph so the brand isn't impersonated.
                  icon: Icons.alternate_email,
                  label: l.shareXTwitter,
                  onTap: () => _openShareIntent(
                    'https://twitter.com/intent/tweet'
                    '?url=${Uri.encodeComponent(url)}'
                    '&text=${Uri.encodeComponent(text)}',
                  ),
                ),
                _btn(
                  context,
                  icon: Icons.cloud_outlined,
                  label: l.shareBluesky,
                  onTap: () => _openShareIntent(
                    'https://bsky.app/intent/compose'
                    '?text=${Uri.encodeComponent('$text $url')}',
                  ),
                ),
                _btn(
                  context,
                  icon: Icons.chat_bubble_outline,
                  label: l.shareWhatsApp,
                  onTap: () => _openShareIntent(
                    'https://wa.me/?text=${Uri.encodeComponent('$text $url')}',
                  ),
                ),
                _btn(
                  context,
                  icon: Icons.forum_outlined,
                  label: l.shareReddit,
                  onTap: () => _openShareIntent(
                    'https://www.reddit.com/submit'
                    '?url=${Uri.encodeComponent(url)}'
                    '&title=${Uri.encodeComponent(text)}',
                  ),
                ),
                _btn(
                  context,
                  icon: Icons.send_outlined,
                  label: l.shareTelegram,
                  onTap: () => _openShareIntent(
                    'https://t.me/share/url'
                    '?url=${Uri.encodeComponent(url)}'
                    '&text=${Uri.encodeComponent(text)}',
                  ),
                ),
                if (!kIsWeb)
                  _btn(
                    context,
                    icon: Icons.ios_share,
                    label: l.shareMore,
                    onTap: () => _nativeShare(text, url),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final ext = context.bnr;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BnrRadius.r1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ext.bg1,
            border: Border.all(color: ext.line),
            borderRadius: BorderRadius.circular(BnrRadius.r1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: ext.fg1),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.mono(
                  size: 10,
                  color: ext.fg1,
                  letterSpacing: 0.10,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openShareIntent(String url) async {
    final uri = safeUri(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).shareLinkCopiedShort),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _nativeShare(String text, String url) async {
    await SharePlus.instance.share(
      ShareParams(text: '$text\n\n$url', subject: text),
    );
  }
}

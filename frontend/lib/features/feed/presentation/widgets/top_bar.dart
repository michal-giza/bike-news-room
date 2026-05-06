import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/brand_mark.dart';

/// Sticky top bar: brand on the left, search pill in the centre, action icons on the right.
///
/// `topInset` is the system status-bar height (`MediaQuery.padding.top`)
/// captured at the construction site so `preferredSize` can include it
/// — Scaffold reads `preferredSize.height` BEFORE this widget builds, so
/// we cannot rely on a build-time MediaQuery lookup alone.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onBookmarksTap;
  final double topInset;

  static const double _contentHeight = 57;

  const TopBar({
    super.key,
    this.onSearchTap,
    this.onSettingsTap,
    this.onBookmarksTap,
    this.topInset = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(_contentHeight + topInset);

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    // Status-bar inset — Scaffold's `appBar` slot allocates extra height
    // for the system status bar but does NOT clip the contained widget
    // away from the inset (only Material's own `AppBar` does that
    // internally). On Android/iOS that meant the brand mark and search
    // pill were drawn UNDER the system battery + clock — the user
    // reported "topbar covered with system icons". Add the inset
    // explicitly so the chrome lives below the status bar; the
    // PreferredSize-side height accounts for the same inset (see
    // _height computation in preferredSize fallback below) so the
    // Scaffold's body still starts immediately after.
    // Prefer the inset captured at construction (used by Scaffold's
    // preferredSize before build runs) but fall back to a fresh
    // MediaQuery read for any consumer that uses TopBar outside a
    // Scaffold.appBar slot.
    final inset = topInset > 0
        ? topInset
        : MediaQuery.of(context).padding.top;
    return Container(
      height: _contentHeight + inset,
      decoration: BoxDecoration(
        color: ext.bg0.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(color: ext.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        BnrSpacing.s6,
        12 + inset,
        BnrSpacing.s6,
        12,
      ),
      child: Row(
        children: [
          // Wrap the brand in Flexible so accessibility text scales
          // (≥1.3x) cannot push the search pill + action icons off the
          // right edge — without this, the "Bike News Room" wordmark
          // claims its intrinsic width and the outer Row overflows.
          const Flexible(child: _Brand()),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _SearchPill(
                  key: const ValueKey('topBarSearchPill'),
                  onTap: onSearchTap,
                ),
              ),
            ),
          ),
          const Spacer(),
          _IconBtn(
            key: const ValueKey('topBarBookmarksBtn'),
            icon: Icons.bookmark_border,
            onTap: onBookmarksTap,
          ),
          _IconBtn(
            key: const ValueKey('topBarSettingsBtn'),
            icon: Icons.settings_outlined,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;

    return LayoutBuilder(
      builder: (context, c) {
        // Drop the BETA badge on narrow viewports / large text scales —
        // when the brand row gets less than ~150px the badge plus
        // wordmark plus icon won't fit without clipping. The wordmark +
        // icon are the primary identifiers; BETA is a nice-to-have we
        // can omit gracefully. Keeping the badge would either force
        // wordmark ellipsis to "Bike…" (worse identity) or push the
        // outer Row into overflow (caught by T1[scale≥1.3] sweep).
        final showBeta = c.maxWidth >= 150;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 24, color: ext.fg0),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Bike News Room',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AppTheme.serif(
                  size: 19,
                  weight: FontWeight.w700,
                  letterSpacing: -0.022,
                  color: ext.fg0,
                ),
              ),
            ),
            if (showBeta) ...[
              const SizedBox(width: 6),
              Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: ext.line),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'BETA',
            style: AppTheme.mono(
              size: 10,
              color: ext.fg2,
              letterSpacing: 0.18,
            ),
          ),
        ),
            ],
          ],
        );
      },
    );
  }
}

class _SearchPill extends StatefulWidget {
  final VoidCallback? onTap;
  const _SearchPill({super.key, this.onTap});

  @override
  State<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<_SearchPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: BnrMotion.m2,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hover ? ext.bg2 : ext.bg1,
            border: Border.all(color: _hover ? ext.fg3 : ext.line),
            borderRadius: BorderRadius.circular(BnrRadius.pill),
          ),
          child: LayoutBuilder(
            builder: (ctx, c) {
              // Responsive: pick the placeholder + show/hide the kbd hint
              // based on the pill's actual width. Without this the long
              // placeholder gets ellipsis-clipped on narrow topbars.
              final wide = c.maxWidth >= 360;
              final placeholder = wide
                  ? 'Search articles, riders, races…'
                  : 'Search…';
              return Row(
                children: [
                  Icon(Icons.search, size: 16, color: ext.fg2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sans(size: 14, color: ext.fg2),
                    ),
                  ),
                  // Keyboard hint only on viewports where a physical keyboard
                  // is realistic. Touch users don't have ⌘K.
                  if (wide) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: ext.line),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '⌘K',
                        style: AppTheme.mono(
                          size: 11,
                          color: ext.fg2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _IconBtn({super.key, required this.icon, this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: BnrMotion.m1,
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: _hover ? ext.bg2 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _hover ? ext.fg0 : ext.fg1,
          ),
        ),
      ),
    );
  }
}

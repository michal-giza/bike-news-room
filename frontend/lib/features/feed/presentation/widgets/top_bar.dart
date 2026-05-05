import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/brand_mark.dart';

/// Sticky top bar: brand on the left, search pill in the centre, action icons on the right.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onBookmarksTap;

  const TopBar({
    super.key,
    this.onSearchTap,
    this.onSettingsTap,
    this.onBookmarksTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(57);

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;

    return Container(
      height: 57,
      decoration: BoxDecoration(
        color: ext.bg0.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(color: ext.line)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: BnrSpacing.s6,
        vertical: 12,
      ),
      child: Row(
        children: [
          _Brand(),
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
  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;

    return Row(
      children: [
        BrandMark(size: 24, color: ext.fg0),
        const SizedBox(width: 10),
        Text(
          'Bike News Room',
          style: AppTheme.serif(
            size: 19,
            weight: FontWeight.w700,
            letterSpacing: -0.022,
            color: ext.fg0,
          ),
        ),
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

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';

enum BnrTab { feed, search, following, calendar, bookmarks }

/// Mobile bottom nav (matches `components.css` `.bottom-nav`).
class BottomNav extends StatelessWidget {
  final BnrTab active;
  final ValueChanged<BnrTab> onTap;

  const BottomNav({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Container(
      decoration: BoxDecoration(
        color: ext.bg0.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: ext.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        0,
        6,
        0,
        6 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn(context, BnrTab.feed, Icons.home_outlined, 'FEED'),
          _btn(context, BnrTab.following, Icons.person_outline, 'FOLLOWING'),
          _btn(context, BnrTab.search, Icons.search, 'SEARCH'),
          _btn(context, BnrTab.calendar, Icons.calendar_today_outlined, 'RACES'),
          _btn(context, BnrTab.bookmarks, Icons.bookmark_border, 'SAVED'),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, BnrTab tab, IconData icon, String label) {
    final ext = context.bnr;
    final on = tab == active;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: on ? BnrColors.accent : ext.fg2),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTheme.mono(
                  size: 10,
                  color: on ? ext.fg0 : ext.fg2,
                  letterSpacing: 0.06,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

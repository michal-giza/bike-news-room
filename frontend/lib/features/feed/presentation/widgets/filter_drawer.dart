import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/article.dart';
import 'sidebar.dart';

/// Mobile filter drawer — slides in from the left when the user taps the
/// filter icon. Reuses [Sidebar]'s contents inside a Drawer-like surface.
class FilterDrawer extends StatelessWidget {
  final ArticleFilter filter;
  final ValueChanged<String?> onDisciplineChanged;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onClearAll;
  final VoidCallback onClose;

  const FilterDrawer({
    super.key,
    required this.filter,
    required this.onDisciplineChanged,
    required this.onRegionChanged,
    required this.onCategoryChanged,
    required this.onClearAll,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Container(
      width: 320,
      color: ext.bg0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              BnrSpacing.s5,
              BnrSpacing.s5,
              BnrSpacing.s4,
              BnrSpacing.s4,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ext.line)),
            ),
            child: Row(
              children: [
                Text(
                  'FILTERS',
                  style: AppTheme.mono(
                    size: 11,
                    color: ext.fg0,
                    letterSpacing: 0.18,
                    weight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onClearAll,
                  child: Text(
                    'CLEAR',
                    style: AppTheme.mono(
                      size: 10,
                      color: ext.fg2,
                      letterSpacing: 0.12,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: ext.fg1),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: Sidebar(
              filter: filter,
              onDisciplineChanged: onDisciplineChanged,
              onRegionChanged: onRegionChanged,
              onCategoryChanged: onCategoryChanged,
              onClearAll: onClearAll,
            ),
          ),
        ],
      ),
    );
  }
}

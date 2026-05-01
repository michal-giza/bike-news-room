import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/article.dart';

/// Left sidebar with discipline/region/category sections + time toggles.
/// Stateless — emits filter changes through callbacks; the parent owns state.
class Sidebar extends StatelessWidget {
  final ArticleFilter filter;
  final ValueChanged<String?> onDisciplineChanged;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback? onClearAll;

  const Sidebar({
    super.key,
    required this.filter,
    required this.onDisciplineChanged,
    required this.onRegionChanged,
    required this.onCategoryChanged,
    this.onClearAll,
  });

  static const _disciplines = [
    ('road', 'Road'),
    ('mtb', 'MTB'),
    ('gravel', 'Gravel'),
    ('track', 'Track'),
    ('cx', 'Cyclocross'),
    ('bmx', 'BMX'),
  ];

  static const _regions = [
    ('world', 'World', '🌍'),
    ('eu', 'EU', '🇪🇺'),
    ('poland', 'Poland', '🇵🇱'),
    ('spain', 'Spain', '🇪🇸'),
  ];

  static const _categories = [
    ('results', 'Results'),
    ('transfers', 'Transfers'),
    ('equipment', 'Equipment'),
    ('events', 'Events'),
    ('general', 'General'),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;

    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: ext.line)),
      ),
      padding: const EdgeInsets.fromLTRB(
        BnrSpacing.s4,
        BnrSpacing.s6,
        BnrSpacing.s4,
        BnrSpacing.s12,
      ),
      child: ListView(
        children: [
          _section(
            context,
            'DISCIPLINE',
            children: _disciplines
                .map((d) => _SideItem(
                      label: d.$2,
                      selected: filter.discipline == d.$1,
                      disciplineColor: BnrColors.disciplineColor(d.$1),
                      showDot: true,
                      onTap: () => onDisciplineChanged(
                        filter.discipline == d.$1 ? null : d.$1,
                      ),
                    ))
                .toList(),
          ),
          _section(
            context,
            'REGION',
            children: _regions
                .map((r) => _SideItem(
                      label: r.$2,
                      flag: r.$3,
                      selected: filter.region == r.$1,
                      onTap: () => onRegionChanged(
                        filter.region == r.$1 ? null : r.$1,
                      ),
                    ))
                .toList(),
          ),
          _section(
            context,
            'CATEGORY',
            children: _categories
                .map((c) => _SideItem(
                      label: c.$2,
                      selected: filter.category == c.$1,
                      onTap: () => onCategoryChanged(
                        filter.category == c.$1 ? null : c.$1,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String label, {
    required List<Widget> children,
  }) {
    final ext = context.bnr;
    return Padding(
      padding: const EdgeInsets.only(bottom: BnrSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, BnrSpacing.s2),
            child: Text(
              label,
              style: AppTheme.mono(
                size: 10,
                color: ext.fg2,
                letterSpacing: 0.18,
                weight: FontWeight.w500,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SideItem extends StatefulWidget {
  final String label;
  final String? flag;
  final Color? disciplineColor;
  final bool showDot;
  final bool selected;
  final VoidCallback? onTap;

  const _SideItem({
    required this.label,
    this.flag,
    this.disciplineColor,
    this.showDot = false,
    this.selected = false,
    this.onTap,
  });

  @override
  State<_SideItem> createState() => _SideItemState();
}

class _SideItemState extends State<_SideItem> {
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
        child: Stack(
          children: [
            AnimatedContainer(
              duration: BnrMotion.m1,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: widget.selected
                    ? ext.bg2
                    : (_hover ? ext.bg1 : Colors.transparent),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  if (widget.showDot && widget.disciplineColor != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.disciplineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else if (widget.flag != null) ...[
                    Text(widget.flag!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: AppTheme.sans(
                      size: 14,
                      color: widget.selected || _hover ? ext.fg0 : ext.fg1,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Selected accent bar
            if (widget.selected)
              Positioned(
                left: -16,
                top: 6,
                bottom: 6,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: widget.disciplineColor ?? BnrColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

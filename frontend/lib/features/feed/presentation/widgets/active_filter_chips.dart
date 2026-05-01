import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../preferences/domain/entities/user_preferences.dart';
import '../../domain/entities/article.dart';

/// The "active filters" chip row + density toggle that sits above the feed list.
class ActiveFilterChips extends StatelessWidget {
  final ArticleFilter filter;
  final CardDensity density;
  final ValueChanged<CardDensity> onDensityChanged;
  final ValueChanged<String> onRemove;
  final VoidCallback? onClearAll;

  const ActiveFilterChips({
    super.key,
    required this.filter,
    required this.density,
    required this.onDensityChanged,
    required this.onRemove,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filter.region != null) {
      chips.add(_chip(context, label: filter.region!, kind: 'region'));
    }
    if (filter.discipline != null) {
      chips.add(_chip(context, label: filter.discipline!, kind: 'discipline'));
    }
    if (filter.category != null) {
      chips.add(_chip(context, label: filter.category!, kind: 'category'));
    }
    if (filter.search != null && filter.search!.isNotEmpty) {
      chips.add(_chip(context, label: '"${filter.search}"', kind: 'search'));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: BnrSpacing.s5),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...chips,
                if (chips.isNotEmpty)
                  TextButton(
                    onPressed: onClearAll,
                    child: Text(
                      'CLEAR ALL',
                      style: AppTheme.mono(
                        size: 10,
                        color: context.bnr.fg2,
                        letterSpacing: 0.12,
                      ),
                    ),
                  )
              ],
            ),
          ),
          _DensityToggle(
            current: density,
            onChanged: onDensityChanged,
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context,
      {required String label, required String kind}) {
    final ext = context.bnr;
    final isDiscipline = kind == 'discipline';
    final disc = isDiscipline ? BnrColors.disciplineColor(label) : null;

    return InkWell(
      onTap: () => onRemove(kind),
      borderRadius: BorderRadius.circular(BnrRadius.pill),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        decoration: BoxDecoration(
          color: ext.bg3,
          border: Border.all(color: disc ?? ext.fg3),
          borderRadius: BorderRadius.circular(BnrRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTheme.sans(
                size: 12,
                color: ext.fg0,
                weight: FontWeight.w500,
                letterSpacing: 0.04,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.close, size: 12, color: ext.fg3),
          ],
        ),
      ),
    );
  }
}

class _DensityToggle extends StatelessWidget {
  final CardDensity current;
  final ValueChanged<CardDensity> onChanged;

  const _DensityToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: ext.bg1,
        border: Border.all(color: ext.line),
        borderRadius: BorderRadius.circular(BnrRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final d in CardDensity.values) _btn(context, d),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, CardDensity d) {
    final ext = context.bnr;
    final on = d == current;
    return InkWell(
      onTap: () => onChanged(d),
      borderRadius: BorderRadius.circular(BnrRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: on ? ext.bg3 : Colors.transparent,
          borderRadius: BorderRadius.circular(BnrRadius.pill),
        ),
        child: Text(
          _label(d),
          style: AppTheme.mono(
            size: 11,
            color: on ? ext.fg0 : ext.fg2,
            letterSpacing: 0.10,
          ),
        ),
      ),
    );
  }

  String _label(CardDensity d) => switch (d) {
        CardDensity.compact => 'COMPACT',
        CardDensity.comfort => 'COMFORT',
        CardDensity.large => 'LARGE',
      };
}

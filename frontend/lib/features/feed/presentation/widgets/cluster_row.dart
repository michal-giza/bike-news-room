import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';

/// Compact "+N sources covering this" footer that shows under article cards
/// when the article has duplicates pointing at it.
///
/// We don't fetch the cluster eagerly — the count comes from the article
/// payload; the actual sibling list is loaded lazily by the modal.
class ClusterRow extends StatelessWidget {
  /// Number of additional sources covering the same story.
  final int count;

  /// Optional initials of those sources (when available — currently we don't
  /// have them in the list payload, so we render generic placeholders).
  final List<String> sourceInitials;

  const ClusterRow({
    super.key,
    required this.count,
    this.sourceInitials = const [],
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    if (count <= 0) return const SizedBox.shrink();

    final initials = sourceInitials.isNotEmpty
        ? sourceInitials.take(4).toList()
        : List<String>.generate(
            count.clamp(1, 4),
            (i) => String.fromCharCode(0x2022), // bullet placeholder
          );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: ext.lineSoft,
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
        ),
        child: Row(
          children: [
            // Stacked square chips
            SizedBox(
              height: 18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < initials.length; i++)
                    Positioned(
                      left: (i * 14).toDouble(),
                      child: _SourceChip(label: initials[i]),
                    ),
                ],
              ),
            ),
            SizedBox(width: 8 + (initials.length - 1) * 14.0),
            Text(
              '+$count source${count == 1 ? '' : 's'} covering this',
              style: AppTheme.mono(
                size: 11,
                color: ext.fg2,
                letterSpacing: 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  const _SourceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: ext.bg3,
        border: Border.all(color: ext.bg0, width: 1),
        borderRadius: BorderRadius.circular(BnrRadius.r1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTheme.mono(
          size: 9,
          color: ext.fg0,
          weight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

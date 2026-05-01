import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';

/// Mono uppercase relative time string. Designed to match `fmtAgo` from JSX.
class TimeAgo extends StatelessWidget {
  final DateTime time;
  const TimeAgo({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Text(
      _format(time),
      style: AppTheme.mono(
        size: 11,
        color: ext.fg2,
        letterSpacing: 0.06,
      ),
    );
  }

  static String _format(DateTime time) {
    final diffMin = DateTime.now().difference(time).inMinutes;
    if (diffMin < 1) return 'JUST NOW';
    if (diffMin < 60) return '${diffMin}M AGO';
    final diffH = diffMin ~/ 60;
    if (diffH < 24) return '${diffH}H AGO';
    final diffD = diffH ~/ 24;
    return '${diffD}D AGO';
  }
}

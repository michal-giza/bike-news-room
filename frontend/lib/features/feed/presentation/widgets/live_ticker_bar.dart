import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Compact running-headline strip shown above the feed when a Grand Tour is
/// live. Polls `/api/live-ticker` every 60s; renders nothing when the
/// backend returns an empty list, so it's invisible outside race weeks.
class LiveTickerBar extends StatefulWidget {
  const LiveTickerBar({super.key});

  @override
  State<LiveTickerBar> createState() => _LiveTickerBarState();
}

class _LiveTickerBarState extends State<LiveTickerBar> {
  static const _pollInterval = Duration(seconds: 60);

  Timer? _timer;
  List<_TickerEntry> _entries = const [];
  int _index = 0;
  Timer? _rotation;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
    // Rotate the visible headline every 6s so the bar feels alive even when
    // the backend hasn't pushed a fresh entry.
    _rotation = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _entries.length <= 1) return;
      setState(() => _index = (_index + 1) % _entries.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotation?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final dio = getIt<ApiClient>().dio;
      final r = await dio.get<dynamic>('/api/live-ticker', queryParameters: {
        'hours': 6,
        'limit': 20,
      });
      final raw = (r.data as Map<String, dynamic>?)?['entries'] as List? ?? [];
      final parsed = raw
          .whereType<Map<String, dynamic>>()
          .map(_TickerEntry.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _entries = parsed;
        if (_index >= _entries.length) _index = 0;
      });
    } catch (_) {
      // Silent — ticker is non-critical decoration.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();
    final ext = context.bnr;
    final entry = _entries[_index];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: BnrSpacing.s4,
        vertical: BnrSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: BnrColors.live.withValues(alpha: 0.12),
        border: Border(bottom: BorderSide(color: ext.lineSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: BnrColors.live,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).live,
            style: AppTheme.mono(
              size: 10,
              color: BnrColors.live,
              letterSpacing: 0.18,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: BnrSpacing.s3),
          Text(
            entry.raceName.toUpperCase(),
            style: AppTheme.mono(
              size: 10,
              color: ext.fg2,
              letterSpacing: 0.16,
            ),
          ),
          const SizedBox(width: BnrSpacing.s3),
          Expanded(
            child: AnimatedSwitcher(
              duration: BnrMotion.m3,
              child: Text(
                entry.headline,
                key: ValueKey(entry.id),
                style: AppTheme.sans(
                  size: 13,
                  color: ext.fg0,
                  weight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TickerEntry {
  final int id;
  final String raceName;
  final String headline;
  final String kind;
  final String? sourceUrl;

  const _TickerEntry({
    required this.id,
    required this.raceName,
    required this.headline,
    required this.kind,
    required this.sourceUrl,
  });

  factory _TickerEntry.fromJson(Map<String, dynamic> j) => _TickerEntry(
        id: (j['id'] as num).toInt(),
        raceName: j['race_name']?.toString() ?? '',
        headline: j['headline']?.toString() ?? '',
        kind: j['kind']?.toString() ?? 'update',
        sourceUrl: j['source_url']?.toString(),
      );
}

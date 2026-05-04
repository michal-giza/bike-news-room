import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../sources/presentation/widgets/add_source_modal.dart';
import '../../../watchlist/domain/entities/watched_entity.dart';
import '../../../watchlist/presentation/cubit/watchlist_cubit.dart';

/// Cmd+K search overlay. Matches `components.css` `.search-overlay`.
///
/// Self-contained: takes a [onSubmit] callback when the user picks/types.
/// Recent searches and suggested searches are passed in.
class SearchOverlay extends StatefulWidget {
  final List<String> recentSearches;
  final List<String> suggested;
  final ValueChanged<String> onSubmit;

  const SearchOverlay({
    super.key,
    this.recentSearches = const [],
    this.suggested = const [
      'Pogačar',
      'Vingegaard',
      'Vuelta',
      'Hardline',
      'Pidcock',
      'Roubaix',
    ],
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onSubmit,
    List<String> recentSearches = const [],
  }) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      barrierDismissible: true,
      barrierLabel: 'close',
      transitionDuration: BnrMotion.m2,
      pageBuilder: (_, __, ___) => SearchOverlay(
        onSubmit: onSubmit,
        recentSearches: recentSearches,
      ),
      transitionBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text != _query) {
        setState(() => _query = _controller.text);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    Navigator.of(context).pop();
    widget.onSubmit(trimmed);
  }

  void _follow(BuildContext context, WatchedEntity entity) {
    context.read<WatchlistCubit>().follow(entity);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(AppLocalizations.of(context).followingName(entity.name)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width < 720 ? width * 0.92 : 680.0;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: ColoredBox(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Align(
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Material(
                  color: ext.bg1,
                  borderRadius: BorderRadius.circular(BnrRadius.r4),
                  clipBehavior: Clip.antiAlias,
                  shadowColor: Colors.black.withValues(alpha: 0.6),
                  elevation: 24,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: ext.fg0,
                      decoration: TextDecoration.none,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _input(context, ext),
                        _followSection(context, ext),
                        _addSourceRow(context, ext),
                        if (widget.recentSearches.isNotEmpty)
                          _section(context, 'RECENT', widget.recentSearches),
                        _suggestedRow(context, ext),
                        _foot(context, ext),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(BuildContext context, BnrThemeExt ext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ext.line)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: ext.fg2),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onSubmitted: _submit,
              style: AppTheme.serif(
                size: 22,
                weight: FontWeight.w500,
                letterSpacing: -0.02,
                color: ext.fg0,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: AppLocalizations.of(context).searchHint,
                hintStyle: AppTheme.serif(
                  size: 22,
                  weight: FontWeight.w400,
                  color: ext.fg3,
                  letterSpacing: -0.02,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _followSection(BuildContext context, BnrThemeExt ext) {
    if (_query.trim().length < 2) return const SizedBox.shrink();
    return BlocBuilder<WatchlistCubit, WatchlistState>(
      builder: (context, state) {
        if (!state.ready) return const SizedBox.shrink();
        final matches = state.searchCatalogue(_query);
        if (matches.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Text(
                'FOLLOW',
                style: AppTheme.mono(
                  size: 10,
                  color: ext.fg2,
                  letterSpacing: 0.16,
                ),
              ),
            ),
            for (final entity in matches)
              InkWell(
                onTap: () => _follow(context, entity),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        switch (entity.kind) {
                          WatchedKind.team => Icons.groups_outlined,
                          WatchedKind.race => Icons.flag_outlined,
                          WatchedKind.rider => Icons.person_outline,
                        },
                        size: 14,
                        color: BnrColors.disciplineColor(entity.discipline),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entity.name,
                              style: AppTheme.sans(
                                size: 14,
                                color: ext.fg0,
                                weight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${entity.kind.name.toUpperCase()} · ${(entity.discipline ?? "").toUpperCase()}',
                              style: AppTheme.mono(
                                size: 10,
                                color: ext.fg2,
                                letterSpacing: 0.10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: BnrColors.accent,
                          borderRadius: BorderRadius.circular(BnrRadius.r1),
                        ),
                        child: Text(
                          AppLocalizations.of(context).follow,
                          style: AppTheme.mono(
                            size: 10,
                            color: BnrColors.accentInk,
                            weight: FontWeight.w600,
                            letterSpacing: 0.10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// "Don't see it? Add a source" — only shown once the user has typed
  /// enough to suggest they're hunting for content we don't have. Opens
  /// the [AddSourceModal] which lets them submit any RSS or website URL.
  Widget _addSourceRow(BuildContext context, BnrThemeExt ext) {
    if (_query.trim().length < 3) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: InkWell(
        onTap: () {
          // Pop the overlay first so the modal sits on a clean surface.
          Navigator.of(context).pop();
          AddSourceModal.show(context, prefillName: _query.trim());
        },
        borderRadius: BorderRadius.circular(BnrRadius.r2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: ext.bg2,
            border: Border.all(color: ext.line),
            borderRadius: BorderRadius.circular(BnrRadius.r2),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_link, size: 16, color: BnrColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).searchAddSourceTitle,
                      style: AppTheme.sans(
                        size: 13,
                        color: ext.fg0,
                        weight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).searchAddSourceBody,
                      style: AppTheme.sans(
                        size: 12,
                        color: ext.fg2,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, size: 14, color: ext.fg2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String label, List<String> items) {
    final ext = context.bnr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Text(
            label,
            style: AppTheme.mono(
              size: 10,
              color: ext.fg2,
              letterSpacing: 0.16,
            ),
          ),
        ),
        for (final item in items)
          InkWell(
            onTap: () => _submit(item),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.history, size: 14, color: ext.fg3),
                  const SizedBox(width: 10),
                  Text(
                    item,
                    style: AppTheme.sans(
                      size: 14,
                      color: ext.fg0,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _suggestedRow(BuildContext context, BnrThemeExt ext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final s in widget.suggested)
            InkWell(
              onTap: () => _submit(s),
              borderRadius: BorderRadius.circular(BnrRadius.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ext.bg2,
                  border: Border.all(color: ext.line),
                  borderRadius: BorderRadius.circular(BnrRadius.pill),
                ),
                child: Text(
                  s,
                  style: AppTheme.sans(size: 12, color: ext.fg1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _foot(BuildContext context, BnrThemeExt ext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ext.line)),
      ),
      child: Row(
        children: [
          _key(context, '↵'),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context).searchKeyToSearch,
            style: AppTheme.mono(size: 11, color: ext.fg2),
          ),
          const SizedBox(width: 16),
          _key(context, 'esc'),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context).searchKeyToClose,
            style: AppTheme.mono(size: 11, color: ext.fg2),
          ),
        ],
      ),
    );
  }

  Widget _key(BuildContext context, String label) {
    final ext = context.bnr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: ext.bg2,
        border: Border.all(color: ext.line),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: AppTheme.mono(
          size: 11,
          color: ext.fg1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

/// Hardware key listener that maps `Cmd+K` / `Ctrl+K` to a callback.
class CmdKShortcut extends StatelessWidget {
  final Widget child;
  final VoidCallback onTrigger;

  const CmdKShortcut({super.key, required this.child, required this.onTrigger});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
            const _OpenSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const _OpenSearchIntent(),
      },
      child: Actions(
        actions: {
          _OpenSearchIntent: CallbackAction<_OpenSearchIntent>(
            onInvoke: (_) {
              onTrigger();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

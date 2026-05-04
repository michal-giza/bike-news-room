import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/repositories/sources_repository.dart';
import '../cubit/sources_cubit.dart';
import 'suggested_sources.dart';

/// "Add a source" dialog — the entry point for users to teach Bike News Room
/// a new website. We keep the form minimal: URL is required, everything else
/// has a sensible default. The backend probes the URL and tells us whether
/// it found RSS or HTML articles; if neither, the use case rejects with a
/// precise error string we surface here.
class AddSourceModal extends StatefulWidget {
  /// Optional pre-fill — when the user opens this modal from "no search
  /// results" we plumb the search term in as the suggested name.
  final String? prefillName;
  const AddSourceModal({super.key, this.prefillName});

  static Future<void> show(BuildContext context, {String? prefillName}) {
    // Use rootNavigator so the modal pushes onto the application's root
    // overlay rather than whichever inner Navigator the caller's context
    // happens to belong to. This makes the dialog robust against being
    // opened from inside other dialogs (e.g. the search overlay), where
    // closing the parent dialog first would otherwise deactivate the
    // context and leave the modal pushed onto a stale navigator.
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => AddSourceModal(prefillName: prefillName),
    );
  }

  @override
  State<AddSourceModal> createState() => _AddSourceModalState();
}

class _AddSourceModalState extends State<AddSourceModal> {
  final _urlCtrl = TextEditingController();
  late final TextEditingController _nameCtrl;
  String _region = 'world';
  String _discipline = 'all';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.prefillName ?? '');
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Pre-fill the form from a curated-catalogue chip. We push the verified
  /// feed URL (not the homepage) so the backend probe is a single hop and
  /// always succeeds — the catalogue's whole point is to bypass the
  /// resolution waterfall for the most-used sites.
  void _applyCatalogueEntry(CatalogueEntry e) {
    setState(() {
      _urlCtrl.text = e.url;
      _nameCtrl.text = e.name;
      _region = _supportedRegions.contains(e.region) ? e.region : 'world';
      _discipline =
          _supportedDisciplines.contains(e.discipline) ? e.discipline : 'all';
    });
  }

  /// Lockstep with the items in `_regionDropdown` — keep them in sync.
  static const _supportedRegions = {'world', 'eu', 'poland', 'spain'};
  static const _supportedDisciplines = {
    'all',
    'road',
    'mtb',
    'gravel',
    'track',
    'cx',
    'bmx',
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final cubit = context.read<UserSourcesCubit>();
    final ok = await cubit.submit(AddSourceRequest(
      url: _urlCtrl.text.trim(),
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      region: _region == 'world' ? null : _region,
      discipline: _discipline == 'all' ? null : _discipline,
      language: null,
    ));
    if (!mounted) return;
    // Pop on the same navigator the dialog was pushed onto. Since `show`
    // uses `useRootNavigator: true`, popping the root navigator's
    // top-most route is what closes us — the inner pop would no-op when
    // the dialog is layered above other modal routes.
    if (ok) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width < 720 ? size.width * 0.94 : 540.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(BnrSpacing.s4),
      child: Material(
        color: ext.bg1,
        borderRadius: BorderRadius.circular(BnrRadius.r4),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: BlocBuilder<UserSourcesCubit, UserSourcesState>(
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(BnrSpacing.s6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _header(ext),
                      const SizedBox(height: BnrSpacing.s5),
                      SuggestedSources(onPick: _applyCatalogueEntry),
                      _urlField(ext),
                      const SizedBox(height: BnrSpacing.s4),
                      _nameField(ext),
                      const SizedBox(height: BnrSpacing.s4),
                      _tagsRow(ext),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: BnrSpacing.s4),
                        _errorBanner(ext, state.errorMessage!),
                      ],
                      const SizedBox(height: BnrSpacing.s6),
                      _actions(ext, state.submitting),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BnrThemeExt ext) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a source',
                style: AppTheme.serif(
                  size: 24,
                  weight: FontWeight.w600,
                  letterSpacing: -0.02,
                  color: ext.fg0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Paste any RSS feed or news website. We'll probe it and "
                'pick up its articles automatically.',
                style: AppTheme.sans(size: 13, color: ext.fg2, height: 1.45),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, size: 20, color: ext.fg1),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ],
    );
  }

  Widget _urlField(BnrThemeExt ext) {
    return TextFormField(
      controller: _urlCtrl,
      autofocus: true,
      keyboardType: TextInputType.url,
      autocorrect: false,
      style: AppTheme.sans(size: 15, color: ext.fg0),
      decoration: _input(ext, 'URL', 'https://example.com/feed'),
      validator: (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return 'URL is required';
        if (!s.startsWith('http')) return 'Must start with http:// or https://';
        return null;
      },
    );
  }

  Widget _nameField(BnrThemeExt ext) {
    return TextFormField(
      controller: _nameCtrl,
      style: AppTheme.sans(size: 15, color: ext.fg0),
      decoration: _input(
        ext,
        'Display name (optional)',
        'How should we label this source?',
      ),
    );
  }

  InputDecoration _input(BnrThemeExt ext, String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppTheme.mono(
        size: 11,
        color: ext.fg2,
        letterSpacing: 0.10,
      ),
      hintStyle: AppTheme.sans(size: 14, color: ext.fg3),
      filled: true,
      fillColor: ext.bg2,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: ext.line),
        borderRadius: BorderRadius.circular(BnrRadius.r2),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ext.line),
        borderRadius: BorderRadius.circular(BnrRadius.r2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: BnrColors.accent, width: 1.5),
        borderRadius: BorderRadius.circular(BnrRadius.r2),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: BnrColors.live),
        borderRadius: BorderRadius.circular(BnrRadius.r2),
      ),
    );
  }

  Widget _tagsRow(BnrThemeExt ext) {
    return Row(
      children: [
        Expanded(child: _regionDropdown(ext)),
        const SizedBox(width: BnrSpacing.s3),
        Expanded(child: _disciplineDropdown(ext)),
      ],
    );
  }

  Widget _regionDropdown(BnrThemeExt ext) {
    final l = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      initialValue: _region,
      style: AppTheme.sans(size: 14, color: ext.fg0),
      decoration: _input(ext, 'Region', ''),
      items: [
        DropdownMenuItem(value: 'world', child: Text(l.regionWorld)),
        DropdownMenuItem(value: 'eu', child: Text(l.regionEu)),
        DropdownMenuItem(value: 'poland', child: Text(l.regionPoland)),
        DropdownMenuItem(value: 'spain', child: Text(l.regionSpain)),
      ],
      onChanged: (v) => setState(() => _region = v ?? 'world'),
    );
  }

  Widget _disciplineDropdown(BnrThemeExt ext) {
    final l = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      initialValue: _discipline,
      style: AppTheme.sans(size: 14, color: ext.fg0),
      decoration: _input(ext, 'Discipline', ''),
      items: [
        DropdownMenuItem(value: 'all', child: Text(l.disciplineAll)),
        DropdownMenuItem(value: 'road', child: Text(l.disciplineRoad)),
        DropdownMenuItem(value: 'mtb', child: Text(l.disciplineMtb)),
        DropdownMenuItem(value: 'gravel', child: Text(l.disciplineGravel)),
        DropdownMenuItem(value: 'track', child: Text(l.disciplineTrack)),
        DropdownMenuItem(value: 'cx', child: Text(l.disciplineCx)),
        DropdownMenuItem(value: 'bmx', child: Text(l.disciplineBmx)),
      ],
      onChanged: (v) => setState(() => _discipline = v ?? 'all'),
    );
  }

  Widget _errorBanner(BnrThemeExt ext, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BnrColors.live.withValues(alpha: 0.10),
        border: Border.all(color: BnrColors.live.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(BnrRadius.r2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: BnrColors.live, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTheme.sans(size: 13, color: ext.fg0, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BnrThemeExt ext, bool submitting) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: submitting ? null : () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(
            'Cancel',
            style: AppTheme.sans(size: 13, color: ext.fg2),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: submitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: BnrColors.accent,
            foregroundColor: BnrColors.accentInk,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BnrRadius.r2),
            ),
          ),
          icon: submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(BnrColors.accentInk),
                  ),
                )
              : const Icon(Icons.add, size: 16),
          label: Text(
            submitting ? 'Probing…' : 'Add source',
            style: AppTheme.sans(
              size: 14,
              weight: FontWeight.w600,
              color: BnrColors.accentInk,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../info/presentation/pages/info_page.dart';

/// Footer call-to-action for the daily-digest email list. Lives at the
/// bottom of the feed so it's seen but never blocks the news. Sends one
/// POST to `/api/subscribers`; the backend then emails a confirmation.
class DigestSignup extends StatefulWidget {
  const DigestSignup({super.key});

  @override
  State<DigestSignup> createState() => _DigestSignupState();
}

enum _Status { idle, sending, sent, error }

class _DigestSignupState extends State<DigestSignup> {
  final _controller = TextEditingController();
  _Status _status = _Status.idle;
  String? _errorMessage;

  Future<void> _submit() async {
    final email = _controller.text.trim();
    final l = AppLocalizations.of(context);
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() {
        _status = _Status.error;
        _errorMessage = l.digestInvalidEmail;
      });
      return;
    }
    setState(() {
      _status = _Status.sending;
      _errorMessage = null;
    });
    try {
      final dio = getIt<ApiClient>().dio;
      await dio.post<dynamic>(
        '/api/subscribers',
        data: {'email': email},
      );
      if (!mounted) return;
      setState(() => _status = _Status.sent);
    } on DioException catch (e) {
      if (!mounted) return;
      // 400 means the address looked obviously wrong. Anything else is "we
      // couldn't reach the server" — surface a generic message either way.
      final detail =
          (e.response?.data is Map ? e.response?.data['error'] : null) ??
              l.digestNetworkError;
      setState(() {
        _status = _Status.error;
        _errorMessage = detail.toString();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _errorMessage = l.digestGenericError;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: BnrSpacing.s8),
      padding: const EdgeInsets.all(BnrSpacing.s6),
      decoration: BoxDecoration(
        color: ext.bg1,
        border: Border.all(color: ext.lineSoft),
        borderRadius: BorderRadius.circular(BnrRadius.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.digestHeadline,
            style: AppTheme.serif(
              size: 24,
              weight: FontWeight.w600,
              letterSpacing: -0.02,
              color: ext.fg0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.digestSubheadline,
            style: AppTheme.sans(size: 14, color: ext.fg2, height: 1.5),
          ),
          const SizedBox(height: BnrSpacing.s4),
          if (_status == _Status.sent)
            _SuccessRow()
          else
            _form(ext, l),
          const SizedBox(height: 8),
          Wrap(
            children: [
              Text(
                l.digestPrivacyPrefix,
                style: AppTheme.sans(size: 11, color: ext.fg2),
              ),
              InkWell(
                onTap: () =>
                    InfoPage.show(context, tab: InfoTab.privacy),
                child: Text(
                  l.digestPrivacyLink,
                  style: AppTheme.sans(
                    size: 11,
                    color: BnrColors.accent,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                l.digestPrivacySuffix,
                style: AppTheme.sans(size: 11, color: ext.fg2),
              ),
            ],
          ),
          if (_status == _Status.error && _errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppTheme.sans(
                size: 12,
                color: BnrColors.live,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _form(BnrThemeExt ext, AppLocalizations l) {
    final sending = _status == _Status.sending;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !sending,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: l.digestEmailHint,
              hintStyle: AppTheme.sans(size: 14, color: ext.fg2),
              filled: true,
              fillColor: ext.bg0,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: BnrSpacing.s4,
                vertical: BnrSpacing.s3,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BnrRadius.r2),
                borderSide: BorderSide(color: ext.lineSoft),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BnrRadius.r2),
                borderSide: BorderSide(color: ext.lineSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BnrRadius.r2),
                borderSide: BorderSide(color: BnrColors.accent, width: 2),
              ),
            ),
            style: AppTheme.sans(size: 14, color: ext.fg0),
          ),
        ),
        const SizedBox(width: BnrSpacing.s3),
        FilledButton(
          onPressed: sending ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: BnrColors.accent,
            foregroundColor: BnrColors.accentInk,
            padding: const EdgeInsets.symmetric(
              horizontal: BnrSpacing.s5,
              vertical: BnrSpacing.s3,
            ),
          ),
          child: sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BnrColors.accentInk,
                  ),
                )
              : Text(
                  l.digestSubscribe,
                  style: AppTheme.mono(
                    size: 11,
                    color: BnrColors.accentInk,
                    letterSpacing: 0.16,
                    weight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

class _SuccessRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ext = context.bnr;
    return Row(
      children: [
        Icon(Icons.mark_email_read_outlined, color: BnrColors.accent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context).digestSuccess,
            style: AppTheme.sans(size: 14, color: ext.fg0),
          ),
        ),
      ],
    );
  }
}

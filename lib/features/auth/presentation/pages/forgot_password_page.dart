import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:validators/validators.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers — classify raw exception messages
// ─────────────────────────────────────────────────────────────────────────────

bool _isRateLimitError(Object e) {
  final msg = e.toString().toLowerCase();
  return msg.contains('rate limit') ||
      msg.contains('429') ||
      msg.contains('too many requests');
}

bool _isNetworkError(Object e) {
  if (e is SocketException) return true;
  final msg = e.toString().toLowerCase();
  return msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('no address associated') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused') ||
      msg.contains('clientexception');
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool isLoading = false;

  bool get _isAr => ref.read(appLocaleProvider) is ArabicLocale;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ── Platform-aware error dialog ───────────────────────────────────────────
  Future<void> _showErrorDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    if (Platform.isIOS) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(_isAr ? 'حسناً' : 'OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_isAr ? 'حسناً' : 'OK'),
            ),
          ],
        ),
      );
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _autovalidateMode = AutovalidateMode.always);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => isLoading = true);

    try {
      final email = _emailController.text.trim();

      // ── Check if email is registered ──────────────────────────────────────
      final exists = await ref
          .read(authRepositoryProvider)
          .emailExists(email: email);

      if (!exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          snack(
            context,
            isError: true,
            message: _isAr
                ? 'هذا البريد الإلكتروني غير مسجل، يرجى إنشاء حساب جديد'
                : 'This email is not registered. Please sign up first.',
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      // ── Email exists → send OTP ───────────────────────────────────────────
      await ref.read(authRepositoryProvider).resetPasswordRequest(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        snack(
          context,
          message:
              '${context.tr('otp_sent')} $email, ${context.tr('check_inbox')}',
        ),
      );

      context.goNamed(
        RouteNames.verifyEmail,
        queryParameters: {'email': email, 'type': 'recovery'},
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      // ── Rate-limit error → dialog ─────────────────────────────────────────
      if (_isRateLimitError(e)) {
        await _showErrorDialog(
          title: _isAr ? 'تجاوزت الحد المسموح' : 'Rate Limit Exceeded',
          message: _isAr
              ? 'لقد تجاوزت الحد المسموح به. يرجى الانتظار قليلاً ثم المحاولة مجدداً.'
              : 'You have exceeded the allowed limit. Please wait a moment and try again.',
        );
        return;
      }

      // ── Network error → dialog ────────────────────────────────────────────
      if (_isNetworkError(e)) {
        await _showErrorDialog(
          title: _isAr ? 'خطأ في الاتصال' : 'Connection Error',
          message: _isAr
              ? 'حدث خطأ ما. يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.'
              : 'Something went wrong. Please check your internet connection and try again.',
        );
        return;
      }

      // ── Generic error → snackbar (unchanged behaviour) ────────────────────
      ScaffoldMessenger.of(context).showSnackBar(
        snack(
          context,
          isError: true,
          message: '${context.tr('error_prefix')}: ${e.toString()}',
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final langCode = isAr ? 'ar' : 'en';
    final cs = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(langCode, context);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            context.tr('forgot_password_title'),
            style: tt.titleMedium?.copyWith(
              color: cs.outline,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              autovalidateMode: _autovalidateMode,
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Subtitle ────────────────────────────────────────────
                  Text(
                    context.tr('enter_email_reset'),
                    textAlign: TextAlign.start,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Email field ─────────────────────────────────────────
                  AppTextField.email(
                    hint: context.tr('email'),
                    controller: _emailController,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.tr('enter_email');
                      }
                      if (!isEmail(value.trim())) {
                        return context.tr('valid_email');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Submit button ───────────────────────────────────────
                  AppButton.primary(
                    isLoading: isLoading,
                    label: context.tr('send_otp'),
                    onPressed: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

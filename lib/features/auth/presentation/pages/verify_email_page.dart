import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/app_typography.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  final String? email;
  final String? type; // 'signup' or 'recovery'

  const VerifyEmailPage({super.key, this.email, this.type});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  late StreamController<ErrorAnimationType> errorController;
  late TextEditingController textEditingController;

  String currentText = '';
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _resendTimer;
  bool _isVerifying = false;

  OtpType get otpType => isRecovery ? OtpType.recovery : OtpType.signup;
  bool get isRecovery => widget.type == 'recovery';

  @override
  void initState() {
    super.initState();
    errorController = StreamController<ErrorAnimationType>();
    textEditingController = TextEditingController();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    errorController.close();
    textEditingController.dispose();
    super.dispose();
  }

  // ── Countdown ─────────────────────────────────────────────────────────────
  void _startResendCountdown() {
    _resendTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  // ── Resend OTP ────────────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (!_canResend || _isVerifying || !mounted) return;

    final email = widget.email;
    if (email == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(snack(context, message: context.tr('no_email_found')));
      return;
    }

    try {
      if (isRecovery) {
        await Supabase.instance.client.auth.signInWithOtp(
          email: email,
          shouldCreateUser: false,
        );
      } else {
        await Supabase.instance.client.auth.resend(
          type: OtpType.signup,
          email: email,
        );
      }

      _startResendCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snack(
            context,
            message:
                '${context.tr('otp_resent')} $email, ${context.tr('check_inbox')}',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snack(
            context,
            isError: true,
            message: '${context.tr('error_resending')}: ${e.toString()}',
          ),
        );
      }
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<void> _verifyOtp(String token) async {
    if (_isVerifying || !mounted) return;
    setState(() => _isVerifying = true);

    final email = widget.email;
    if (email == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(snack(context, isError: true, message: 'No email found'));
      setState(() => _isVerifying = false);
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: otpType,
      );

      if (response.session == null) {
        throw Exception('Verification failed - no session created');
      }

      _resendTimer?.cancel();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        snack(
          context,
          message: isRecovery
              ? context.tr('recovery_success')
              : context.tr('verification_success'),
        ),
      );

      if (isRecovery) {
        context.goNamed(
          RouteNames.changePassword,
          queryParameters: {'from': 'forgot'},
        );
      }
    } catch (e) {
      if (mounted) {
        errorController.add(ErrorAnimationType.shake);
        textEditingController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          snack(
            context,
            isError: true,
            message: '${context.tr('verification_failed')}: ${e.toString()}',
          ),
        );
        setState(() => _isVerifying = false);
      }
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  Future<void> _cancel() async {
    if (!mounted) return;
    try {
      _resendTimer?.cancel();
      if (isRecovery) {
        context.goNamed(RouteNames.signin);
      } else {
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) context.goNamed(RouteNames.signin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snack(context, isError: true, message: 'Error: ${e.toString()}'),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;
    final langCode = isAr ? 'ar' : 'en';
    final cs = Theme.of(context).colorScheme;
    final tt = AppTypography.getTextTheme(langCode, context);
    final displayEmail = widget.email ?? 'your email';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AppButton.text(
                onPressed: _isVerifying ? null : _cancel,
                label: context.tr('cancel'),
                color: cs.secondary,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page title ──────────────────────────────────────────────
              Text(
                isRecovery
                    ? context.tr('password_recovery')
                    : context.tr('email_verification'),
                style: tt.headlineLarge,
              ),
              const SizedBox(height: 8),

              // ── Subtitle ────────────────────────────────────────────────
              Text(
                context.tr('enter_code'),
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),

              // ── Email chip ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayEmail,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── PIN field ───────────────────────────────────────────────
              PinCodeTextField(
                autovalidateMode: AutovalidateMode.disabled,
                autoFocus: true,
                appContext: context,
                pastedTextStyle: tt.bodyLarge?.copyWith(
                  color: cs.secondary,
                  fontWeight: FontWeight.w700,
                ),
                length: 6,
                animationType: AnimationType.fade,
                enabled: !_isVerifying,
                validator: (v) {
                  if (v!.length < 6) return context.tr('enter_complete_code');
                  return null;
                },
                pinTheme: PinTheme(
                  // Active (filled) cell
                  activeColor: cs.secondary,
                  activeFillColor: cs.surface,
                  // Selected (focused) cell
                  selectedColor: cs.secondary,
                  selectedFillColor: cs.surfaceContainerHighest,
                  // Inactive (empty unfocused) cell
                  inactiveColor: cs.onSurface.withValues(alpha: 0.2),
                  inactiveFillColor: cs.surface,
                  // Disabled
                  disabledColor: cs.onSurface.withValues(alpha: 0.1),
                  // Shape
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  borderWidth: 1.5,
                  fieldHeight: 54,
                  fieldWidth: 46,
                ),
                cursorColor: cs.secondary,
                animationDuration: const Duration(milliseconds: 250),
                enableActiveFill: true,
                errorAnimationController: errorController,
                controller: textEditingController,
                keyboardType: TextInputType.number,
                textStyle: tt.headlineSmall?.copyWith(color: cs.onSurface),
                boxShadows: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    color: cs.shadow.withValues(alpha: 0.06),
                    blurRadius: 8,
                  ),
                ],
                onCompleted: _verifyOtp,
                onChanged: (value) {
                  if (mounted) setState(() => currentText = value);
                },
                beforeTextPaste: (_) => true,
              ),

              const SizedBox(height: 8),

              // ── Loading indicator ───────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isVerifying
                    ? Padding(
                        key: const ValueKey('loader'),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: cs.secondary,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('empty'), height: 0),
              ),

              const SizedBox(height: 16),

              // ── Resend row ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr('didnt_get_email'),
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _canResend
                      ? AppButton.text(
                          onPressed: !_isVerifying ? _resendOtp : null,
                          label: context.tr('resend_code'),
                          color: cs.secondary,
                        )
                      : Text(
                          // Show countdown as "Resend in 42s"
                          '${isAr ? 'إعادة الإرسال خلال' : 'Resend in'} $_resendCountdown${isAr ? 'ث' : 's'}',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

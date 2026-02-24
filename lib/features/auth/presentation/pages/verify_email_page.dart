import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/constants/theme/app_colors.dart';
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
  String currentText = "";
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _resendTimer;
  bool _isVerifying = false;

  // FIXED: Use correct OTP type for password recovery
  // OtpType.recovery matches resetPasswordForEmail
  // OtpType.signup matches signUp
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

  Future<void> _resendOtp() async {
    if (!_canResend || _isVerifying || !mounted) return;

    final email = widget.email;

    if (email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snack(context, message: context.tr('no_email_found')),
        );
      }
      return;
    }

    try {
      // FIXED: Resend OTP using signInWithOtp for recovery
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

  Future<void> _verifyOtp(String token) async {
    if (_isVerifying || !mounted) return;

    setState(() => _isVerifying = true);

    final email = widget.email;

    if (email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snack(context, message: 'No email found'),
        );
        setState(() => _isVerifying = false);
      }
      return;
    }

    try {
      // FIXED: Verify OTP with correct type
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type:
            otpType, // Uses OtpType.email for recovery, OtpType.signup for signup
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

      // Navigate based on type
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

  Future<void> _cancel() async {
    if (!mounted) return;

    try {
      _resendTimer?.cancel();

      if (isRecovery) {
        context.goNamed(RouteNames.signin);
      } else {
        // For signup, sign out and go to sign in
        final repository = ref.read(authRepositoryProvider);
        await repository.signOut();
        if (mounted) {
          context.goNamed(RouteNames.signin);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snack(context, isError: true, message: 'Error: ${e.toString()}'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = widget.email ?? 'your email';
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          AppButton.text(
            onPressed: _isVerifying ? null : _cancel,
            label: context.tr('cancel'),
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRecovery
                  ? context.tr('password_recovery')
                  : context.tr('email_verification'),
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('enter_code'),
              style: theme.textTheme.titleSmall,
            ),
            Text(
              displayEmail,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.secondary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: PinCodeTextField(
                autovalidateMode: AutovalidateMode.disabled,
                autoFocus: true,
                appContext: context,
                pastedTextStyle: const TextStyle(
                  color: AppColors.lightGreenSecondary,
                  fontWeight: FontWeight.bold,
                ),
                length: 6,
                animationType: AnimationType.fade,
                enabled: !_isVerifying,
                validator: (v) {
                  if (v!.length < 6) return context.tr('enter_complete_code');
                  return null;
                },
                pinTheme: PinTheme(
                  inactiveFillColor: Colors.transparent,
                  inactiveColor: Colors.black,
                  selectedColor: AppColors.lightGreenSecondary,
                  selectedFillColor: Colors.white,
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(5),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: Colors.white,
                  disabledColor: Colors.grey,
                ),
                cursorColor: Theme.of(context).colorScheme.secondary,
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                errorAnimationController: errorController,
                controller: textEditingController,
                keyboardType: TextInputType.number,
                boxShadows: const [
                  BoxShadow(
                    offset: Offset(0, 1),
                    color: Colors.black12,
                    blurRadius: 10,
                  ),
                ],
                onCompleted: (v) {
                  _verifyOtp(v);
                },
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      currentText = value;
                    });
                  }
                },
                beforeTextPaste: (text) {
                  return true;
                },
              ),
            ),
            if (_isVerifying)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  context.tr('didnt_get_email'),
                  style: theme.textTheme.titleMedium,
                ),
                AppButton.text(
                  onPressed: _canResend && !_isVerifying ? _resendOtp : null,
                  label: context.tr('resend_code'),
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

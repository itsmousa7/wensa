import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:validators/validators.dart';

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
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => isLoading = true);

    try {
      final email = _emailController.text.trim();
      final repo = ref.read(authRepositoryProvider);

      // Check if email exists first
      // final exists = await repo.emailExists(email: email);
      // if (!exists) {
      //   if (!mounted) return;
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('No account found with this email')),
      //   );
      //   setState(() => isLoading = false);
      //   return;
      // }

      // Send OTP (now correctly uses signInWithOtp)
      await repo.resetPasswordRequest(email: email);

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
      ScaffoldMessenger.of(context).showSnackBar(
        snack(
          context,
          isError: true,
          message: '${context.tr('error_prefix')}: ${e.toString()}',
        ),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('forgot_password_title')),
      ),
      body: Center(
        child: Form(
          autovalidateMode: _autovalidateMode,
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('enter_email_reset'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 16),
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
    );
  }
}

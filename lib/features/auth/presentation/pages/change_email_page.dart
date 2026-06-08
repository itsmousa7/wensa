import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/core/widgets/glass_back_button.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:validators/validators.dart';

class ChangeEmailPage extends ConsumerStatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  ConsumerState<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends ConsumerState<ChangeEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _isLoading = false;

  String get _currentEmail =>
      Supabase.instance.client.auth.currentUser?.email ?? '';

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newEmail = _emailController.text.trim();
      await ref.read(authRepositoryProvider).updateEmail(newEmail);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        snack(context, message: context.tr('email_change_otp_sent')),
      );

      context.goNamed(
        RouteNames.verifyEmail,
        queryParameters: {'email': newEmail, 'type': 'email_change'},
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final isAlreadyRegistered = msg.contains('already registered') ||
          msg.contains('already in use') ||
          msg.contains('already been registered') ||
          msg.contains('email address already') ||
          msg.contains('user already');
      ScaffoldMessenger.of(context).showSnackBar(
        snack(
          context,
          isError: true,
          message: isAlreadyRegistered
              ? context.tr('email_already_registered')
              : '${context.tr('error_prefix')}: ${e.toString()}',
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: GlassBackButton.appBarLeading(),
        leadingWidth: GlassBackButton.appBarLeadingWidth,
        title: Text(
          context.tr('change_email'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.outline,
              ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentEmail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _currentEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ),
              AppTextField.email(
                hint: context.tr('new_email'),
                controller: _emailController,
                focusNode: _emailFocus,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('enter_new_email');
                  }
                  if (!isEmail(value.trim())) {
                    return context.tr('valid_email');
                  }
                  if (value.trim().toLowerCase() ==
                      _currentEmail.toLowerCase()) {
                    return context.tr('email_same_as_current');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              AppButton.filled(
                onPressed: _isLoading ? null : _submit,
                label: context.tr('update_email'),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

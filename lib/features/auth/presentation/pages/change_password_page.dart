import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/core/utils/error_dialog.dart';
import 'package:future_riverpod/features/auth/domain/models/custom_error.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/snack_bar.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key, this.fromForgotPassword = false});
  final bool fromForgotPassword;
  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .updatePassword(_newPasswordController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        snack(context, message: context.tr('password_updated')),
      );

      if (widget.fromForgotPassword) {
        // Sign out first so the router doesn't redirect to /home
        await ref.read(authRepositoryProvider).signOut();
        if (!mounted) return;
        context.goNamed(RouteNames.signin);
      } else {
        context.goNamed(RouteNames.profile);
      }
    } catch (e) {
      if (!mounted) return;
      errorDialog(context, e as CustomError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.goNamed(RouteNames.profile),
          icon: const Icon(Icons.arrow_back_outlined),
        ),
        title: Text(context.tr('change_password')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField.password(
                controller: _newPasswordController,
                enabled: !_isLoading,
                hint: context.tr('new_password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('enter_new_password');
                  }
                  if (value.length < 6) return context.tr('password_length');
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AppTextField.password(
                controller: _confirmPasswordController,
                enabled: !_isLoading,
                hint: context.tr('confirm_password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('confirm_your_password');
                  }
                  if (value != _newPasswordController.text) {
                    return context.tr('passwords_not_match');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              AppButton.filled(
                onPressed: _isLoading ? null : _submit,
                label: context.tr('update_password'),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

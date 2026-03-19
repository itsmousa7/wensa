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
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:go_router/go_router.dart';

class ChangeNamePage extends ConsumerStatefulWidget {
  final String? accessToken;
  const ChangeNamePage({super.key, this.accessToken});

  @override
  ConsumerState<ChangeNamePage> createState() => _ChangeNamePageState();
}

class _ChangeNamePageState extends ConsumerState<ChangeNamePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  bool _isLoading = false;

  // First Name ➜ Second Name ✓
  final _firstNameFocus = FocusNode();
  final _secondNameFocus = FocusNode();

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _firstNameFocus.dispose();
    _secondNameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .updateUserProfile(
            firstName: _firstNameController.text.trim(),
            secondName: _secondNameController.text.trim(),
          );
      ref.invalidate(profileProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(snack(context, message: context.tr('name_updated')));

      context.goNamed(RouteNames.profile);
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
        title: Text(
          context.tr('change_name'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField.name(
                controller: _firstNameController,
                enabled: !_isLoading,
                hint: context.tr('new_first_name'),
                focusNode: _firstNameFocus,
                nextFocusNode: _secondNameFocus, // ➜ Second Name
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('enter_new_name');
                  }
                  if (value.length < 2) return context.tr('name_length');
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AppTextField.name(
                controller: _secondNameController,
                enabled: !_isLoading,
                hint: context.tr('new_second_name'),
                focusNode: _secondNameFocus,
                // no nextFocusNode → Done key dismisses keyboard ✓
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('enter_second_name_field');
                  }
                  if (value.length < 2) return context.tr('name_length');
                  return null;
                },
              ),
              const SizedBox(height: 30),
              AppButton.filled(
                onPressed: _isLoading ? null : _submit,
                label: context.tr('update_name'),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

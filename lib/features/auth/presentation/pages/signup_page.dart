import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/core/utils/error_dialog.dart';
import 'package:future_riverpod/features/auth/presentation/providers/signup_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/ref_listener.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:validators/validators.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final email = _emailController.text.trim();

    // Wait for signup to complete
    await ref
        .read(signupProvider.notifier)
        .signup(
          firstName: _firstNameController.text.trim(),
          secondName: _secondNameController.text.trim(),
          email: email,
          password: _passwordController.text.trim(),
        );

    // Only navigate if signup was successful (no error)
    if (!mounted) return;

    final signupState = ref.read(signupProvider);
    if (!signupState.hasError) {
      context.goNamed(
        RouteNames.verifyEmail,
        queryParameters: {'email': email},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen(signupProvider, (prev, next) {
      listenAsyncProvider(
        context: context,
        prev: prev,
        next: next,
        onLoading: null,
        onError: (error) => errorDialog(context, error),
      );
    });
    final signupState = ref.watch(signupProvider);
    final isLoading = signupState.isLoading;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: ListView(
                shrinkWrap: true,
                reverse: true,
                children: [
                  Text(
                    context.tr('sign_up'),
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Gap(20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AppTextField(
                          hint: context.tr('first_name'),
                          controller: _firstNameController,
                          enabled: !isLoading,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr('enter_first_name');
                            }
                            if (value.trim().length < 2) {
                              return context.tr('name_length');
                            }
                            return null;
                          },
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: AppTextField(
                          hint: context.tr('second_name'),
                          controller: _secondNameController,
                          enabled: !isLoading,

                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return context.tr('enter_second_name');
                            }
                            if (value.trim().length < 2) {
                              return context.tr('name_length');
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(30),
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
                  const Gap(30),
                  AppTextField.password(
                    hint: context.tr('password'),
                    controller: _passwordController,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.tr('enter_password');
                      }
                      if (value.trim().length < 6) {
                        return context.tr('password_length');
                      }
                      return null;
                    },
                  ),
                  const Gap(50),

                  AppButton.filled(
                    onPressed: isLoading ? null : _submit,
                    label: context.tr('sign_up'),
                    isLoading: isLoading,
                  ),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('have_account'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      AppButton.text(
                        label: context.tr('log_in'),
                        color: theme.colorScheme.primary,
                        onPressed: isLoading
                            ? null
                            : () => context.goNamed(RouteNames.signin),
                      ),
                    ],
                  ),
                ].reversed.toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

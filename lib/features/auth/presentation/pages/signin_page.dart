import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:future_riverpod/core/constants/theme/theme_provider.dart';
import 'package:future_riverpod/core/constants/theme/theme_state.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/core/utils/error_dialog.dart';
import 'package:future_riverpod/features/auth/domain/models/custom_error.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:future_riverpod/features/auth/presentation/providers/google_auth_provider.dart';
import 'package:future_riverpod/features/auth/presentation/providers/signin_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/ref_listener.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:validators/validators.dart';

class SigninPage extends ConsumerStatefulWidget {
  const SigninPage({super.key});

  @override
  ConsumerState<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends ConsumerState<SigninPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  void _submit() {
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(signinProvider.notifier)
        .signin(_emailController.text.trim(), _passwordController.text);
  }

  Future<void> _handleEmailNotConfirmed(String email) async {
    try {
      await ref
          .read(authRepositoryProvider)
          .resendOTP(email: email, type: OtpType.signup);

      if (!mounted) return;

      context.goNamed(
        RouteNames.verifyEmail,
        queryParameters: {'email': email}, // was: extra: email
      );
    } catch (e) {
      if (!mounted) return;
      errorDialog(context, e as CustomError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeProvider);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    ref.listen(signinProvider, (prev, next) {
      listenAsyncProvider(
        context: context,
        prev: prev,
        next: next,
        onError: (error) {
          if (error.message == 'Email not confirmed') {
            final email = _emailController.text.trim();
            _handleEmailNotConfirmed(email);
            return;
          }
          errorDialog(context, error);
        },
      );
    });
    ref.listen(googleAuthProvider, (prev, next) {
      listenAsyncProvider(
        context: context,
        prev: prev,
        next: next,
        onLoading: () => showLoadingDialog(context),
        onError: (error) => errorDialog(context, error),
      );
    });

    final isLoading = ref.watch(signinProvider).isLoading;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          actions: [
            AppButton.icon(
              onPressed: () => ref.read(appThemeProvider.notifier).toggle(),
              icon: Icon(switch (currentTheme) {
                LightTheme() => CupertinoIcons.sun_max,
                DarkTheme() => CupertinoIcons.moon,
                SystemTheme() =>
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark
                      ? CupertinoIcons.moon
                      : CupertinoIcons.sun_max,
              }),
            ),

            IconButton(
              onPressed: () => ref.read(appLocaleProvider.notifier).toggle(),
              icon: Icon(switch (ref.watch(appLocaleProvider)) {
                ArabicLocale() => Icons.language, // showing AR → tap for EN
                _ => Icons.language_outlined, // showing EN → tap for AR
              }),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingScreen,
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('sign_in'),
                      style: theme.textTheme.displayMedium,
                    ),

                    const Gap(AppSpacing.xl),
                    AppTextField.email(
                      controller: _emailController,
                      enabled: !isLoading,
                      hint: context.tr('email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('enter_email');
                        }
                        if (!isEmail(value.trim())) {
                          return context.tr('valid_email');
                        }
                        return null;
                      },
                      onSubmitted: (_) {},
                    ),
                    const Gap(AppSpacing.mlg),
                    AppTextField.password(
                      hint: context.tr('password'),
                      controller: _passwordController,
                      enabled: !isLoading,

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('enter_password');
                        }
                        if (value.length < 6) {
                          return context.tr('password_length');
                        }
                        return null;
                      },
                      onSubmitted: (_) => _submit(),
                    ),
                    const Gap(AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton.text(
                        label: context.tr('forgot_password'),
                        color: theme.colorScheme.primary,
                        fullWidth: false,
                        onPressed: isLoading
                            ? null
                            : () => context.push('/forgot-password'),
                      ),
                    ),
                    const Gap(AppSpacing.lg),
                    AppButton.filled(
                      label: context.tr('login'),
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _submit,
                    ),
                    const Gap(AppSpacing.xl),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            context.tr('or'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const Gap(AppSpacing.lg),
                    AppButton.secondary(
                      onPressed: () async {
                        await ref
                            .read(googleAuthProvider.notifier)
                            .signInWithGoogle();
                        // Don't navigate manually — GoRouterRefreshNotifier handles it
                      },
                      color: theme.colorScheme.outline,
                      icon: SvgPicture.asset(
                        'assets/icons/google.svg',
                        width: width * 0.02,
                        height: height * 0.02,
                      ),
                      label: context.tr('continue_google'),
                    ),

                    const Gap(20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('no_account'),
                          style: theme.textTheme.bodyMedium,
                        ),
                        AppButton.text(
                          label: context.tr('sign_up'),
                          fullWidth: false,
                          color: theme.colorScheme.primary,
                          onPressed: isLoading
                              ? null
                              : () => context.goNamed(RouteNames.signup),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

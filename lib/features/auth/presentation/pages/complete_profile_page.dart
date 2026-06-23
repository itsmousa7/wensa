import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_locale_provider.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/constants/locale/locale_state.dart';
import 'package:future_riverpod/core/utils/error_dialog.dart';
import 'package:future_riverpod/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:future_riverpod/features/auth/presentation/providers/complete_profile_provider.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/ref_listener.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:gap/gap.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  final _phoneFocus = FocusNode();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  PhoneNumber? _phoneNumber;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _autovalidateMode = AutovalidateMode.always);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final phone = _phoneNumber?.completeNumber ?? '';
    if (phone.isEmpty) return;

    // The name is NOT collected here (see [isProfileComplete] / Sign in with
    // Apple guidelines). Preserve whatever name the auth provider already gave
    // us so the upsert never blanks it; if there is none yet, it is captured
    // later in the booking flow.
    final profile = ref.read(profileProvider).value;

    await ref
        .read(completeProfileProvider.notifier)
        .submit(
          firstName: profile?.firstName.trim() ?? '',
          secondName: profile?.secondName.trim() ?? '',
          phone: phone,
        );
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = ref.watch(appLocaleProvider) is ArabicLocale;

    ref.listen(completeProfileProvider, (prev, next) {
      listenAsyncProvider(
        context: context,
        prev: prev,
        next: next,
        onLoading: null,
        onError: (error) => errorDialog(context, error),
      );
    });

    final asyncState = ref.watch(completeProfileProvider);
    final isLoading = asyncState.isLoading;

    return PopScope(
      canPop: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode,
                child: ListView(
                  children: [
                    const Gap(40),
                    Text(
                      context.tr('complete_profile_title'),
                      style:
                          (isAr
                                  ? theme.textTheme.displaySmall
                                  : theme.textTheme.displayMedium)
                              ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const Gap(12),
                    Text(
                      context.tr('complete_profile_subtitle'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Gap(32),
                    // Only the phone number is collected here. The user's name
                    // is never requested at this auth step — Sign in with Apple
                    // already provides it (and only on first authorization), so
                    // re-asking would violate its guidelines. Any missing name
                    // is captured later inside the booking flow.
                    _PhoneField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      enabled: !isLoading,
                      onChanged: (phone) => _phoneNumber = phone,
                      invalidNumberMessage: context.tr('valid_phone'),
                      hint: context.tr('phone_number'),
                      emptyMessage: context.tr('enter_phone'),
                    ),
                    const Gap(40),
                    AppButton.filled(
                      onPressed: isLoading ? null : _submit,
                      label: context.tr('save'),
                      isLoading: isLoading,
                    ),
                    const Gap(8),
                    AppButton.text(
                      label: context.tr('sign_out'),
                      color: theme.colorScheme.primary,
                      onPressed: isLoading ? null : _signOut,
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

/// Phone input themed to match [AppTextField] — same fill, radius and error
/// colors. The country selector defaults to Iraq (+964).
class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.invalidNumberMessage,
    required this.hint,
    required this.emptyMessage,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<PhoneNumber> onChanged;
  final String invalidNumberMessage;
  final String hint;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    OutlineInputBorder border({Color? color}) => OutlineInputBorder(
      borderRadius: AppSpacing.borderRadiusLG,
      borderSide: color == null ? BorderSide.none : BorderSide(color: color),
    );

    return Theme(
      data: theme.copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: theme.colorScheme.primary.withValues(alpha: 0.4),
          selectionHandleColor: theme.colorScheme.primary,
        ),
      ),
      child: IntlPhoneField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        languageCode: languageCode,
        initialCountryCode: 'IQ',
        invalidNumberMessage: invalidNumberMessage,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        validator: (phone) {
          if (phone == null || phone.number.trim().isEmpty) {
            return emptyMessage;
          }
          return null;
        },
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.outline,
        ),
        dropdownTextStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.outline,
        ),
        dropdownIcon: Icon(
          Icons.arrow_drop_down,
          color: theme.colorScheme.outline,
        ),
        flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 12),
        showCountryFlag: true,
        showDropdownIcon: true,
        cursorColor: theme.colorScheme.secondary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainer,
          counterText: '',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          enabledBorder: border(),
          border: border(),
          focusedBorder: border(color: theme.colorScheme.secondary),
          errorBorder: border(color: theme.colorScheme.errorContainer),
          focusedErrorBorder: border(color: theme.colorScheme.errorContainer),
        ),
      ),
    );
  }
}

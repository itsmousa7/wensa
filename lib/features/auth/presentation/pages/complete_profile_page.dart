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
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';
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
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _secondNameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  PhoneNumber? _phoneNumber;
  bool _prefilled = false;

  /// True once we know the profile already carries a full name (e.g. supplied
  /// by Sign in with Apple / Google). When set, the name inputs are hidden so
  /// we never re-ask for information the auth provider already gave us — only
  /// the phone number (which Apple does not provide) is collected here.
  bool _nameKnown = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _phoneController.dispose();
    _firstNameFocus.dispose();
    _secondNameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _prefillFromProfile() {
    if (_prefilled) return;
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    _firstNameController.text = profile.firstName;
    _secondNameController.text = profile.secondName;
    _nameKnown =
        profile.firstName.trim().isNotEmpty &&
        profile.secondName.trim().isNotEmpty;
    _prefilled = true;
  }

  Future<void> _submit() async {
    setState(() => _autovalidateMode = AutovalidateMode.always);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final phone = _phoneNumber?.completeNumber ?? '';
    if (phone.isEmpty) return;

    await ref
        .read(completeProfileProvider.notifier)
        .submit(
          firstName: _firstNameController.text.trim(),
          secondName: _secondNameController.text.trim(),
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

    _prefillFromProfile();

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
                    // Name inputs are shown only when we don't already have a
                    // name. When Sign in with Apple / Google shares the name it
                    // is persisted and these stay hidden (just collect phone);
                    // when the user hides/withholds it, the framework gives us
                    // nothing, so asking here is allowed (not a Guideline 4
                    // violation) and the fields are shown alongside the phone.
                    if (!_nameKnown) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField.name(
                              hint: context.tr('first_name'),
                              controller: _firstNameController,
                              enabled: !isLoading,
                              focusNode: _firstNameFocus,
                              nextFocusNode: _secondNameFocus,
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
                            child: AppTextField.name(
                              hint: context.tr('second_name'),
                              controller: _secondNameController,
                              enabled: !isLoading,
                              focusNode: _secondNameFocus,
                              nextFocusNode: _phoneFocus,
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
                      const Gap(20),
                    ],
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';
import 'package:future_riverpod/features/auth/domain/repositories/profile_repository.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:gap/gap.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gates the booking flow on having a full name AND a phone number on file.
///
/// Neither the name nor the phone number is required at the authentication
/// step (see [isProfileComplete]): Sign in with Apple only returns the name on
/// the very first authorization, and Apple's guideline 5.1.1(v) forbids
/// requiring personal information (such as a phone number) that is not needed
/// to create the account. Both are instead collected here — once, prefilled
/// from any value we already hold — because attaching a name and a contact
/// number to a *reservation* is a legitimate functional requirement of that
/// transaction rather than an account-creation gate. Once the profile carries
/// both, this widget renders its [child] directly and is never seen again.
class BookingDetailsGate extends ConsumerStatefulWidget {
  const BookingDetailsGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BookingDetailsGate> createState() => _BookingDetailsGateState();
}

class _BookingDetailsGateState extends ConsumerState<BookingDetailsGate> {
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
  bool _saving = false;

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

  bool _hasName(String first, String second) =>
      first.trim().isNotEmpty && second.trim().isNotEmpty;

  bool _hasPhone(String? phone) => (phone ?? '').trim().isNotEmpty;

  Future<void> _save(bool isAr) async {
    setState(() => _autovalidateMode = AutovalidateMode.always);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final phone = _phoneNumber?.completeNumber ?? '';
    if (phone.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      // updateProfile only writes the fields we pass — email/city/etc. are
      // left untouched, so this never clobbers data collected elsewhere.
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            userId,
            firstName: _firstNameController.text.trim(),
            secondName: _secondNameController.text.trim(),
            phone: phone,
          );
      ref.invalidate(profileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تعذّر حفظ البيانات. حاول مرة أخرى.'
                  : 'Could not save your details. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // On a profile fetch error we still let the user supply their details so
      // the booking isn't dead-ended; the save path repairs the row.
      error: (_, _) => _detailsForm(context, isAr),
      data: (profile) {
        if (_hasName(profile.firstName, profile.secondName) &&
            _hasPhone(profile.phone)) {
          return widget.child;
        }
        if (!_prefilled) {
          _firstNameController.text = profile.firstName;
          _secondNameController.text = profile.secondName;
          _prefilled = true;
        }
        return _detailsForm(context, isAr);
      },
    );
  }

  Widget _detailsForm(BuildContext context, bool isAr) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: ListView(
            children: [
              const Gap(24),
              Text(
                isAr ? 'بيانات الحجز' : 'Details for your booking',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const Gap(8),
              Text(
                isAr
                    ? 'نحتاج اسمك ورقم هاتفك لإتمام الحجز وتأكيده.'
                    : 'We need your name and phone number to complete and '
                          'confirm the booking.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Gap(24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField.name(
                      hint: isAr ? 'الاسم الأول' : 'First name',
                      controller: _firstNameController,
                      enabled: !_saving,
                      focusNode: _firstNameFocus,
                      nextFocusNode: _secondNameFocus,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return isAr
                              ? 'أدخل الاسم الأول'
                              : 'Enter your first name';
                        }
                        if (value.trim().length < 2) {
                          return isAr ? 'الاسم قصير جداً' : 'Name is too short';
                        }
                        return null;
                      },
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: AppTextField.name(
                      hint: isAr ? 'الاسم الثاني' : 'Last name',
                      controller: _secondNameController,
                      enabled: !_saving,
                      focusNode: _secondNameFocus,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return isAr
                              ? 'أدخل الاسم الثاني'
                              : 'Enter your last name';
                        }
                        if (value.trim().length < 2) {
                          return isAr ? 'الاسم قصير جداً' : 'Name is too short';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const Gap(16),
              _PhoneField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                enabled: !_saving,
                onChanged: (phone) => _phoneNumber = phone,
                invalidNumberMessage: isAr
                    ? 'رقم هاتف غير صالح'
                    : 'Invalid phone number',
                hint: isAr ? 'رقم الهاتف' : 'Phone number',
                emptyMessage: isAr
                    ? 'أدخل رقم هاتفك'
                    : 'Enter your phone number',
              ),
              const Gap(32),
              AppButton.filled(
                onPressed: _saving ? null : () => _save(isAr),
                label: isAr ? 'متابعة' : 'Continue',
                isLoading: _saving,
              ),
            ],
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

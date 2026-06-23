import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/auth/domain/repositories/profile_repository.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_text_field.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gates the booking flow on having a full name on file.
///
/// Sign in with Apple only returns the user's name on their first ever
/// authorization, so we never require it at the auth step (see
/// [isProfileComplete]). Instead, the name is collected here — once, prefilled
/// from any value the auth provider did give us — because attaching a name to a
/// reservation is a legitimate functional requirement rather than an
/// authentication gate. Once the profile carries a name this widget renders its
/// [child] directly and is never seen again.
class BookingNameGate extends ConsumerStatefulWidget {
  const BookingNameGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BookingNameGate> createState() => _BookingNameGateState();
}

class _BookingNameGateState extends ConsumerState<BookingNameGate> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _firstNameFocus = FocusNode();
  final _secondNameFocus = FocusNode();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _prefilled = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _firstNameFocus.dispose();
    _secondNameFocus.dispose();
    super.dispose();
  }

  bool _hasName(String first, String second) =>
      first.trim().isNotEmpty && second.trim().isNotEmpty;

  Future<void> _save(bool isAr) async {
    setState(() => _autovalidateMode = AutovalidateMode.always);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      // updateProfile only writes the fields we pass — phone/email/etc. are
      // left untouched, so this never clobbers data collected elsewhere.
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            userId,
            firstName: _firstNameController.text.trim(),
            secondName: _secondNameController.text.trim(),
          );
      ref.invalidate(profileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تعذّر حفظ الاسم. حاول مرة أخرى.'
                  : 'Could not save your name. Please try again.',
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
      // On a profile fetch error we still let the user supply a name so the
      // booking isn't dead-ended; the save path repairs the row.
      error: (_, _) => _nameForm(context, isAr),
      data: (profile) {
        if (_hasName(profile.firstName, profile.secondName)) {
          return widget.child;
        }
        if (!_prefilled) {
          _firstNameController.text = profile.firstName;
          _secondNameController.text = profile.secondName;
          _prefilled = true;
        }
        return _nameForm(context, isAr);
      },
    );
  }

  Widget _nameForm(BuildContext context, bool isAr) {
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
                isAr ? 'الاسم على الحجز' : 'Name for your booking',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const Gap(8),
              Text(
                isAr
                    ? 'نحتاج اسمك لإتمام الحجز.'
                    : 'We need your name to complete the booking.',
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

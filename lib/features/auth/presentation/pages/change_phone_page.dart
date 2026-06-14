import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/core/constants/locale/app_strings_extentions.dart';
import 'package:future_riverpod/core/router/router_names.dart';
import 'package:future_riverpod/core/widgets/glass_back_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/app_button.dart';
import 'package:future_riverpod/features/auth/presentation/widgets/snack_bar.dart';
import 'package:future_riverpod/features/auth/domain/repositories/profile_repository.dart';
import 'package:future_riverpod/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:future_riverpod/core/constants/theme/app_spacing.dart';

class ChangePhonePage extends ConsumerStatefulWidget {
  const ChangePhonePage({super.key});

  @override
  ConsumerState<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends ConsumerState<ChangePhonePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();

  PhoneNumber? _phoneNumber;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final phone = _phoneNumber?.completeNumber ?? '';
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await ref.read(profileRepositoryProvider).updateProfile(
            userId,
            phone: phone,
          );
      ref.invalidate(profileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(snack(context, message: context.tr('phone_updated')));
      context.goNamed(RouteNames.profile);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        snack(context, isError: true, message: context.tr('error_prefix')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    OutlineInputBorder border({Color? color}) => OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusLG,
          borderSide:
              color == null ? BorderSide.none : BorderSide(color: color),
        );

    return Scaffold(
      appBar: AppBar(
        leading: GlassBackButton.appBarLeading(),
        leadingWidth: GlassBackButton.appBarLeadingWidth,
        title: Text(
          context.tr('change_phone'),
          style: theme.textTheme.titleMedium
              ?.copyWith(color: cs.outline),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Theme(
                data: theme.copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: cs.primary.withValues(alpha: 0.4),
                    selectionHandleColor: cs.primary,
                  ),
                ),
                child: IntlPhoneField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  enabled: !_isLoading,
                  initialCountryCode: 'IQ',
                  invalidNumberMessage: context.tr('valid_phone'),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (phone) => _phoneNumber = phone,
                  validator: (phone) {
                    if (phone == null || phone.number.trim().isEmpty) {
                      return context.tr('enter_phone');
                    }
                    return null;
                  },
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: cs.outline),
                  dropdownTextStyle: theme.textTheme.bodyLarge
                      ?.copyWith(color: cs.outline),
                  dropdownIcon: Icon(Icons.arrow_drop_down, color: cs.outline),
                  flagsButtonPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  showCountryFlag: true,
                  showDropdownIcon: true,
                  cursorColor: cs.secondary,
                  decoration: InputDecoration(
                    hintText: context.tr('phone_number'),
                    hintStyle: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    filled: true,
                    fillColor: cs.surfaceContainer,
                    counterText: '',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    enabledBorder: border(),
                    border: border(),
                    focusedBorder: border(color: cs.secondary),
                    errorBorder: border(color: cs.errorContainer),
                    focusedErrorBorder: border(color: cs.errorContainer),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              AppButton.filled(
                onPressed: _isLoading ? null : _submit,
                label: context.tr('update_phone'),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

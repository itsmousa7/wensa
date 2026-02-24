import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app text field with consistent styling
class AppTextField extends StatefulWidget {
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final String? helperText;
  final String? errorText;
  final bool showPasswordToggle;

  const AppTextField({
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.helperText,
    this.errorText,
    this.showPasswordToggle = false,

    super.key,
  });

  /// Email text field
  const AppTextField.email({
    this.hint = 'Email',
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,

    super.key,
  }) : obscureText = false,
       keyboardType = TextInputType.emailAddress,
       textInputAction = TextInputAction.next,
       maxLines = 1,
       maxLength = null,
       readOnly = false,
       prefixIcon = const Icon(CupertinoIcons.envelope),
       suffixIcon = null,
       onTap = null,
       inputFormatters = null,
       textCapitalization = TextCapitalization.none,
       helperText = null,
       errorText = null,
       showPasswordToggle = false;

  /// Password text field with toggle visibility
  const AppTextField.password({
    this.hint = 'Password',
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,

    super.key,
  }) : obscureText = true,
       keyboardType = TextInputType.visiblePassword,
       maxLines = 1,
       maxLength = null,
       readOnly = false,
       prefixIcon = const Icon(CupertinoIcons.lock),
       suffixIcon = null,
       onTap = null,
       inputFormatters = null,
       textCapitalization = TextCapitalization.none,
       helperText = null,
       errorText = null,
       showPasswordToggle = true;

  /// Phone text field
  const AppTextField.phone({
    this.hint = 'Phone Number',
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,

    super.key,
  }) : obscureText = false,
       keyboardType = TextInputType.phone,
       textInputAction = TextInputAction.next,
       maxLines = 1,
       maxLength = null,
       readOnly = false,
       prefixIcon = const Icon(CupertinoIcons.phone),
       suffixIcon = null,
       onTap = null,
       inputFormatters = null,
       textCapitalization = TextCapitalization.none,
       helperText = null,
       errorText = null,
       showPasswordToggle = false;

  /// Multiline text field
  const AppTextField.text({
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.maxLines = 5,
    this.maxLength,
    this.enabled = true,
    this.focusNode,

    super.key,
  }) : obscureText = false,
       keyboardType = TextInputType.multiline,
       textInputAction = TextInputAction.newline,
       readOnly = false,
       prefixIcon = null,
       suffixIcon = null,
       onTap = null,
       onSubmitted = null,
       inputFormatters = null,
       textCapitalization = TextCapitalization.sentences,
       helperText = null,
       errorText = null,
       showPasswordToggle = false;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build suffix icon (with password toggle if needed)
    Widget? suffixIcon = widget.suffixIcon;
    if (widget.showPasswordToggle) {
      suffixIcon = IconButton(
        icon: Icon(
          _obscureText ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
          color: theme.colorScheme.primary,
        ),
        onPressed: _togglePasswordVisibility,
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: theme.colorScheme.primary.withValues(alpha: 0.4),
          selectionHandleColor: theme.colorScheme.primary,
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: _obscureText ? 1 : widget.maxLines,
        maxLength: widget.maxLength,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        inputFormatters: widget.inputFormatters,
        focusNode: widget.focusNode,
        textCapitalization: widget.textCapitalization,
        cursorColor: theme.colorScheme.secondary,
        cursorErrorColor: theme.colorScheme.errorContainer,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hint,
          helperText: widget.helperText,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: suffixIcon,
          counterText: widget.maxLength != null ? null : '',
          filled: true,
          fillColor: theme.colorScheme.surfaceContainer,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(
              color: theme.colorScheme.secondary,
            ),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: InputBorder.none,
          errorBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(16),
            ),
            borderSide: BorderSide(
              color: theme.colorScheme.errorContainer,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(16),
            ),
            borderSide: BorderSide(
              color: theme.colorScheme.errorContainer,
            ),
          ),
        ),
      ),
    );
  }
}

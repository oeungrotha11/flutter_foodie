import 'package:flutter/material.dart';

/// Shared Foodie form field styling and common TextFormField options.
///
/// Keep validation and controller ownership in each screen so the widget can
/// be reused for login, registration, profile, delivery, and password forms.
class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.helperText,
    this.maxLength,
    this.counterText,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.onUserInteractionIfError,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final String? helperText;
  final int? maxLength;
  final String? counterText;
  final ValueChanged<String>? onChanged;
  final AutovalidateMode autovalidateMode;

  static const Color _primaryColor = Color(0xFFF5233B);

  @override
  Widget build(BuildContext context) {
    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Colors.grey, width: 0.8),
    );

    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: autovalidateMode,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        
        labelText: labelText,
        hintText: hintText ?? 'Enter ${labelText.toLowerCase()}',
        helperText: helperText,
        counterText: counterText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 16, color: _primaryColor),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 35,
          minHeight: 35,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        errorStyle: const TextStyle(fontSize: 10),
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: _primaryColor, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red, width: 0.8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }
}

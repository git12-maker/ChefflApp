import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Reusable styled text field for authentication screens
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      autofocus: autofocus,
      enabled: enabled,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: isDark ? AppColors.darkOnBackground : AppColors.lightOnBackground,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.grey400 : AppColors.grey600,
        ),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.grey600 : AppColors.grey400,
        ),
      ),
    );
  }
}

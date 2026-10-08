import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Compact and responsive text field:
/// - Compact height (~40dp) with dense content padding
/// - Maximum width constraint preventing endless stretching on desktop/wide viewports
/// - Clear accessible label, helper, error slot, and tactile focus border
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final double? maxWidth;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onEditingComplete,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxWidth = AppConstants.maxFormWidth,
  });

  @override
  Widget build(BuildContext context) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.gapXs,
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          readOnly: readOnly,
          enabled: enabled,
          maxLength: maxLength,
          maxLines: maxLines,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            prefixText: prefixText,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: AppRadius.radiusSm,
            ),
            helperMaxLines: 1,
            errorMaxLines: 2,
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );

    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: field,
      );
    }

    return field;
  }
}

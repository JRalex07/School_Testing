import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outlined, destructive, text }

/// Compact, accessible, and tactile Claymorphic Button:
/// - Compact height (~40dp default, 36dp compact, 44dp standard)
/// - Soft claymorphic extruded shadow on primary/secondary buttons
/// - Visible focus, hover, and active feedback
/// - Spinner loading state preserving button dimensions
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final bool isCompact;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.isCompact = false,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.isCompact = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.outlined({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.isCompact = false,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.destructive({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.isCompact = false,
  }) : variant = AppButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final buttonHeight = isCompact
        ? AppConstants.compactControlHeight
        : AppConstants.standardControlHeight;

    Widget buttonChild;
    if (isLoading) {
      final spinnerColor = (variant == AppButtonVariant.outlined || variant == AppButtonVariant.text)
          ? AppColors.primary
          : Colors.white;
      buttonChild = SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: isCompact
                ? AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)
                : AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        text,
        style: isCompact
            ? AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)
            : AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
      );
    }

    Widget btn;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case AppButtonVariant.primary:
        btn = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: Size(fullWidth ? double.infinity : 40, buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            elevation: 1.5,
            shadowColor: AppColors.primary.withAlpha(90),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.secondary:
        btn = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.primaryContainer,
            foregroundColor: isDark ? Colors.white : AppColors.onPrimaryContainer,
            minimumSize: Size(fullWidth ? double.infinity : 40, buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.outlined:
        btn = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(fullWidth ? double.infinity : 40, buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            side: const BorderSide(color: AppColors.primary, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.destructive:
        btn = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onError,
            minimumSize: Size(fullWidth ? double.infinity : 40, buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            elevation: 1.5,
            shadowColor: AppColors.error.withAlpha(90),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.text:
        btn = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(fullWidth ? double.infinity : 36, buttonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
          ),
          child: buttonChild,
        );
        break;
    }

    return btn;
  }
}

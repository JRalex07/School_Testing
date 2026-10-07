import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outlined, destructive, text }

/// Accessible button complying with UI/UX Pro Max and Rule 13:
/// - Minimum 48dp touch target
/// - Visual loading state with spinner
/// - Visible focus & active states
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.outlined({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.destructive({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  }) : variant = AppButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget buttonChild;
    if (isLoading) {
      final spinnerColor = (variant == AppButtonVariant.outlined || variant == AppButtonVariant.text)
          ? AppColors.primary
          : Colors.white;
      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          AppSpacing.gapSm,
          Text(text, style: AppTypography.labelLarge),
        ],
      );
    } else {
      buttonChild = Text(text, style: AppTypography.labelLarge);
    }

    Widget btn;
    switch (variant) {
      case AppButtonVariant.primary:
        btn = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.secondary:
        btn = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.onSecondary,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.outlined:
        btn = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
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
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.text:
        btn = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
          ),
          child: buttonChild,
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: btn,
      );
    }
    return btn;
  }
}

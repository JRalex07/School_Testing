import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Accessible dialog helper complying with UI/UX Pro Max and Rule 13.
class AppDialog {
  AppDialog._();

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text(title, style: AppTypography.titleLarge),
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(ctx).colorScheme.onSurface.withAlpha(200),
          ),
        ),
        actionsPadding: AppSpacing.paddingMd,
        actions: [
          AppButton.outlined(
            text: cancelLabel,
            onPressed: () => Navigator.of(ctx).pop(false),
            fullWidth: false,
          ),
          AppSpacing.gapSm,
          isDestructive
              ? AppButton.destructive(
                  text: confirmLabel,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  fullWidth: false,
                )
              : AppButton.primary(
                  text: confirmLabel,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  fullWidth: false,
                ),
        ],
      ),
    );
  }

  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text(title, style: AppTypography.titleLarge),
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(ctx).colorScheme.onSurface.withAlpha(200),
          ),
        ),
        actionsPadding: AppSpacing.paddingMd,
        actions: [
          AppButton.primary(
            text: buttonLabel,
            onPressed: () => Navigator.of(ctx).pop(),
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}

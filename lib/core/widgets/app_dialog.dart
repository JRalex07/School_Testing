import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Accessible and compact dialog helper:
/// - Max width boundary (AppConstants.maxDialogWidth) preventing oversized desktop dialogs
/// - Clean typography and compact button row
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxDialogWidth),
          child: Text(
            title,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxDialogWidth),
          child: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(ctx).colorScheme.onSurface.withAlpha(200),
            ),
          ),
        ),
        actions: [
          AppButton.outlined(
            text: cancelLabel,
            isCompact: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            fullWidth: false,
          ),
          AppSpacing.gapSm,
          isDestructive
              ? AppButton.destructive(
                  text: confirmLabel,
                  isCompact: true,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  fullWidth: false,
                )
              : AppButton.primary(
                  text: confirmLabel,
                  isCompact: true,
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxDialogWidth),
          child: Text(
            title,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxDialogWidth),
          child: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(ctx).colorScheme.onSurface.withAlpha(200),
            ),
          ),
        ),
        actions: [
          AppButton.primary(
            text: buttonLabel,
            isCompact: true,
            onPressed: () => Navigator.of(ctx).pop(),
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}

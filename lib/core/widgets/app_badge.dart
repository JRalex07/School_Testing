import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppBadgeVariant { success, warning, error, info, neutral }

/// Accessible status badge for fees, attendance, and exam publication.
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case AppBadgeVariant.success:
        bg = AppColors.successContainer;
        fg = AppColors.onSuccessContainer;
        break;
      case AppBadgeVariant.warning:
        bg = AppColors.warningContainer;
        fg = AppColors.onWarningContainer;
        break;
      case AppBadgeVariant.error:
        bg = AppColors.errorContainer;
        fg = AppColors.onErrorContainer;
        break;
      case AppBadgeVariant.info:
        bg = AppColors.infoContainer;
        fg = AppColors.onInfoContainer;
        break;
      case AppBadgeVariant.neutral:
        final isDark = Theme.of(context).brightness == Brightness.dark;
        bg = isDark ? AppColors.darkSurfaceSubtle : AppColors.primaryContainer;
        fg = isDark ? Colors.white : AppColors.onPrimaryContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.radiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

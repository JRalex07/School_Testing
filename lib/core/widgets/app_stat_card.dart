import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_badge.dart';
import 'app_card.dart';

/// Reusable compact Claymorphic Stat Card for dashboard metrics:
/// - Small icon with soft tinted surface
/// - Metric value, short title, and optional status badge
/// - Compact height (~96dp) and adaptive responsive width
class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? badge;
  final AppBadgeVariant badgeVariant;
  final String? subtitle;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.badge,
    this.badgeVariant = AppBadgeVariant.neutral,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      padding: AppSpacing.cardPaddingCompact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceSubtle
                      : AppColors.primaryContainer,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              if (badge != null) AppBadge(label: badge!, variant: badgeVariant),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(160),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.labelSmall.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(120),
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Card component with consistent shape, optional elevation, and splash feedback.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final bool hasShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingMd,
    this.onTap,
    this.color,
    this.border,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.radiusMd,
        border: border ??
            Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  color: Colors.black.withAlpha(isDark ? 50 : 15),
                )
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.radiusMd,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

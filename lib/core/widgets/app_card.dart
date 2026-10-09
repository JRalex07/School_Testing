import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Professional Claymorphic Card component:
/// - Soft rounded surfaces with dual-depth shadows (subtle drop shadow + top highlight)
/// - Compact default padding (12dp) for high information density
/// - Optional min/max width/height constraints preventing unbounded stretching
/// - Tactile splash & hover states for interactive cards
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final bool hasShadow;
  final double? minWidth;
  final double? maxWidth;
  final double? minHeight;
  final double? maxHeight;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
    this.hasShadow = true,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor =
        color ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? AppRadius.radiusCard;
    final effectivePadding = padding ?? AppSpacing.cardPaddingCompact;

    // Stitch Professional Claymorphism dual-shadow:
    // Warm magenta-tinted ambient key shadow + pure white top-left rim highlight
    final List<BoxShadow>? clayShadows = hasShadow
        ? [
            // Ambient warm tinted diffuse shadow
            BoxShadow(
              offset: const Offset(4, 4),
              blurRadius: 12,
              spreadRadius: 0,
              color: isDark ? Colors.black.withAlpha(70) : AppColors.clayShadow,
            ),
            // Diffuse extruded top-left rim highlight
            BoxShadow(
              offset: const Offset(-3, -3),
              blurRadius: 8,
              spreadRadius: 0,
              color: isDark
                  ? Colors.white.withAlpha(12)
                  : AppColors.clayInnerLight,
            ),
          ]
        : null;

    Widget content = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: effectiveRadius,
        border:
            border ??
            Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
        boxShadow: clayShadows,
      ),
      child: child,
    );

    if (minWidth != null ||
        maxWidth != null ||
        minHeight != null ||
        maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 0.0,
          maxWidth: maxWidth ?? double.infinity,
          minHeight: minHeight ?? 0.0,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: content,
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

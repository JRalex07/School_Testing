import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_spacing.dart';

enum DeviceScreenType { compactMobile, mobile, tablet, desktop, wideDesktop }

/// Centralized Responsive System:
/// - Dispatches across compact mobile, mobile, tablet, desktop, and wide desktop
/// - Context- and constraint-aware
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppConstants.desktopBreakpoint) {
      return DeviceScreenType.wideDesktop;
    } else if (width >= AppConstants.tabletBreakpoint) {
      return DeviceScreenType.desktop;
    } else if (width >= AppConstants.mobileBreakpoint) {
      return DeviceScreenType.tablet;
    } else if (width >= AppConstants.compactMobileBreakpoint) {
      return DeviceScreenType.mobile;
    }
    return DeviceScreenType.compactMobile;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < AppConstants.compactMobileBreakpoint;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppConstants.mobileBreakpoint &&
        width < AppConstants.tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.tabletBreakpoint;

  static bool isWideDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.tabletBreakpoint) {
          if (desktop != null) return desktop!(context);
          if (tablet != null) return tablet!(context);
          return mobile(context);
        }

        if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
          if (tablet != null) return tablet!(context);
          return mobile(context);
        }

        return mobile(context);
      },
    );
  }
}

/// Responsive Page Container:
/// - Constrains content to AppConstants.maxContentWidth on desktop
/// - Centers content gracefully on 1440px+ ultra-wide screens
/// - Applies responsive gutters
class ResponsivePageContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  const ResponsivePageContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = AppConstants.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? AppSpacing.pageGutter(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Adaptive Responsive Grid:
/// - Automatically calculates columns based on available container width
/// - Reflows smoothly when browser is resized
/// - Enforces sensible min and max item widths
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double targetItemWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.targetItemWidth = 250.0,
    this.maxColumns = 4,
    this.spacing = 12.0,
    this.runSpacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Calculate optimal column count
        final rawCols = (availableWidth / targetItemWidth).floor();
        final cols = rawCols.clamp(1, maxColumns);

        // Calculate exact item width so items fill the row proportionally
        final itemWidth = (availableWidth - (cols - 1) * spacing) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth.floorToDouble(),
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

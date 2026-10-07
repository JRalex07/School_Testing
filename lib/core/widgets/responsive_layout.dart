import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

enum DeviceScreenType { mobile, tablet, desktop }

/// Responsive layout builder that dispatches across mobile, tablet, and desktop viewports.
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
    if (width >= AppConstants.tabletBreakpoint) {
      return DeviceScreenType.desktop;
    } else if (width >= AppConstants.mobileBreakpoint) {
      return DeviceScreenType.tablet;
    }
    return DeviceScreenType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceScreenType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceScreenType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceScreenType.desktop;

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

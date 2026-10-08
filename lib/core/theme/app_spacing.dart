import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Spacing system based on 8-point grid with compact and responsive layout helpers.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0; // Optimized from 16 to 12 for compact UI
  static const double standard = 16.0;
  static const double lg = 20.0; // Optimized from 24 to 20
  static const double xl = 28.0; // Optimized from 32 to 28
  static const double xxl = 40.0;

  // Insets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingStandard = EdgeInsets.all(standard);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Card Insets
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12.0);
  static const EdgeInsets cardPaddingStandard = EdgeInsets.all(16.0);

  // Horizontal Insets
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalStandard = EdgeInsets.symmetric(
    horizontal: standard,
  );
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  // Vertical Insets
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalStandard = EdgeInsets.symmetric(
    vertical: standard,
  );
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  // SizedBox Gaps
  static const Widget gapXs = SizedBox(width: xs, height: xs);
  static const Widget gapSm = SizedBox(width: sm, height: sm);
  static const Widget gapMd = SizedBox(width: md, height: md);
  static const Widget gapStandard = SizedBox(width: standard, height: standard);
  static const Widget gapLg = SizedBox(width: lg, height: lg);
  static const Widget gapXl = SizedBox(width: xl, height: xl);
  static const Widget gapXxl = SizedBox(width: xxl, height: xxl);

  /// Responsive page gutter: scales gracefully across screen sizes without over-padding
  static EdgeInsets pageGutter(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppConstants.compactMobileBreakpoint) {
      return const EdgeInsets.all(10.0);
    } else if (width < AppConstants.mobileBreakpoint) {
      return const EdgeInsets.all(14.0);
    } else if (width < AppConstants.tabletBreakpoint) {
      return const EdgeInsets.all(18.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  /// Responsive horizontal page padding
  static EdgeInsets pageHorizontalGutter(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppConstants.compactMobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 10.0);
    } else if (width < AppConstants.mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 14.0);
    } else if (width < AppConstants.tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 18.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    }
  }
}

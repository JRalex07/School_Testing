import 'package:flutter/material.dart';

/// Spacing system based on 8-point grid.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Insets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal Insets
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  // Vertical Insets
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  // SizedBox Gaps
  static const Widget gapXs = SizedBox(width: xs, height: xs);
  static const Widget gapSm = SizedBox(width: sm, height: sm);
  static const Widget gapMd = SizedBox(width: md, height: md);
  static const Widget gapLg = SizedBox(width: lg, height: lg);
  static const Widget gapXl = SizedBox(width: xl, height: xl);
  static const Widget gapXxl = SizedBox(width: xxl, height: xxl);
}

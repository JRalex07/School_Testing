import 'package:flutter/material.dart';

/// Design tokens for colors based on Stitch's Tactile Academic System.
/// Primary: Carmine Magenta (#E11D48 / #B80035)
/// Secondary: Rose Burgundy (#8F4953 / #FFD9DC)
/// Tertiary / Attendance: Academic Emerald (#006847 / #10B981)
/// Backgrounds & Surfaces: Porcelain Blush (#F8F9FF / #EFF4FF / #FFFFFF)
class AppColors {
  AppColors._();

  // Primary Carmine Magenta Palette
  static const Color primary = Color(0xFFE11D48);
  static const Color primaryDeep = Color(0xFFB80035);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE11D48);
  static const Color onPrimaryContainer = Color(0xFFFFFAF9);
  static const Color primaryFixed = Color(0xFFFFDADA);
  static const Color primaryFixedDim = Color(0xFFFFB3B6);
  static const Color onPrimaryFixedVariant = Color(0xFF920028);

  // Secondary Rose Burgundy Palette
  static const Color secondary = Color(0xFF8F4953);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFA6B1);
  static const Color onSecondaryContainer = Color(0xFF7A3842);
  static const Color secondaryFixed = Color(0xFFFFD9DC);
  static const Color secondaryFixedDim = Color(0xFFFFB2BB);
  static const Color onSecondaryFixedVariant = Color(0xFF73323D);

  // Tertiary Academic Emerald Palette (Attendance, Verification, Success)
  static const Color tertiary = Color(0xFF006847);
  static const Color tertiaryEmerald = Color(0xFF10B981);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF00845A);
  static const Color onTertiaryContainer = Color(0xFFEEFFF3);
  static const Color tertiaryFixed = Color(0xFF6FFBBE);
  static const Color tertiaryFixedDim = Color(0xFF4EDEA3);
  static const Color onTertiaryFixed = Color(0xFF002113);

  // Accent / CTA (Warm Amber / Rose CTA)
  static const Color accent = Color(0xFFE11D48);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color accentContainer = Color(0xFFFFDADA);
  static const Color onAccentContainer = Color(0xFF920028);

  // Semantic Feedback Colors
  static const Color success = Color(0xFF006847);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFE6F7F0);
  static const Color onSuccessContainer = Color(0xFF004D34);

  static const Color warning = Color(0xFFD97706);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF78350F);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color info = Color(0xFF006847);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFE5EEFF);
  static const Color onInfoContainer = Color(0xFF0B1C30);

  // Stitch Porcelain & Academic Clay Surfaces
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color surfaceBright = Color(0xFFF8F9FF);

  // Claymorphic Depth Tokens
  static const Color clayShadow = Color(0x14E11D48);
  static const Color clayShadowSubtle = Color(0x0DE11D48);
  static const Color clayBorder = Color(0x26F472B6);
  static const Color clayInnerLight = Color(0xF2FFFFFF);

  // Light Mode Surfaces & Text
  static const Color lightBackground = Color(0xFFF8F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0B1C30);
  static const Color lightTextSecondary = Color(0xFF5C3F40);
  static const Color lightTextMuted = Color(0xFF906F70);
  static const Color lightBorder = Color(0x26F472B6);
  static const Color lightDivider = Color(0x1AF472B6);

  // Dark Mode Surfaces & Text
  static const Color darkBackground = Color(0xFF0B1C30);
  static const Color darkSurface = Color(0xFF16253A);
  static const Color darkSurfaceSubtle = Color(0xFF213145);
  static const Color darkTextPrimary = Color(0xFFF8F9FF);
  static const Color darkTextSecondary = Color(0xFFEAF1FF);
  static const Color darkTextMuted = Color(0xFF906F70);
  static const Color darkBorder = Color(0x33F472B6);
  static const Color darkDivider = Color(0xFF213145);
}

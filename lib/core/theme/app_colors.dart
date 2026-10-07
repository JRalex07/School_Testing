import 'package:flutter/material.dart';

/// Design tokens for colors based on UI/UX Pro Max guidelines.
/// Primary: Indigo 600 (#4F46E5)
/// Accent/CTA: Orange 600 (#EA580C)
/// Backgrounds: Slate 50 / Slate 900
class AppColors {
  AppColors._();

  // Primary Indigo Palette
  static const Color primary = Color(0xFF4F46E5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEEF2FF);
  static const Color onPrimaryContainer = Color(0xFF3730A3);

  // Secondary Sky Palette
  static const Color secondary = Color(0xFF0284C7);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE0F2FE);
  static const Color onSecondaryContainer = Color(0xFF075985);

  // Accent / CTA Energetic Orange
  static const Color accent = Color(0xFFEA580C);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color accentContainer = Color(0xFFFFEDD5);
  static const Color onAccentContainer = Color(0xFF9A3412);

  // Semantic Feedback Colors
  static const Color success = Color(0xFF16A34A);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccessContainer = Color(0xFF14532D);

  static const Color warning = Color(0xFFD97706);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF78350F);

  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  static const Color info = Color(0xFF2563EB);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color onInfoContainer = Color(0xFF1E3A8A);

  // Light Mode Surfaces & Text
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFF1F5F9);

  // Dark Mode Surfaces & Text
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceSubtle = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);
}

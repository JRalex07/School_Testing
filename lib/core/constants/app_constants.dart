/// Application-wide constants for MPS School Management System.
class AppConstants {
  AppConstants._();

  static const String appName = 'MPS School Management System';
  static const String schoolShortName = 'MPS';
  static const String firebaseProjectId = 'tutorfee-83839';

  // Supported Locales
  static const String localeEn = 'en';
  static const String localeHi = 'hi';

  // Centralized Responsive Breakpoints
  static const double compactMobileBreakpoint = 360.0;
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  // Maximum content boundary to avoid ultra-wide stretching on large displays
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 580.0;
  static const double maxDialogWidth = 460.0;

  // Adaptive Card Boundaries
  static const double minCardWidth = 220.0;
  static const double maxCardWidth = 360.0;

  // Compact Control Heights
  static const double compactControlHeight = 38.0;
  static const double standardControlHeight = 44.0;
  static const double minTouchTargetSize = 48.0;

  // Icon Sizing Scale
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 22.0;
  static const double iconLg = 28.0;
}

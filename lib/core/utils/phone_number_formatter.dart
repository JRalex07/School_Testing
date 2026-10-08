/// Phone number validation and normalization utility for MPS School Management System.
/// Standardizes Indian mobile numbers to E.164 (+91XXXXXXXXXX) format (Rule 4).
class PhoneNumberFormatter {
  PhoneNumberFormatter._();

  /// Normalize a phone number to standard E.164 format (+91XXXXXXXXXX).
  /// Returns null if the number is not a valid 10-digit Indian mobile number.
  static String? normalize(String rawPhone) {
    if (rawPhone.trim().isEmpty) return null;

    // Strip whitespace, hyphens, and parentheses
    String cleaned = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Handle +91 prefix
    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }

    // Must be exactly 10 digits starting with 6, 7, 8, or 9
    final regex = RegExp(r'^[6-9]\d{9}$');
    if (!regex.hasMatch(cleaned)) {
      return null;
    }

    return '+91$cleaned';
  }

  /// Check whether a raw phone input is a valid mobile number.
  static bool isValid(String rawPhone) {
    return normalize(rawPhone) != null;
  }

  /// Format normalized phone number for display (e.g. +91 98765 43210).
  static String formatDisplay(String normalizedPhone) {
    if (normalizedPhone.length == 13 && normalizedPhone.startsWith('+91')) {
      final part1 = normalizedPhone.substring(0, 3);
      final part2 = normalizedPhone.substring(3, 8);
      final part3 = normalizedPhone.substring(8);
      return '$part1 $part2 $part3';
    }
    return normalizedPhone;
  }

  /// Mask phone number for OTP display security (e.g. +91 ******3210).
  static String mask(String normalizedPhone) {
    if (normalizedPhone.length >= 10) {
      final prefix = normalizedPhone.substring(0, 3);
      final suffix = normalizedPhone.substring(normalizedPhone.length - 4);
      return '$prefix ******$suffix';
    }
    return normalizedPhone;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/phone_number_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Professional Phone OTP Login Screen conforming to MPS Claymorphism design.
class LoginScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final void Function(UserProfile profile) onLoginSuccess;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLocale;
  final bool isDarkMode;
  final Locale currentLocale;

  const LoginScreen({
    super.key,
    required this.authRepository,
    required this.onLoginSuccess,
    required this.onToggleTheme,
    required this.onToggleLocale,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _verificationId;
  int? _resendToken;
  String _normalizedPhone = '';

  int _resendCountdown = 30;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    final normalized = PhoneNumberFormatter.normalize(rawPhone);

    if (normalized == null) {
      setState(() {
        _errorMessage =
            'Please enter a valid 10-digit mobile number (e.g. 9876543210)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _normalizedPhone = normalized;
    });

    final result = await widget.authRepository.verifyPhoneNumber(
      phoneNumber: normalized,
      resendToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _isOtpSent = true;
          _isLoading = false;
          _verificationId = verificationId;
          _resendToken = resendToken;
          _errorMessage = null;
        });
        _startCountdown();
      },
      onVerificationFailed: (errorMsg) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      },
      onVerificationCompleted: (uid) async {
        if (!mounted) return;
        _resolveUserSession();
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        if (!mounted) return;
        setState(() => _verificationId = verificationId);
      },
    );

    if (result.isFailure && mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorOrNull?.message ?? 'Failed to send OTP.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP';
      });
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _errorMessage = 'Verification session expired. Please resend OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.authRepository.verifyOtp(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    if (result.isFailure) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = result.errorOrNull?.message ?? 'Invalid OTP code.';
        });
      }
      return;
    }

    await _resolveUserSession();
  }

  Future<void> _resolveUserSession() async {
    final profileResult = await widget.authRepository.getCurrentUserProfile();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (profileResult.isFailure) {
      setState(() {
        _errorMessage =
            profileResult.errorOrNull?.message ??
            'Failed to fetch user account.';
      });
      return;
    }

    final profile = profileResult.dataOrNull;

    // Check 1: Unregistered mobile number (Rule 5 & 24)
    if (profile == null) {
      await widget.authRepository.signOut();
      if (mounted) {
        AppDialog.showAlert(
          context: context,
          title: 'Unregistered Number',
          message: 'This mobile number is not registered with MPS.\nPlease contact the school administrator to provision your account.',
        );
        setState(() {
          _isOtpSent = false;
          _otpController.clear();
        });
      }
      return;
    }

    // Check 2: Account active status (Rule 10)
    if (!profile.isActive) {
      await widget.authRepository.signOut();
      if (mounted) {
        AppDialog.showAlert(
          context: context,
          title: 'Account Inactive',
          message: 'Your MPS account is currently inactive.\nPlease contact the school administrator.',
        );
        setState(() {
          _isOtpSent = false;
          _otpController.clear();
        });
      }
      return;
    }

    // Check 3: Authorized active account
    widget.onLoginSuccess(profile);
  }

  void _resetPhoneInput() {
    _countdownTimer?.cancel();
    setState(() {
      _isOtpSent = false;
      _otpController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.clayBorder),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(2, 2),
                    blurRadius: 6,
                    color: AppColors.clayShadow,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icons/mps_app_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.school,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AppConstants.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.currentLocale.languageCode == 'en'
                ? 'हिंदी'
                : 'English',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.currentLocale.languageCode.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onPressed: widget.onToggleLocale,
          ),
          IconButton(
            tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 18,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stitch Concentric Molded Crest Pedestal
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(4, 4),
                            blurRadius: 14,
                            color: AppColors.clayShadow,
                          ),
                          const BoxShadow(
                            offset: Offset(-3, -3),
                            blurRadius: 10,
                            color: AppColors.clayInnerLight,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.clayBorder),
                        ),
                        child: Center(
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/mps_app_icon.png',
                              width: 52,
                              height: 52,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) => const Icon(
                                Icons.school,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withAlpha(40),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'MPS',
                  style: AppTypography.displaySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                // Portal Sub-badge with dual micro-shadow
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixed,
                    borderRadius: AppRadius.radiusPill,
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(2, 2),
                        blurRadius: 6,
                        color: AppColors.clayShadowSubtle,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.family_restroom,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'PARENT PORTAL',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSecondaryFixedVariant,
                          letterSpacing: 0.8,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Interactive Form Card
                AppCard(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: AppRadius.radiusMd,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // State 1: Mobile Entry Module
                      if (!_isOtpSent) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Parent Login',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: AppRadius.radiusPill,
                              ),
                              child: Text(
                                'Step 1 of 2',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your registered mobile number to receive a one-time verification code',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Sunken Input Container
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MOBILE NUMBER',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.clayBorder),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                children: [
                                  // Country Code Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.clayBorder,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '🇮🇳 ',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          '+91',
                                          style: AppTypography.labelMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.lock_outline,
                                          size: 12,
                                          color: AppColors.lightTextMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 22,
                                    width: 1,
                                    color: AppColors.clayBorder,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.smartphone,
                                    size: 18,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      enabled: !_isLoading,
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        hintText: '98765 43210',
                                        hintStyle: AppTypography.bodyLarge
                                            .copyWith(
                                              color: AppColors.lightTextMuted
                                                  .withAlpha(150),
                                            ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onSubmitted: (_) {
                                        if (!_isLoading) _sendOtp();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Primary Pill CTA
                        AppButton.primary(
                          text: _isLoading ? 'Sending OTP...' : 'Send OTP',
                          icon: Icons.arrow_forward,
                          onPressed: _isLoading ? null : _sendOtp,
                        ),
                      ]
                      // State 2: OTP Verification Module
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Verification Code',
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryFixed,
                                        borderRadius: AppRadius.radiusPill,
                                      ),
                                      child: Text(
                                        'Active',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: AppColors
                                                  .onSecondaryFixedVariant,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sent to +91 ${_normalizedPhone.length >= 10 ? _normalizedPhone.substring(_normalizedPhone.length - 10) : _normalizedPhone}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: _isLoading ? null : _resetPhoneInput,
                              borderRadius: AppRadius.radiusPill,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: AppRadius.radiusPill,
                                  border: Border.all(
                                    color: AppColors.clayBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.edit,
                                      size: 13,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Edit',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // 6 Rounded Clay Digit Cells
                        Stack(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                final text = _otpController.text;
                                final hasChar = index < text.length;
                                final isCurrent = index == text.length;
                                final char = hasChar ? text[index] : '';

                                return Container(
                                  width: 44,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppColors.surfaceContainer
                                        : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCurrent
                                          ? AppColors.primary
                                          : AppColors.clayBorder,
                                      width: isCurrent ? 1.8 : 1.0,
                                    ),
                                    boxShadow: [
                                      if (isCurrent)
                                        BoxShadow(
                                          offset: const Offset(0, 2),
                                          blurRadius: 6,
                                          color: AppColors.primary.withAlpha(
                                            50,
                                          ),
                                        ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    hasChar ? char : (isCurrent ? '•' : '•'),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: hasChar
                                          ? AppColors.lightTextPrimary
                                          : (isCurrent
                                                ? AppColors.primary
                                                : AppColors.lightTextMuted
                                                      .withAlpha(100)),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            // Invisible text field overlay for smooth native keyboard
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.0,
                                child: TextField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  autofocus: true,
                                  enabled: !_isLoading,
                                  decoration: const InputDecoration(
                                    counterText: '',
                                  ),
                                  onChanged: (val) {
                                    setState(() {});
                                    if (val.length == 6) {
                                      _verifyOtp();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Timer & Resend Toolbar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.history,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _resendCountdown > 0
                                      ? 'Resend code in 00:${_resendCountdown.toString().padLeft(2, '0')}'
                                      : 'Didn\'t receive code?',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (_resendCountdown == 0)
                              InkWell(
                                onTap: _isLoading ? null : _sendOtp,
                                child: Text(
                                  'Resend OTP',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Verify Pill CTA
                        AppButton.primary(
                          text: _isLoading
                              ? 'Verifying...'
                              : 'Verify & Continue',
                          icon: Icons.verified_user,
                          onPressed: _isLoading ? null : _verifyOtp,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // Security Reassurance Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.clayBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 16,
                          color: AppColors.onTertiaryFixed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '256-BIT SSL PROTECTION',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.tertiary,
                              ),
                            ),
                            Text(
                              'Encrypted & secure verification backed by MPS Portal',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/phone_number_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_text_field.dart';
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.radiusSm,
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
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
          padding: AppSpacing.paddingMd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // School Badge & Title
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  AppSpacing.gapMd,
                  Text(
                    'MPS Portal Login',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone Number + OTP Verification',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapLg,

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: AppRadius.radiusSm,
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapMd,
                  ],

                  // Step 1: Phone input
                  if (!_isOtpSent) ...[
                    AppTextField(
                      label: l10n.translate('phone_number'),
                      hint: '10-digit mobile number',
                      controller: _phoneController,
                      prefixText: '+91 ',
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      enabled: !_isLoading,
                    ),
                    AppSpacing.gapLg,
                    AppButton.primary(
                      text: _isLoading ? 'Sending OTP...' : 'Send OTP',
                      icon: Icons.sms_outlined,
                      onPressed: _isLoading ? null : _sendOtp,
                    ),
                  ]
                  // Step 2: OTP verification
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_android,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'OTP sent to ${PhoneNumberFormatter.mask(_normalizedPhone)}',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _resetPhoneInput,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Change',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapMd,
                    AppTextField(
                      label: 'Enter 6-Digit OTP',
                      hint: '• • • • • •',
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: !_isLoading,
                    ),
                    AppSpacing.gapMd,
                    AppButton.primary(
                      text: _isLoading ? 'Verifying OTP...' : 'Verify OTP',
                      icon: Icons.login,
                      onPressed: _isLoading ? null : _verifyOtp,
                    ),
                    AppSpacing.gapSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_resendCountdown > 0)
                          Text(
                            'Resend OTP in ${_resendCountdown}s',
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(140),
                            ),
                          )
                        else
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text(
                              'Resend OTP',
                              style: TextStyle(fontSize: 13),
                            ),
                            onPressed: _isLoading ? null : _sendOtp,
                          ),
                      ],
                    ),
                  ],

                  AppSpacing.gapMd,
                  Text(
                    'School Management Portal • Authorized Personnel Only',
                    style: AppTypography.labelSmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(120),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

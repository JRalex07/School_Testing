import '../../core/errors/result.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';

/// Contract for Authentication, Phone OTP, and User Provisioning (Rules 4, 5, 10).
abstract class AuthRepository {
  /// Stream of authenticated user ID or null.
  Stream<String?> get authStateChanges;

  /// Currently authenticated user ID.
  String? get currentUserId;

  /// Initiate Firebase Phone Number verification.
  Future<Result<void>> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    required void Function(String uid) onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  });

  /// Verify 6-digit SMS OTP against Firebase Phone Authentication.
  Future<Result<String>> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Fetch authoritative profile of current authenticated user.
  Future<Result<UserProfile?>> getCurrentUserProfile();

  /// Query user profile by normalized phone number (+91XXXXXXXXXX).
  Future<Result<UserProfile?>> getUserProfileByPhone(String normalizedPhone);

  /// Provision a new staff/user account (Principal only).
  Future<Result<void>> provisionUser(UserProfile profile);

  /// Fetch all staff accounts for school administration.
  Future<Result<List<UserProfile>>> getSchoolStaffUsers(String schoolId);

  /// Activate or deactivate a user account (Principal only).
  Future<Result<void>> setUserActiveStatus({
    required String uid,
    required bool isActive,
    required String changedByUserId,
  });

  /// Authoritative role lookup.
  Future<Result<UserRole>> fetchAuthoritativeRole();

  /// Safe sign out and session clear (Rule 12 & 13).
  Future<Result<void>> signOut();
}

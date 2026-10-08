import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/cache/cache_manager.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../../core/utils/phone_number_formatter.dart';
import '../../domain/models/audit_log_record.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

/// Production Firebase Phone Authentication and User Profile repository.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final CacheManager _cache;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    CacheManager? cache,
  }) : _customAuth = auth,
       _customFirestore = firestore,
       _cache = cache ?? CacheManager();

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _auditLogsRef =>
      _firestore.collection('auditLogs');

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<Result<void>> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    required void Function(String uid) onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    final normalized = PhoneNumberFormatter.normalize(phoneNumber);
    if (normalized == null) {
      return const Result.failure(
        ValidationError('Please enter a valid 10-digit Indian mobile number'),
      );
    }

    try {
      _logAuth('VERIFY_PHONE: $normalized');
      await _auth.verifyPhoneNumber(
        phoneNumber: normalized,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _logAuth('AUTO_VERIFIED: $normalized');
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            final uid = userCredential.user?.uid;
            if (uid != null) {
              onVerificationCompleted(uid);
            }
          } catch (e) {
            onVerificationFailed('Auto verification sign-in failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _logAuth('VERIFICATION_FAILED: ${e.code} - ${e.message}');
          final message = _mapFirebaseAuthError(e);
          onVerificationFailed(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _logAuth('CODE_SENT to $normalized (verId: $verificationId)');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _logAuth('TIMEOUT verId: $verificationId');
          onCodeAutoRetrievalTimeout(verificationId);
        },
      );

      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        AuthenticationError('Failed to initiate phone verification: $e'),
      );
    }
  }

  @override
  Future<Result<String>> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final code = smsCode.trim();
    if (code.length != 6) {
      return const Result.failure(
        ValidationError('Please enter the full 6-digit OTP'),
      );
    }

    try {
      _logAuth('VERIFY_OTP with code: $code');
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        return const Result.failure(
          AuthenticationError('OTP verification failed to return user'),
        );
      }

      // Record last login timestamp
      try {
        await _usersRef.doc(user.uid).set({
          'lastLoginAt': FieldValue.serverTimestamp(),
          if (user.phoneNumber != null) 'phoneNumber': user.phoneNumber,
        }, SetOptions(merge: true));
      } catch (_) {}

      return Result.success(user.uid);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthenticationError(_mapFirebaseAuthError(e)));
    } catch (e) {
      return Result.failure(AuthenticationError('OTP verification failed: $e'));
    }
  }

  @override
  Future<Result<UserProfile?>> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Result.success(null);
    }

    final cacheKey = CacheKeys.userProfile(user.uid);
    final cached = _cache.get<UserProfile>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      // 1. Lookup by UID
      _logAuth('FETCH_PROFILE /users/${user.uid}');
      final doc = await _usersRef.doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromMap(doc.data()!, doc.id);
        _cache.set(cacheKey, profile, ttl: const Duration(minutes: 10));
        return Result.success(profile);
      }

      // 2. Lookup by phone number (if administrator provisioned prior to first sign-in)
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        final phoneResult = await getUserProfileByPhone(user.phoneNumber!);
        if (phoneResult.isSuccess && phoneResult.dataOrNull != null) {
          final existing = phoneResult.dataOrNull!;
          // Link this UID to the provisioned profile
          final linkedProfile = existing.copyWith(uid: user.uid);
          await _usersRef
              .doc(user.uid)
              .set(linkedProfile.toMap(), SetOptions(merge: true));
          _cache.set(cacheKey, linkedProfile, ttl: const Duration(minutes: 10));
          return Result.success(linkedProfile);
        }
      }

      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to fetch user profile: $e'));
    }
  }

  @override
  Future<Result<UserProfile?>> getUserProfileByPhone(
    String normalizedPhone,
  ) async {
    final normalized =
        PhoneNumberFormatter.normalize(normalizedPhone) ?? normalizedPhone;
    final cacheKey = 'phone:$normalized:profile';
    final cached = _cache.get<UserProfile>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logAuth('QUERY /users where phoneNumber=$normalized');
      final query = await _usersRef
          .where('phoneNumber', isEqualTo: normalized)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return const Result.success(null);
      }

      final doc = query.docs.first;
      final profile = UserProfile.fromMap(doc.data(), doc.id);
      _cache.set(cacheKey, profile, ttl: const Duration(minutes: 5));
      return Result.success(profile);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to find user by phone: $e'));
    }
  }

  @override
  Future<Result<void>> provisionUser(UserProfile profile) async {
    final normalized = PhoneNumberFormatter.normalize(profile.phoneNumber);
    if (normalized == null) {
      return const Result.failure(
        ValidationError('Invalid phone number for provisioning'),
      );
    }

    try {
      _logAuth('PROVISION_USER: ${profile.fullName} ($normalized)');
      final docRef = profile.uid.isNotEmpty
          ? _usersRef.doc(profile.uid)
          : _usersRef.doc();

      final data = profile.toMap();
      data['uid'] = docRef.id;
      data['phoneNumber'] = normalized;
      data['createdAt'] = FieldValue.serverTimestamp();

      await docRef.set(data, SetOptions(merge: true));

      // Append immutable audit log (Rule 11)
      final auditLog = AuditLogRecord(
        id: '',
        schoolId: profile.schoolId,
        actorUserId: currentUserId ?? 'admin_principal',
        actorRole: 'principal',
        action: 'PROVISION_USER',
        entityType: 'user',
        entityId: docRef.id,
        metadata: {
          'role': profile.role.value,
          'phoneNumber': normalized,
          'name': profile.fullName,
        },
        timestamp: DateTime.now(),
      );
      await _auditLogsRef.add(auditLog.toMap());

      // Invalidate relevant cache
      _cache.invalidate('phone:$normalized:profile');
      _cache.invalidateTag('school_${profile.schoolId}');

      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to provision user: $e'));
    }
  }

  @override
  Future<Result<List<UserProfile>>> getSchoolStaffUsers(String schoolId) async {
    final cacheKey = 'school:$schoolId:staff';
    final cached = _cache.get<List<UserProfile>>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logAuth('FETCH_STAFF for schoolId=$schoolId');
      final snapshot = await _usersRef
          .where('schoolId', isEqualTo: schoolId)
          .where(
            'role',
            whereIn: [
              UserRole.teacher.value,
              UserRole.principal.value,
              UserRole.vicePrincipal.value,
              UserRole.accountant.value,
              UserRole.feeClerk.value,
              UserRole.officeStaff.value,
            ],
          )
          .get();

      final list = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList();

      _cache.set(
        cacheKey,
        list,
        ttl: const Duration(minutes: 5),
        scopeTag: 'school_$schoolId',
      );
      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to fetch school staff: $e'));
    }
  }

  @override
  Future<Result<void>> setUserActiveStatus({
    required String uid,
    required bool isActive,
    required String changedByUserId,
  }) async {
    try {
      _logAuth('SET_USER_STATUS: $uid -> isActive=$isActive');
      await _usersRef.doc(uid).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Audit log
      final auditLog = AuditLogRecord(
        id: '',
        schoolId: 'mps_main',
        actorUserId: changedByUserId,
        actorRole: 'principal',
        action: isActive ? 'ACTIVATE_USER' : 'DEACTIVATE_USER',
        entityType: 'user',
        entityId: uid,
        metadata: {'isActive': isActive},
        timestamp: DateTime.now(),
      );
      await _auditLogsRef.add(auditLog.toMap());

      // Invalidate cache
      _cache.invalidate(CacheKeys.userProfile(uid));
      _cache.invalidateTag('school_mps_main');

      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        DatabaseError('Failed to update user active status: $e'),
      );
    }
  }

  @override
  Future<Result<UserRole>> fetchAuthoritativeRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Result.failure(AuthenticationError('No authenticated user'));
    }

    try {
      // 1. Check custom claims
      final idTokenResult = await user.getIdTokenResult(true);
      final roleClaim = idTokenResult.claims?['role'] as String?;
      if (roleClaim != null && roleClaim.isNotEmpty) {
        return Result.success(UserRole.fromString(roleClaim));
      }

      // 2. Check profile in Firestore
      final profileResult = await getCurrentUserProfile();
      if (profileResult.isSuccess && profileResult.dataOrNull != null) {
        return Result.success(profileResult.dataOrNull!.role);
      }

      return const Result.success(UserRole.parent);
    } catch (e) {
      return Result.failure(
        AuthenticationError('Failed to fetch authoritative role: $e'),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        _cache.clearForUser(uid);
      }
      _cache.clearAll();

      await _auth.signOut();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AuthenticationError('Failed to sign out: $e'));
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The provided phone number is invalid.';
      case 'invalid-verification-code':
        return 'The OTP entered is incorrect. Please check and re-enter.';
      case 'session-expired':
        return 'The OTP has expired. Please request a new OTP.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few moments before trying again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded for today. Please contact school administration.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact the administrator.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  void _logAuth(String message) {
    if (kDebugMode) {
      debugPrint('[MPS Auth] $message');
    }
  }
}

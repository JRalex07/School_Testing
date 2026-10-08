import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/cache/cache_manager.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

/// Production Firebase Auth implementation enforcing Rules 4, 5, and 12.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final CacheManager _cache;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    CacheManager? cache,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? CacheManager();

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<Result<UserRole>> fetchAuthoritativeRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      return Result.failure(const AuthenticationError('No authenticated user'));
    }

    try {
      // 1. Check authoritative custom claims (Rule 4)
      final idTokenResult = await user.getIdTokenResult(true);
      final roleClaim = idTokenResult.claims?['role'] as String?;
      if (roleClaim != null && roleClaim.isNotEmpty) {
        return Result.success(UserRole.fromString(roleClaim));
      }

      // 2. Fallback to Firestore users collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final roleStr = userDoc.data()!['role'] as String?;
        return Result.success(UserRole.fromString(roleStr));
      }

      // Default least-privilege role
      return const Result.success(UserRole.parent);
    } catch (e) {
      return Result.failure(AuthenticationError('Failed to fetch user role: $e'));
    }
  }

  @override
  Future<Result<String>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        return Result.failure(const AuthenticationError('Failed to obtain user session'));
      }
      return Result.success(uid);
    } on FirebaseAuthException catch (e) {
      return Result.failure(AuthenticationError(e.message ?? 'Authentication failed'));
    } catch (e) {
      return Result.failure(AuthenticationError('Sign in error: $e'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        // Enforce Rule 12: Clear all private user cache on logout
        _cache.clearForUser(uid);
      }
      _cache.clearAll();

      await _auth.signOut();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AuthenticationError('Failed to sign out: $e'));
    }
  }
}

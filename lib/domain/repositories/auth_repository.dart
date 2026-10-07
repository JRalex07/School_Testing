import '../../core/errors/result.dart';
import '../models/user_role.dart';

/// Contract for Authentication and Authoritative Claims (Rules 4 & 5).
abstract class AuthRepository {
  /// Stream of authenticated user ID or null.
  Stream<String?> get authStateChanges;

  /// Authoritative role lookup (via Firebase Custom Claims).
  Future<Result<UserRole>> fetchAuthoritativeRole();

  /// Sign in with email and password.
  Future<Result<String>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Safe sign out and session clear.
  Future<Result<void>> signOut();
}

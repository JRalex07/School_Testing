import 'user_role.dart';

/// Authoritative User Profile model for MPS School Management System (Rules 4, 5, 10).
class UserProfile {
  final String uid;
  final String phoneNumber;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final String schoolId;
  final String? staffId;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> metadata;

  const UserProfile({
    required this.uid,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    this.isActive = true,
    required this.schoolId,
    this.staffId,
    required this.createdAt,
    this.lastLoginAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'role': role.value,
      'isActive': isActive,
      'schoolId': schoolId,
      'staffId': staffId,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String docId) {
    return UserProfile(
      uid: docId,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      isActive: map['isActive'] as bool? ?? true,
      schoolId: map['schoolId'] as String? ?? 'mps_main',
      staffId: map['staffId'] as String?,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateTime(map['lastLoginAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }

  /// Safely parses a date field that may be a Firestore [Timestamp],
  /// an ISO-8601 [String], or null.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    // Firestore SDK returns cloud_firestore.Timestamp for serverTimestamp() fields.
    // Using duck-typing (toDate) so we don't need to import cloud_firestore here.
    if (value is DateTime) return value;
    try {
      final dynamic ts = value;
      if (ts.runtimeType.toString().contains('Timestamp')) {
        return (ts as dynamic).toDate() as DateTime;
      }
    } catch (_) {}
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  UserProfile copyWith({
    String? uid,
    String? phoneNumber,
    String? fullName,
    UserRole? role,
    bool? isActive,
    String? schoolId,
    String? staffId,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      schoolId: schoolId ?? this.schoolId,
      staffId: staffId ?? this.staffId,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

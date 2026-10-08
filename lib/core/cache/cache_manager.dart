import 'package:flutter/foundation.dart';

/// Cache Entry with TTL expiration and scope tag.
class _CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;
  final String? scopeTag;

  _CacheEntry({
    required this.data,
    required this.createdAt,
    required this.ttl,
    this.scopeTag,
  });

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}

/// Centralized Cache Manager for MPS School Management System.
/// Implements:
/// - In-memory TTL caching with scope tagging
/// - Observability logs ([CACHE HIT], [CACHE MISS], [CACHE SET], [CACHE INVALIDATE])
/// - User & role partition isolation
/// - Safe logout/role-switch eviction
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, _CacheEntry<dynamic>> _store = {};

  /// Retrieve cached value if present and unexpired.
  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) {
      _log('[CACHE MISS] $key');
      return null;
    }

    if (entry.isExpired) {
      _store.remove(key);
      _log('[CACHE EXPIRED] $key');
      return null;
    }

    _log('[CACHE HIT] $key');
    return entry.data as T?;
  }

  /// Store value in cache with TTL and optional scope tag.
  void set<T>(
    String key,
    T data, {
    Duration ttl = const Duration(minutes: 5),
    String? scopeTag,
  }) {
    _store[key] = _CacheEntry<T>(
      data: data,
      createdAt: DateTime.now(),
      ttl: ttl,
      scopeTag: scopeTag,
    );
    _log('[CACHE SET] $key (TTL: ${ttl.inSeconds}s, Tag: $scopeTag)');
  }

  /// Invalidate a specific cache key.
  void invalidate(String key) {
    if (_store.containsKey(key)) {
      _store.remove(key);
      _log('[CACHE INVALIDATE] Key: $key');
    }
  }

  /// Invalidate all entries matching a scope tag (e.g. "class_6_A", "student_101").
  void invalidateTag(String tag) {
    final keysToRemove = <String>[];
    _store.forEach((key, entry) {
      if (entry.scopeTag == tag) {
        keysToRemove.add(key);
      }
    });

    for (final k in keysToRemove) {
      _store.remove(k);
    }
    if (keysToRemove.isNotEmpty) {
      _log('[CACHE INVALIDATE] Tag: $tag (${keysToRemove.length} keys evicted)');
    }
  }

  /// Evict all private user cache on logout or role change.
  void clearForUser(String userId) {
    final keysToRemove = <String>[];
    _store.forEach((key, entry) {
      if (key.contains('user:$userId') ||
          key.contains('parent:$userId') ||
          key.contains('teacher:$userId')) {
        keysToRemove.add(key);
      }
    });

    for (final k in keysToRemove) {
      _store.remove(k);
    }
    _log('[CACHE CLEAR USER] Evicted ${keysToRemove.length} entries for $userId');
  }

  /// Clear all cache completely.
  void clearAll() {
    final count = _store.length;
    _store.clear();
    _log('[CACHE CLEAR ALL] Evicted $count entries');
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[MPS Cache] $message');
    }
  }
}

/// Standardized Cache Key builders enforcing user/scope boundaries.
class CacheKeys {
  CacheKeys._();

  static String userProfile(String userId) => 'user:$userId:profile';
  static String teacherAssignments(String teacherId) =>
      'teacher:$teacherId:assignments';
  static String teacherClassStudents(
    String teacherId,
    String classId,
    String section,
  ) =>
      'teacher:$teacherId:class:${classId}_$section:students';
  static String classAttendance(
    String classId,
    String section,
    DateTime date,
  ) {
    final dateStr =
        '${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';
    return 'attendance:${classId}_$section:$dateStr';
  }

  static String parentChildren(String parentId) =>
      'parent:$parentId:children';
  static String studentFees(String studentId) => 'student:$studentId:fees';
  static String schoolFeeMetrics(String schoolId) =>
      'school:$schoolId:fee_metrics';
  static String notices(String schoolId) => 'school:$schoolId:notices';
}

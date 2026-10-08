import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/cache/cache_manager.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../../domain/models/teacher_assignment.dart';
import '../../domain/repositories/teacher_assignment_repository.dart';

/// Production Firestore implementation for Teacher Assignments with Caching.
class FirebaseTeacherAssignmentRepository
    implements TeacherAssignmentRepository {
  final FirebaseFirestore _firestore;
  final CacheManager _cache;

  FirebaseTeacherAssignmentRepository({
    FirebaseFirestore? firestore,
    CacheManager? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? CacheManager();

  CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection('teacherAssignments');

  @override
  Future<Result<List<TeacherAssignment>>> getTeacherAssignments(
    String teacherId,
  ) async {
    final cacheKey = CacheKeys.teacherAssignments(teacherId);
    final cached = _cache.get<List<TeacherAssignment>>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logFirestore('READ /teacherAssignments where teacherId=$teacherId');
      final snapshot = await _assignmentsRef
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .get();

      final list = snapshot.docs
          .map((doc) => TeacherAssignment.fromMap(doc.data(), doc.id))
          .toList();

      _cache.set(
        cacheKey,
        list,
        ttl: const Duration(minutes: 10),
        scopeTag: 'teacher_$teacherId',
      );
      return Result.success(list);
    } catch (e) {
      return Result.failure(
        DatabaseError('Failed to fetch teacher assignments: $e'),
      );
    }
  }

  @override
  Future<Result<int>> getActiveAssignmentCount(String academicYearId) async {
    final cacheKey = 'assignments:count:$academicYearId';
    final cached = _cache.get<int>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logFirestore('READ /teacherAssignments count academicYear=$academicYearId');
      final query = _assignmentsRef.where('isActive', isEqualTo: true);
      final aggregate = await query.count().get();
      final count = aggregate.count ?? 0;

      _cache.set(cacheKey, count, ttl: const Duration(minutes: 5));
      return Result.success(count);
    } catch (e) {
      return Result.failure(
        DatabaseError('Failed to count teacher assignments: $e'),
      );
    }
  }

  @override
  Future<Result<void>> assignTeacher(TeacherAssignment assignment) async {
    try {
      _logFirestore('WRITE /teacherAssignments/${assignment.id}');
      final docRef = assignment.id.isNotEmpty
          ? _assignmentsRef.doc(assignment.id)
          : _assignmentsRef.doc();

      await docRef.set(assignment.toMap(), SetOptions(merge: true));

      // Invalidate teacher cache
      _cache.invalidate(CacheKeys.teacherAssignments(assignment.teacherId));
      _cache.invalidateTag('teacher_${assignment.teacherId}');
      _cache.invalidate('assignments:count:${assignment.academicYearId}');

      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        DatabaseError('Failed to save teacher assignment: $e'),
      );
    }
  }

  void _logFirestore(String message) {
    if (kDebugMode) {
      debugPrint('[FIRESTORE $message]');
    }
  }
}

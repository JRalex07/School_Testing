import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/cache/cache_manager.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';

/// Production Firestore implementation for Attendance with Caching (Rule 9).
class FirebaseAttendanceRepository implements AttendanceRepository {
  final FirebaseFirestore _firestore;
  final CacheManager _cache;

  FirebaseAttendanceRepository({
    FirebaseFirestore? firestore,
    CacheManager? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? CacheManager();

  CollectionReference<Map<String, dynamic>> get _attendanceRef =>
      _firestore.collection('attendance');

  Stream<List<AttendanceRecord>> watchClassAttendance({
    required String classId,
    required String section,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _attendanceRef
        .where('classId', isEqualTo: classId)
        .where('section', isEqualTo: section)
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<Result<List<AttendanceRecord>>> getStudentAttendance(
    String studentId,
  ) async {
    final cacheKey = 'student:$studentId:attendance';
    final cached = _cache.get<List<AttendanceRecord>>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logFirestore('READ /attendance where studentId=$studentId');
      final snapshot = await _attendanceRef
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .get();

      final list = snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();
      _cache.set(
        cacheKey,
        list,
        ttl: const Duration(minutes: 5),
        scopeTag: 'student_$studentId',
      );
      return Result.success(list);
    } catch (e) {
      return Result.failure(
        DatabaseError('Failed to fetch student attendance: $e'),
      );
    }
  }

  @override
  Future<Result<List<AttendanceRecord>>> getClassAttendance({
    required String classId,
    required String section,
    required DateTime date,
  }) async {
    final cacheKey = CacheKeys.classAttendance(classId, section, date);
    final cached = _cache.get<List<AttendanceRecord>>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      _logFirestore(
        'READ /attendance class=$classId sec=$section date=${startOfDay.toIso8601String().substring(0, 10)}',
      );
      final snapshot = await _attendanceRef
          .where('classId', isEqualTo: classId)
          .where('section', isEqualTo: section)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      final list = snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();
      _cache.set(
        cacheKey,
        list,
        ttl: const Duration(minutes: 5),
        scopeTag: 'class_${classId}_$section',
      );
      return Result.success(list);
    } catch (e) {
      return Result.failure(
        DatabaseError('Failed to fetch class attendance: $e'),
      );
    }
  }

  @override
  Future<Result<void>> saveAttendance({
    required List<AttendanceRecord> records,
    required String teacherUserId,
  }) async {
    if (records.isEmpty) return const Result.success(null);

    try {
      _logFirestore('BATCH WRITE /attendance (${records.length} records)');
      final batch = _firestore.batch();
      for (final record in records) {
        final docRef = record.id.isNotEmpty
            ? _attendanceRef.doc(record.id)
            : _attendanceRef.doc(
                '${record.studentId}_${record.date.toIso8601String().substring(0, 10)}',
              );
        batch.set(docRef, record.toMap(), SetOptions(merge: true));

        // Invalidate specific student attendance cache
        _cache.invalidateTag('student_${record.studentId}');
      }
      await batch.commit();

      // Invalidate class attendance cache for this date
      final first = records.first;
      _cache.invalidate(
        CacheKeys.classAttendance(first.classId, first.section, first.date),
      );
      _cache.invalidateTag('class_${first.classId}_${first.section}');

      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to save attendance: $e'));
    }
  }

  void _logFirestore(String message) {
    if (kDebugMode) {
      debugPrint('[FIRESTORE $message]');
    }
  }
}

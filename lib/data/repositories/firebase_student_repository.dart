import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/cache/cache_manager.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../../domain/models/student.dart';
import '../../domain/repositories/student_repository.dart';

/// Production Firestore implementation for Student management with caching (Rule 3 & 7).
class FirebaseStudentRepository implements StudentRepository {
  final FirebaseFirestore _firestore;
  final CacheManager _cache;

  FirebaseStudentRepository({
    FirebaseFirestore? firestore,
    CacheManager? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? CacheManager();

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _firestore.collection('students');

  @override
  Stream<List<Student>> watchStudents({String? classId, String? section}) {
    Query<Map<String, dynamic>> query =
        _studentsRef.where('isActive', isEqualTo: true);
    if (classId != null && classId.isNotEmpty) {
      query = query.where('classId', isEqualTo: classId);
    }
    if (section != null && section.isNotEmpty) {
      query = query.where('section', isEqualTo: section);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Student.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<Result<Student?>> getStudent(String studentId) async {
    final cacheKey = 'student:$studentId';
    final cached = _cache.get<Student>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logFirestore('READ /students/$studentId');
      final doc = await _studentsRef.doc(studentId).get();
      if (!doc.exists || doc.data() == null) {
        return const Result.success(null);
      }
      final student = Student.fromMap(doc.data()!, doc.id);
      _cache.set(cacheKey, student, scopeTag: 'student_$studentId');
      return Result.success(student);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to fetch student: $e'));
    }
  }

  @override
  Future<Result<List<Student>>> getStudentsByClass({
    required String classId,
    required String section,
  }) async {
    final cacheKey = 'class:${classId}_$section:students';
    final cached = _cache.get<List<Student>>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logFirestore('QUERY /students where classId=$classId AND section=$section');
      final snapshot = await _studentsRef
          .where('classId', isEqualTo: classId)
          .where('section', isEqualTo: section)
          .where('isActive', isEqualTo: true)
          .get();

      final list = snapshot.docs
          .map((doc) => Student.fromMap(doc.data(), doc.id))
          .toList();

      _cache.set(
        cacheKey,
        list,
        ttl: const Duration(minutes: 10),
        scopeTag: 'class_${classId}_$section',
      );
      return Result.success(list);
    } catch (e) {
      return Result.failure(
        DatabaseError('Failed to fetch class students: $e'),
      );
    }
  }

  @override
  Future<Result<List<Student>>> getStudentsForParent(
    String parentUserId,
  ) async {
    final cacheKey = CacheKeys.parentChildren(parentUserId);
    final cached = _cache.get<List<Student>>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logFirestore('QUERY /students where parentUserIds contains $parentUserId');
      final snapshot = await _studentsRef
          .where('parentUserIds', arrayContains: parentUserId)
          .where('isActive', isEqualTo: true)
          .get();

      final list = snapshot.docs
          .map((doc) => Student.fromMap(doc.data(), doc.id))
          .toList();

      _cache.set(
        cacheKey,
        list,
        ttl: const Duration(minutes: 10),
        scopeTag: 'parent_$parentUserId',
      );
      return Result.success(list);
    } catch (e) {
      return Result.failure(
        DatabaseError('Failed to fetch parent children: $e'),
      );
    }
  }

  @override
  Future<Result<void>> createStudent(Student student) async {
    try {
      final docRef = student.id.isNotEmpty
          ? _studentsRef.doc(student.id)
          : _studentsRef.doc();
      final data = student.toMap();
      data['id'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();

      _logFirestore('WRITE /students/${docRef.id}');
      await docRef.set(data);

      // Invalidate relevant cache scopes
      _cache.invalidateTag('class_${student.classId}_${student.section}');
      for (final pId in student.parentUserIds) {
        _cache.invalidateTag('parent_$pId');
      }

      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to create student: $e'));
    }
  }

  @override
  Future<Result<void>> updateStudent(Student student) async {
    try {
      final data = student.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();

      _logFirestore('UPDATE /students/${student.id}');
      await _studentsRef.doc(student.id).update(data);

      // Invalidate cache
      _cache.invalidate('student:${student.id}');
      _cache.invalidateTag('class_${student.classId}_${student.section}');
      for (final pId in student.parentUserIds) {
        _cache.invalidateTag('parent_$pId');
      }

      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to update student: $e'));
    }
  }

  @override
  Future<Result<void>> deactivateStudent(String studentId) async {
    try {
      _logFirestore('DEACTIVATE /students/$studentId');
      await _studentsRef.doc(studentId).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });

      _cache.invalidate('student:$studentId');
      _cache.invalidateTag('student_$studentId');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to deactivate student: $e'));
    }
  }

  @override
  Future<Result<int>> getTotalStudentCount() async {
    const cacheKey = 'students:count:active';
    final cached = _cache.get<int>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logFirestore('QUERY COUNT /students where isActive=true');
      final query = _studentsRef.where('isActive', isEqualTo: true);
      final aggregate = await query.count().get();
      final count = aggregate.count ?? 0;

      _cache.set(cacheKey, count, ttl: const Duration(minutes: 5));
      return Result.success(count);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to count students: $e'));
    }
  }

  void _logFirestore(String msg) {
    if (kDebugMode) {
      debugPrint('[FIRESTORE] $msg');
    }
  }
}

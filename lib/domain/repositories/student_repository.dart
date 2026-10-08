import '../../core/errors/result.dart';
import '../models/student.dart';

/// Contract for Student Management (Rule 3 & 7).
abstract class StudentRepository {
  /// Stream of active students scoped by class/section.
  Stream<List<Student>> watchStudents({String? classId, String? section});

  /// Fetch a single student record.
  Future<Result<Student?>> getStudent(String studentId);

  /// Fetch students by class and section.
  Future<Result<List<Student>>> getStudentsByClass({
    required String classId,
    required String section,
  });

  /// Fetch students linked to a specific parent user ID.
  Future<Result<List<Student>>> getStudentsForParent(String parentUserId);

  /// Create a student record (Principal / Admin only).
  Future<Result<void>> createStudent(Student student);

  /// Update an existing student record (Principal / Admin only).
  Future<Result<void>> updateStudent(Student student);

  /// Deactivate a student (Soft delete preserving historical audits).
  Future<Result<void>> deactivateStudent(String studentId);

  /// Fetch total active student count using Firestore aggregate count (Rule 16).
  Future<Result<int>> getTotalStudentCount();
}

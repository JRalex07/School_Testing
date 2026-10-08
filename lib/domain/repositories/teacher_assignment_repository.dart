import '../../core/errors/result.dart';
import '../models/teacher_assignment.dart';

/// Contract for authoritative teacher class/section/subject assignments (Rules 3, 5, 9).
abstract class TeacherAssignmentRepository {
  /// Fetch assignments strictly bound to the authenticated teacher ID.
  Future<Result<List<TeacherAssignment>>> getTeacherAssignments(
    String teacherId,
  );

  /// Fetch total active assignments count for principal administrative oversight.
  Future<Result<int>> getActiveAssignmentCount(String academicYearId);

  /// Create or update an assignment (Principal only).
  Future<Result<void>> assignTeacher(TeacherAssignment assignment);
}

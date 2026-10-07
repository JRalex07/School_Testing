import '../../core/errors/result.dart';
import '../models/attendance_record.dart';

/// Contract for Academic Attendance Management (Rule 9).
abstract class AttendanceRepository {
  /// Fetch student attendance history (Parent view).
  Future<Result<List<AttendanceRecord>>> getStudentAttendance(String studentId);

  /// Fetch class attendance for a specific date (Teacher / Principal view).
  Future<Result<List<AttendanceRecord>>> getClassAttendance({
    required String classId,
    required String section,
    required DateTime date,
  });

  /// Submit or update attendance records (Authorized Teacher / Principal only).
  /// Preserves audit trail with user ID and timestamp.
  Future<Result<void>> saveAttendance({
    required List<AttendanceRecord> records,
    required String teacherUserId,
  });
}

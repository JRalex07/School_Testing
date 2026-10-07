import '../models/student.dart';
import '../models/teacher_assignment.dart';
import '../models/user_role.dart';

/// Service implementing granular teacher authorization rules (Sections 4, 5, 6, 7, 8).
/// Enforces class-level, section-level, and subject-level access boundaries.
class TeacherAuthorizationService {
  const TeacherAuthorizationService();

  /// Verifies whether an actor can view or access a student record.
  /// - Principal has universal access.
  /// - Teacher must have an active assignment to the student's exact class and section.
  /// - Knowing student's document ID or admission number does NOT bypass this check (Section 6).
  bool canAccessStudent({
    required UserRole actorRole,
    required List<TeacherAssignment> teacherAssignments,
    required Student student,
  }) {
    if (actorRole.isPrincipal) return true;
    if (!actorRole.isTeacher) return false;

    // Check if any active assignment matches the student's class and section
    return teacherAssignments.any(
      (a) =>
          a.isActive &&
          a.classId == student.classId &&
          a.sectionId == student.section,
    );
  }

  /// Verifies whether an actor can create or modify attendance for a class/section.
  bool canManageAttendance({
    required UserRole actorRole,
    required List<TeacherAssignment> teacherAssignments,
    required String classId,
    required String sectionId,
  }) {
    if (actorRole.isPrincipal) return true;
    if (!actorRole.isTeacher) return false;

    return teacherAssignments.any(
      (a) => a.isActive && a.classId == classId && a.sectionId == sectionId,
    );
  }

  /// Verifies whether an actor can enter or modify marks for a specific subject (Section 7).
  /// - A teacher assigned to Mathematics CANNOT modify English marks, even within the same class.
  /// - Subject-level granularity must be strictly respected.
  bool canManageMarks({
    required UserRole actorRole,
    required List<TeacherAssignment> teacherAssignments,
    required String classId,
    required String sectionId,
    required String subjectId,
  }) {
    if (actorRole.isPrincipal) return true;
    if (!actorRole.isTeacher) return false;

    return teacherAssignments.any(
      (a) =>
          a.isActive &&
          a.classId == classId &&
          a.sectionId == sectionId &&
          (a.subjectId == subjectId ||
              (a.isClassTeacher && a.subjectId == null)),
    );
  }

  /// Verifies whether an actor can review a student leave request.
  bool canReviewLeaveRequest({
    required UserRole actorRole,
    required List<TeacherAssignment> teacherAssignments,
    required Student student,
  }) {
    if (actorRole.isPrincipal) return true;
    if (!actorRole.isTeacher) return false;

    return teacherAssignments.any(
      (a) =>
          a.isActive &&
          a.classId == student.classId &&
          a.sectionId == student.section &&
          a.isClassTeacher,
    );
  }

  /// Verifies whether an actor can create or modify fee records.
  /// Teachers are strictly forbidden from modifying financial data (Section 8, Test 8).
  bool canManageFees({required UserRole actorRole}) {
    return actorRole.canManageFees;
  }

  /// Verifies whether an actor can change user roles or permissions.
  /// Teachers can NEVER modify their own role or other teachers' permissions (Section 8, Test 7).
  bool canModifyUserRole({
    required UserRole actorRole,
    required UserRole targetRole,
  }) {
    if (!actorRole.isPrincipal) return false;
    return true;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:schooltesting/domain/models/student.dart';
import 'package:schooltesting/domain/models/teacher_assignment.dart';
import 'package:schooltesting/domain/models/user_role.dart';
import 'package:schooltesting/domain/services/teacher_authorization_service.dart';

void main() {
  group('MPS Teacher Security Test Matrix (Section 19)', () {
    const authService = TeacherAuthorizationService();
    final now = DateTime.now();

    // Teacher A setup: assigned to Class 6, Section A, Subject: Mathematics
    final teacherAAssignments = [
      TeacherAssignment(
        id: 'assign_teacherA_6A_math',
        teacherId: 'teacher_A_uid',
        academicYearId: '2026-2027',
        classId: '6',
        sectionId: 'A',
        subjectId: 'math',
        isClassTeacher: true,
        assignedAt: now,
      ),
    ];

    // Students
    final student6A = Student(
      id: 'student_6A_001',
      admissionNumber: 'MPS-2026-6A-01',
      fullName: 'Student in 6A',
      classId: '6',
      section: 'A',
      rollNumber: '01',
      parentUserIds: ['parent_uid_01'],
    );

    final student6B = Student(
      id: 'student_6B_099',
      admissionNumber: 'MPS-2026-6B-99',
      fullName: 'Student in 6B',
      classId: '6',
      section: 'B',
      rollNumber: '99',
      parentUserIds: ['parent_uid_99'],
    );

    // Test 1: Teacher A assigned to Class 6A can read Class 6A students -> ALLOW
    test('Test 1: Teacher A assigned to Class 6A can read Class 6A students -> ALLOW', () {
      final canAccess = authService.canAccessStudent(
        actorRole: UserRole.teacher,
        teacherAssignments: teacherAAssignments,
        student: student6A,
      );
      expect(canAccess, isTrue);
    });

    // Test 2: Teacher A tries to read Class 6B -> DENY
    test('Test 2: Teacher A tries to read Class 6B -> DENY', () {
      final canAccess = authService.canAccessStudent(
        actorRole: UserRole.teacher,
        teacherAssignments: teacherAAssignments,
        student: student6B,
      );
      expect(canAccess, isFalse);
    });

    // Test 3: Teacher A tries to modify Class 6B attendance -> DENY
    test('Test 3: Teacher A tries to modify Class 6B attendance -> DENY', () {
      final canManageAttendance = authService.canManageAttendance(
        actorRole: UserRole.teacher,
        teacherAssignments: teacherAAssignments,
        classId: '6',
        sectionId: 'B',
      );
      expect(canManageAttendance, isFalse);
    });

    // Test 4: Teacher A tries to modify Class 6B marks -> DENY
    test('Test 4: Teacher A tries to modify Class 6B marks -> DENY', () {
      final canManageMarks = authService.canManageMarks(
        actorRole: UserRole.teacher,
        teacherAssignments: teacherAAssignments,
        classId: '6',
        sectionId: 'B',
        subjectId: 'math',
      );
      expect(canManageMarks, isFalse);
    });

    // Test 5: Teacher A knows Class 6B student's document ID and directly queries it -> DENY
    test('Test 5: Teacher A knows Class 6B student document ID and directly queries it -> DENY (No ID Bypass)', () {
      // Direct query with student6B.id
      final directLookupStudent =
          student6B; // Retrieved doc path 'students/student_6B_099'
      final canAccess = authService.canAccessStudent(
        actorRole: UserRole.teacher,
        teacherAssignments: teacherAAssignments,
        student: directLookupStudent,
      );
      expect(
        canAccess,
        isFalse,
        reason:
            'ID bypass must be prevented: Teacher A has no assignment to 6B',
      );
    });

    // Test 6: Teacher A tries to modify another teacher's subject marks (e.g. English) -> DENY
    test('Test 6: Teacher A tries to modify another teacher\'s subject marks (English) -> DENY', () {
      // Teacher A is assigned to Mathematics only for subject marks
      final teacherASubjectOnly = [
        TeacherAssignment(
          id: 'assign_teacherA_6A_math_only',
          teacherId: 'teacher_A_uid',
          academicYearId: '2026-2027',
          classId: '6',
          sectionId: 'A',
          subjectId: 'math',
          isClassTeacher: false, // Subject teacher only
          assignedAt: now,
        ),
      ];

      final canManageMath = authService.canManageMarks(
        actorRole: UserRole.teacher,
        teacherAssignments: teacherASubjectOnly,
        classId: '6',
        sectionId: 'A',
        subjectId: 'math',
      );
      expect(canManageMath, isTrue);

      final canManageEnglish = authService.canManageMarks(
        actorRole: UserRole.teacher,
        teacherAssignments: teacherASubjectOnly,
        classId: '6',
        sectionId: 'A',
        subjectId: 'english',
      );
      expect(
        canManageEnglish,
        isFalse,
        reason: 'Teacher A cannot edit unassigned subject (English)',
      );
    });

    // Test 7: Teacher A tries to change their role to principal -> DENY
    test(
      'Test 7: Teacher A tries to change their role to principal -> DENY',
      () {
        final canChangeRole = authService.canModifyUserRole(
          actorRole: UserRole.teacher,
          targetRole: UserRole.principal,
        );
        expect(
          canChangeRole,
          isFalse,
          reason: 'Teachers can never modify roles',
        );
      },
    );

    // Test 8: Teacher A tries to modify fee records -> DENY
    test('Test 8: Teacher A tries to modify fee records -> DENY', () {
      final canManageFees = authService.canManageFees(
        actorRole: UserRole.teacher,
      );
      expect(
        canManageFees,
        isFalse,
        reason: 'Teachers have no write access to financial fee records',
      );
    });

    // Test 9: Principal accesses Class 6A -> ALLOW
    test('Test 9: Principal accesses Class 6A -> ALLOW', () {
      final canAccessStudent = authService.canAccessStudent(
        actorRole: UserRole.principal,
        teacherAssignments: const [],
        student: student6A,
      );
      final canManageAttendance = authService.canManageAttendance(
        actorRole: UserRole.principal,
        teacherAssignments: const [],
        classId: '6',
        sectionId: 'A',
      );
      final canManageFees = authService.canManageFees(
        actorRole: UserRole.principal,
      );

      expect(canAccessStudent, isTrue);
      expect(canManageAttendance, isTrue);
      expect(canManageFees, isTrue);
    });

    // Test 10: Principal accesses Class 6B -> ALLOW
    test('Test 10: Principal accesses Class 6B -> ALLOW', () {
      final canAccessStudent = authService.canAccessStudent(
        actorRole: UserRole.principal,
        teacherAssignments: const [],
        student: student6B,
      );
      final canManageAttendance = authService.canManageAttendance(
        actorRole: UserRole.principal,
        teacherAssignments: const [],
        classId: '6',
        sectionId: 'B',
      );
      final canManageMarks = authService.canManageMarks(
        actorRole: UserRole.principal,
        teacherAssignments: const [],
        classId: '6',
        sectionId: 'B',
        subjectId: 'science',
      );

      expect(canAccessStudent, isTrue);
      expect(canManageAttendance, isTrue);
      expect(canManageMarks, isTrue);
    });
  });
}

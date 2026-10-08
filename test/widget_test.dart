import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schooltesting/core/errors/app_error.dart';

import 'package:schooltesting/core/errors/result.dart';
import 'package:schooltesting/domain/models/attendance_record.dart';
import 'package:schooltesting/domain/models/fee_record.dart';
import 'package:schooltesting/domain/models/payment_record.dart';
import 'package:schooltesting/domain/models/student.dart';
import 'package:schooltesting/domain/models/teacher_assignment.dart';
import 'package:schooltesting/domain/models/user_profile.dart';
import 'package:schooltesting/domain/models/user_role.dart';
import 'package:schooltesting/domain/repositories/attendance_repository.dart';
import 'package:schooltesting/domain/repositories/auth_repository.dart';
import 'package:schooltesting/domain/repositories/fee_repository.dart';
import 'package:schooltesting/domain/repositories/student_repository.dart';
import 'package:schooltesting/domain/repositories/teacher_assignment_repository.dart';
import 'package:schooltesting/main.dart';

class MockAuthRepository implements AuthRepository {
  UserProfile? mockProfile;
  final List<UserProfile> staffList = [];
  bool shouldFailOtp = false;

  @override
  Stream<String?> get authStateChanges => Stream.value(mockProfile?.uid);

  @override
  String? get currentUserId => mockProfile?.uid;

  @override
  Future<Result<void>> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    required void Function(String uid) onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    // Immediately send verification ID
    onCodeSent('test_verification_id_123', 1);
    return const Result.success(null);
  }

  @override
  Future<Result<String>> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (shouldFailOtp || smsCode != '123456') {
      return Result.failure(ValidationError('Invalid OTP code'));
    }
    return Result.success(mockProfile?.uid ?? 'test_uid_01');
  }

  @override
  Future<Result<UserProfile?>> getCurrentUserProfile() async {
    return Result.success(mockProfile);
  }

  @override
  Future<Result<UserProfile?>> getUserProfileByPhone(
    String normalizedPhone,
  ) async {
    if (mockProfile?.phoneNumber == normalizedPhone) {
      return Result.success(mockProfile);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> provisionUser(UserProfile profile) async {
    staffList.add(profile);
    return const Result.success(null);
  }

  @override
  Future<Result<List<UserProfile>>> getSchoolStaffUsers(String schoolId) async {
    return Result.success(staffList);
  }

  @override
  Future<Result<void>> setUserActiveStatus({
    required String uid,
    required bool isActive,
    required String changedByUserId,
  }) async {
    final idx = staffList.indexWhere((u) => u.uid == uid);
    if (idx != -1) {
      staffList[idx] = staffList[idx].copyWith(isActive: isActive);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<UserRole>> fetchAuthoritativeRole() async {
    return Result.success(mockProfile?.role ?? UserRole.parent);
  }

  @override
  Future<Result<void>> signOut() async {
    mockProfile = null;
    return const Result.success(null);
  }
}

// Test implementation representing an empty database state (Rule 20)
class EmptyStudentRepository implements StudentRepository {
  @override
  Stream<List<Student>> watchStudents({String? classId, String? section}) =>
      Stream.value([]);

  @override
  Future<Result<Student?>> getStudent(String studentId) async =>
      const Result.success(null);

  @override
  Future<Result<List<Student>>> getStudentsByClass({
    required String classId,
    required String section,
  }) async => const Result.success([]);

  @override
  Future<Result<List<Student>>> getStudentsForParent(
    String parentUserId,
  ) async => const Result.success([]);

  @override
  Future<Result<void>> createStudent(Student student) async =>
      const Result.success(null);

  @override
  Future<Result<void>> updateStudent(Student student) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deactivateStudent(String studentId) async =>
      const Result.success(null);

  @override
  Future<Result<int>> getTotalStudentCount() async => const Result.success(0);
}

class EmptyAttendanceRepository implements AttendanceRepository {
  @override
  Future<Result<List<AttendanceRecord>>> getStudentAttendance(
    String studentId,
  ) async => const Result.success([]);

  @override
  Future<Result<List<AttendanceRecord>>> getClassAttendance({
    required String classId,
    required String section,
    required DateTime date,
  }) async => const Result.success([]);

  @override
  Future<Result<void>> saveAttendance({
    required List<AttendanceRecord> records,
    required String teacherUserId,
  }) async => const Result.success(null);
}

class EmptyFeeRepository implements FeeRepository {
  @override
  Future<Result<List<FeeRecord>>> getFeesForStudent(String studentId) async =>
      const Result.success([]);

  @override
  Future<Result<Map<String, double>>> getSchoolFeeMetrics(
    String schoolId,
  ) async => const Result.success({
    'totalAssigned': 0.0,
    'totalCollected': 0.0,
    'totalConcession': 0.0,
    'pendingBalance': 0.0,
  });

  @override
  Future<Result<PaymentRecord>> recordOfflinePayment({
    required String schoolId,
    required FeeRecord feeRecord,
    required double amount,
    required PaymentMethod paymentMethod,
    String? referenceNumber,
    required String recordedByUserId,
    String? notes,
  }) async => throw UnimplementedError();

  @override
  Future<Result<List<PaymentRecord>>> getPaymentsForFee(
    String feeRecordId,
  ) async => const Result.success([]);

  @override
  Future<Result<PaymentRecord>> reversePayment({
    required PaymentRecord payment,
    required String reversedByUserId,
    required String reason,
  }) async => throw UnimplementedError();
}

class EmptyTeacherAssignmentRepository implements TeacherAssignmentRepository {
  @override
  Future<Result<List<TeacherAssignment>>> getTeacherAssignments(
    String teacherId,
  ) async => const Result.success([]);

  @override
  Future<Result<int>> getActiveAssignmentCount(String academicYearId) async =>
      const Result.success(0);

  @override
  Future<Result<void>> assignTeacher(TeacherAssignment assignment) async =>
      const Result.success(null);
}

void main() {
  testWidgets('Unauthenticated user is gated by LoginScreen and Phone OTP', (
    WidgetTester tester,
  ) async {
    final authRepo = MockAuthRepository();

    // App starts without authenticated session -> LoginScreen
    await tester.pumpWidget(
      MPSApp(
        authRepository: authRepo,
        studentRepository: EmptyStudentRepository(),
        attendanceRepository: EmptyAttendanceRepository(),
        feeRepository: EmptyFeeRepository(),
        assignmentRepository: EmptyTeacherAssignmentRepository(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Login Screen is displayed
    expect(find.text('MPS Portal Login'), findsOneWidget);
    expect(find.text('Phone Number + OTP Verification'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);

    // Enter valid 10-digit mobile number
    final phoneField = find.byType(TextField).first;
    await tester.enterText(phoneField, '9876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    // Verify OTP field and masked phone are displayed
    expect(find.textContaining('OTP sent to +91 ******3210'), findsOneWidget);
    expect(find.text('Verify OTP'), findsOneWidget);
    expect(find.textContaining('Resend OTP in'), findsOneWidget);

    // Set up mock profile for successful verification
    authRepo.mockProfile = UserProfile(
      uid: 'principal_01',
      phoneNumber: '+919876543210',
      fullName: 'Dr. Anand Verma',
      role: UserRole.principal,
      isActive: true,
      schoolId: 'mps_main',
      createdAt: DateTime.now(),
    );

    // Enter valid 6-digit OTP
    final otpField = find.byType(TextField).first;
    await tester.enterText(otpField, '123456');
    await tester.tap(find.text('Verify OTP'));
    await tester.pumpAndSettle();

    // Verify user is routed to Principal Dashboard
    expect(
      find.textContaining('MPS Administrative & Security Overview'),
      findsOneWidget,
    );
    expect(find.textContaining('Dr. Anand Verma'), findsOneWidget);
    expect(find.text('Staff Directory'), findsOneWidget);
  });

  testWidgets('Principal can access Staff Directory and User Provisioning', (
    WidgetTester tester,
  ) async {
    final authRepo = MockAuthRepository();
    final principalProfile = UserProfile(
      uid: 'principal_01',
      phoneNumber: '+919876543210',
      fullName: 'Dr. Anand Verma',
      role: UserRole.principal,
      isActive: true,
      schoolId: 'mps_main',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MPSApp(
        authRepository: authRepo,
        studentRepository: EmptyStudentRepository(),
        attendanceRepository: EmptyAttendanceRepository(),
        feeRepository: EmptyFeeRepository(),
        assignmentRepository: EmptyTeacherAssignmentRepository(),
        initialProfile: principalProfile,
      ),
    );
    await tester.pumpAndSettle();

    // Verify Principal Dashboard opens directly
    expect(find.text('Staff Directory'), findsOneWidget);

    // Tap Staff Directory to open Staff Provisioning Screen
    await tester.tap(find.text('Staff Directory'));
    await tester.pumpAndSettle();

    // Verify Staff Provisioning Screen renders
    expect(find.text('Staff & User Management'), findsOneWidget);
    expect(find.text('No Staff Accounts Provisioned'), findsOneWidget);
    expect(find.text('Provision First Staff Member'), findsOneWidget);

    // Test Theme toggle
    final themeToggle = find.byIcon(Icons.dark_mode);
    if (themeToggle.evaluate().isNotEmpty) {
      await tester.tap(themeToggle);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    }
  });

  testWidgets('Teacher account is locked to assigned view and sign out works', (
    WidgetTester tester,
  ) async {
    final authRepo = MockAuthRepository();
    final teacherProfile = UserProfile(
      uid: 'teacher_01',
      phoneNumber: '+919876543211',
      fullName: 'Sunita Sharma',
      role: UserRole.teacher,
      isActive: true,
      schoolId: 'mps_main',
      staffId: 'MPS-TCH-001',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MPSApp(
        authRepository: authRepo,
        studentRepository: EmptyStudentRepository(),
        attendanceRepository: EmptyAttendanceRepository(),
        feeRepository: EmptyFeeRepository(),
        assignmentRepository: EmptyTeacherAssignmentRepository(),
        initialProfile: teacherProfile,
      ),
    );
    await tester.pumpAndSettle();

    // Teacher cannot see Staff Directory or Principal controls
    expect(find.text('Staff Directory'), findsNothing);
    expect(find.text('No Active Class Assignments'), findsOneWidget);
    expect(find.textContaining('Sunita Sharma'), findsOneWidget);

    // Sign out
    final signOutButton = find.byIcon(Icons.logout);
    expect(signOutButton, findsOneWidget);
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Sign Out of MPS'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Out'));
    await tester.pumpAndSettle();

    // User is back on LoginScreen
    expect(find.text('MPS Portal Login'), findsOneWidget);
  });
}

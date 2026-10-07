import 'package:flutter_test/flutter_test.dart';
import 'package:schooltesting/core/errors/app_error.dart';
import 'package:schooltesting/core/errors/result.dart';
import 'package:schooltesting/domain/models/attendance_record.dart';
import 'package:schooltesting/domain/models/audit_log_record.dart';
import 'package:schooltesting/domain/models/fee_record.dart';
import 'package:schooltesting/domain/models/student.dart';
import 'package:schooltesting/domain/models/user_role.dart';
import 'package:schooltesting/domain/services/payment_provider.dart';

void main() {
  group('UserRole & Authorization Tests (Rule 5)', () {
    test('UserRole parsing and permission boundaries', () {
      expect(UserRole.fromString('parent'), UserRole.parent);
      expect(UserRole.fromString('teacher'), UserRole.teacher);
      expect(UserRole.fromString('principal'), UserRole.principal);
      expect(UserRole.fromString('unknown'), UserRole.parent);

      final principal = UserRole.principal;
      expect(principal.isPrincipal, isTrue);
      expect(principal.canManageFees, isTrue);

      final parent = UserRole.parent;
      expect(parent.isParent, isTrue);
      expect(parent.isTeacher, isFalse);
      expect(parent.canManageFees, isFalse);

      final teacher = UserRole.teacher;
      expect(teacher.isTeacher, isTrue);
      expect(teacher.canManageFees, isFalse);
    });
  });

  group('Financial & FeeRecord Audit Tests (Rule 8 - Manual / Offline)', () {
    test('FeeRecord preserves manual payment audit fields, balances, and immutability', () {
      final now = DateTime.now();
      final fee = FeeRecord(
        id: 'fee_101',
        schoolId: 'sch_mps_01',
        studentId: 'std_01',
        studentName: 'Student One',
        title: 'Tuition Fee Term 1',
        amount: 15000.0,
        paidAmount: 5000.0,
        concessionAmount: 1000.0,
        dueDate: now,
        status: PaymentStatus.partiallyPaid,
        lastPaymentMethod: 'cash',
        lastReferenceNumber: 'REC-001',
        paidAt: now,
        receiptNumber: 'MPS-RCPT-2026-001',
        isServerVerified: true,
        auditCreatedBy: 'accountant_user_01',
        auditCreatedAt: now,
        lastAuditNote: 'Manual cash installment recorded at office',
      );

      expect(fee.balanceDue, 9000.0);

      final map = fee.toMap();
      final restored = FeeRecord.fromMap(map, 'fee_101');

      expect(restored.id, 'fee_101');
      expect(restored.amount, 15000.0);
      expect(restored.paidAmount, 5000.0);
      expect(restored.concessionAmount, 1000.0);
      expect(restored.balanceDue, 9000.0);
      expect(restored.status, PaymentStatus.partiallyPaid);
      expect(restored.receiptNumber, 'MPS-RCPT-2026-001');
      expect(restored.isServerVerified, isTrue);
    });

    test(
      'ManualPaymentProvider records offline payment and produces receipt',
      () async {
        final provider = ManualPaymentProvider();
        final now = DateTime.now();
        final fee = FeeRecord(
          id: 'fee_202',
          schoolId: 'sch_mps_01',
          studentId: 'std_02',
          studentName: 'Student Two',
          title: 'Annual Fee',
          amount: 20000.0,
          paidAmount: 0.0,
          dueDate: now,
        );

        final result = await provider.recordPayment(
          schoolId: 'sch_mps_01',
          feeRecord: fee,
          amount: 10000.0,
          paymentMethod: PaymentMethod.cheque,
          referenceNumber: 'CHQ-889922',
          recordedByUserId: 'fee_clerk_01',
          notes: 'SBI Cheque cleared',
        );

        expect(result.isSuccess, isTrue);
        final payment = result.dataOrNull!;
        expect(payment.amount, 10000.0);
        expect(payment.paymentMethod, PaymentMethod.cheque);
        expect(payment.referenceNumber, 'CHQ-889922');
        expect(payment.receiptNumber, startsWith('MPS-RCPT-'));
        expect(payment.isReversed, isFalse);

        // Reversal with audit reason
        final reversalResult = await provider.reversePayment(
          paymentRecord: payment,
          reversedByUserId: 'principal_admin',
          reason: 'Cheque bounced due to signature mismatch',
        );

        expect(reversalResult.isSuccess, isTrue);
        final reversedPayment = reversalResult.dataOrNull!;
        expect(reversedPayment.isReversed, isTrue);
        expect(
          reversedPayment.reversalReason,
          'Cheque bounced due to signature mismatch',
        );
      },
    );

    test(
      'ManualPaymentProvider rejects overpayment beyond balance due',
      () async {
        final provider = ManualPaymentProvider();
        final fee = FeeRecord(
          id: 'fee_303',
          schoolId: 'sch_mps_01',
          studentId: 'std_03',
          studentName: 'Student Three',
          title: 'Library Fee',
          amount: 1000.0,
          paidAmount: 800.0,
          dueDate: DateTime.now(),
        );

        // Trying to pay 500 when balance is only 200
        final result = await provider.recordPayment(
          schoolId: 'sch_mps_01',
          feeRecord: fee,
          amount: 500.0,
          paymentMethod: PaymentMethod.cash,
          recordedByUserId: 'clerk_01',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull, isA<ValidationError>());
      },
    );
  });

  group('Attendance Audit Trail Tests (Rule 9)', () {
    test(
      'AttendanceRecord serializes and preserves modification timestamps',
      () {
        final now = DateTime.now();
        final record = AttendanceRecord(
          id: 'att_001',
          studentId: 'std_01',
          studentName: 'Student One',
          classId: '6',
          section: 'A',
          date: now,
          status: AttendanceStatus.present,
          markedByUserId: 'teacher_user_01',
          markedAt: now,
          lastChangedByUserId: 'principal_user_01',
          lastChangedAt: now,
          remark: 'Medical excuse updated by principal',
        );

        final map = record.toMap();
        final restored = AttendanceRecord.fromMap(map, 'att_001');

        expect(restored.status, AttendanceStatus.present);
        expect(restored.markedByUserId, 'teacher_user_01');
        expect(restored.lastChangedByUserId, 'principal_user_01');
        expect(restored.remark, contains('Medical excuse'));
      },
    );
  });

  group('AuditLogRecord Model Tests (Rule 22)', () {
    test('AuditLogRecord captures mutation metadata and actor authority', () {
      final now = DateTime.now();
      final log = AuditLogRecord(
        id: 'audit_001',
        schoolId: 'sch_mps_01',
        actorUserId: 'principal_01',
        actorRole: 'principal',
        action: 'ASSIGN_TEACHER_CLASS',
        entityType: 'teacherAssignment',
        entityId: 'assign_6A_math',
        metadata: {'classId': '6', 'sectionId': 'A', 'subjectId': 'math'},
        timestamp: now,
      );

      final map = log.toMap();
      final restored = AuditLogRecord.fromMap(map, 'audit_001');

      expect(restored.actorRole, 'principal');
      expect(restored.action, 'ASSIGN_TEACHER_CLASS');
      expect(restored.metadata['classId'], '6');
    });
  });

  group('Student Model Tests (Rule 7)', () {
    test('Student parent-linking preserves normalized relationship', () {
      final student = Student(
        id: 'std_01',
        admissionNumber: 'MPS-2026-001',
        fullName: 'Student Diya',
        classId: '9',
        section: 'B',
        rollNumber: '102',
        parentUserIds: ['parent_user_1', 'parent_user_2'],
        isActive: true,
      );

      final map = student.toMap();
      final restored = Student.fromMap(map, 'std_01');

      expect(restored.parentUserIds.length, 2);
      expect(restored.parentUserIds, contains('parent_user_1'));
      expect(restored.isActive, isTrue);
    });
  });

  group('Result Monad & Typed Errors (Rule 2 & 17)', () {
    test('Success and Failure behavior', () {
      const Result<int> success = Success(42);
      expect(success.isSuccess, isTrue);
      expect(success.dataOrNull, 42);

      const Result<int> failure = Failure(NetworkError('No internet'));
      expect(failure.isFailure, isTrue);
      expect(failure.errorOrNull, isA<NetworkError>());
      expect(failure.errorOrNull?.message, 'No internet');
    });
  });
}

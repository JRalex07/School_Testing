import 'package:flutter_test/flutter_test.dart';
import 'package:schooltesting/core/utils/phone_number_formatter.dart';
import 'package:schooltesting/domain/models/user_profile.dart';
import 'package:schooltesting/domain/models/user_role.dart';

void main() {
  group('PhoneNumberFormatter Tests (Rule 4 & Section 4)', () {
    test(
      'Normalizes valid 10-digit Indian numbers to E.164 (+91XXXXXXXXXX)',
      () {
        expect(PhoneNumberFormatter.normalize('9876543210'), '+919876543210');
        expect(
          PhoneNumberFormatter.normalize('+919876543210'),
          '+919876543210',
        );
        expect(
          PhoneNumberFormatter.normalize('+91 98765 43210'),
          '+919876543210',
        );
        expect(PhoneNumberFormatter.normalize('09876543210'), '+919876543210');
        expect(PhoneNumberFormatter.normalize('919876543210'), '+919876543210');
        expect(PhoneNumberFormatter.normalize('6123456789'), '+916123456789');
        expect(PhoneNumberFormatter.normalize('7890123456'), '+917890123456');
        expect(PhoneNumberFormatter.normalize('8901234567'), '+918901234567');
      },
    );

    test('Rejects invalid phone numbers', () {
      expect(PhoneNumberFormatter.normalize(''), isNull);
      expect(PhoneNumberFormatter.normalize('12345'), isNull);
      expect(PhoneNumberFormatter.normalize('abcdefghij'), isNull);
      // Indian mobile numbers do not start with 1, 2, 3, 4, 5
      expect(PhoneNumberFormatter.normalize('5123456789'), isNull);
      expect(PhoneNumberFormatter.normalize('1800123456'), isNull);
      expect(
        PhoneNumberFormatter.normalize('98765432100'),
        isNull,
      ); // 11 digits
    });

    test('Masks phone numbers securely for OTP display', () {
      expect(PhoneNumberFormatter.mask('+919876543210'), '+91 ******3210');
    });

    test('Formats phone numbers cleanly for display', () {
      expect(
        PhoneNumberFormatter.formatDisplay('+919876543210'),
        '+91 98765 43210',
      );
    });
  });

  group('UserProfile Model Tests (Rule 4, 5, 10)', () {
    test('Serializes and deserializes UserProfile preserving all fields', () {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: 'usr_teacher_01',
        phoneNumber: '+919876543210',
        fullName: 'Sunita Sharma',
        role: UserRole.teacher,
        isActive: true,
        schoolId: 'mps_main',
        staffId: 'MPS-TCH-001',
        createdAt: now,
        lastLoginAt: now,
        metadata: {'subject': 'Mathematics', 'class': '6A'},
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap(map, 'usr_teacher_01');

      expect(restored.uid, 'usr_teacher_01');
      expect(restored.phoneNumber, '+919876543210');
      expect(restored.fullName, 'Sunita Sharma');
      expect(restored.role, UserRole.teacher);
      expect(restored.isActive, isTrue);
      expect(restored.staffId, 'MPS-TCH-001');
      expect(restored.metadata['subject'], 'Mathematics');
    });

    test('copyWith creates modified clone correctly', () {
      final profile = UserProfile(
        uid: 'usr_01',
        phoneNumber: '+919876543210',
        fullName: 'Rajesh Kumar',
        role: UserRole.parent,
        isActive: true,
        schoolId: 'mps_main',
        createdAt: DateTime.now(),
      );

      final deactivated = profile.copyWith(isActive: false);
      expect(deactivated.isActive, isFalse);
      expect(deactivated.fullName, 'Rajesh Kumar');
      expect(deactivated.role, UserRole.parent);
    });
  });
}

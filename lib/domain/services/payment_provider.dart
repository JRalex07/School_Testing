import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../models/fee_record.dart';
import '../models/payment_record.dart';

/// Provider interface allowing pluggable payment implementations.
/// Online gateways can be plugged in the future without changing fee records.
abstract class PaymentProvider {
  String get providerId;
  String get displayName;
  bool get isOnline;

  Future<Result<PaymentRecord>> recordPayment({
    required String schoolId,
    required FeeRecord feeRecord,
    required double amount,
    required PaymentMethod paymentMethod,
    String? referenceNumber,
    required String recordedByUserId,
    String? notes,
  });

  Future<Result<PaymentRecord>> reversePayment({
    required PaymentRecord paymentRecord,
    required String reversedByUserId,
    required String reason,
  });
}

/// Active manual / offline payment provider for MPS School Management System.
/// Handles Cash, Cheque, Bank Transfer, Demand Draft, and Concession records.
class ManualPaymentProvider implements PaymentProvider {
  @override
  String get providerId => 'manual_offline';

  @override
  String get displayName => 'Manual / Cash / Cheque Recording';

  @override
  bool get isOnline => false;

  @override
  Future<Result<PaymentRecord>> recordPayment({
    required String schoolId,
    required FeeRecord feeRecord,
    required double amount,
    required PaymentMethod paymentMethod,
    String? referenceNumber,
    required String recordedByUserId,
    String? notes,
  }) async {
    if (amount <= 0) {
      return const Failure(ValidationError('Payment amount must be greater than zero'));
    }

    if (amount > feeRecord.balanceDue) {
      return Failure(ValidationError(
        'Payment amount (₹$amount) cannot exceed outstanding balance (₹${feeRecord.balanceDue})',
      ));
    }

    final receiptNumber = 'MPS-RCPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

    final payment = PaymentRecord(
      id: paymentId,
      schoolId: schoolId,
      feeRecordId: feeRecord.id,
      studentId: feeRecord.studentId,
      amount: amount,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      receiptNumber: receiptNumber,
      paidAt: DateTime.now(),
      recordedByUserId: recordedByUserId,
      notes: notes,
    );

    return Success(payment);
  }

  @override
  Future<Result<PaymentRecord>> reversePayment({
    required PaymentRecord paymentRecord,
    required String reversedByUserId,
    required String reason,
  }) async {
    if (paymentRecord.isReversed) {
      return const Failure(ValidationError('Payment has already been reversed'));
    }

    if (reason.trim().isEmpty) {
      return const Failure(ValidationError('Reversal reason is mandatory for audit trail'));
    }

    final reversed = PaymentRecord(
      id: paymentRecord.id,
      schoolId: paymentRecord.schoolId,
      feeRecordId: paymentRecord.feeRecordId,
      studentId: paymentRecord.studentId,
      amount: paymentRecord.amount,
      paymentMethod: paymentRecord.paymentMethod,
      referenceNumber: paymentRecord.referenceNumber,
      receiptNumber: paymentRecord.receiptNumber,
      paidAt: paymentRecord.paidAt,
      recordedByUserId: paymentRecord.recordedByUserId,
      notes: paymentRecord.notes,
      isReversed: true,
      reversalReason: reason,
      reversedByUserId: reversedByUserId,
      reversedAt: DateTime.now(),
    );

    return Success(reversed);
  }
}

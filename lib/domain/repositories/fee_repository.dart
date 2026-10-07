import '../../core/errors/result.dart';
import '../models/fee_record.dart';
import '../models/payment_record.dart';

/// Contract for Fee Management and Manual Payment Recording.
/// Online payment gateways are disabled at this stage and replaced by manual recording.
abstract class FeeRepository {
  /// Fetch fee records for a specific student.
  Future<Result<List<FeeRecord>>> getFeesForStudent(String studentId);

  /// Fetch total collection metrics for administrative oversight.
  Future<Result<Map<String, double>>> getSchoolFeeMetrics(String schoolId);

  /// Record an offline payment (Cash, Cheque, Bank Transfer, Demand Draft).
  Future<Result<PaymentRecord>> recordOfflinePayment({
    required String schoolId,
    required FeeRecord feeRecord,
    required double amount,
    required PaymentMethod paymentMethod,
    String? referenceNumber,
    required String recordedByUserId,
    String? notes,
  });

  /// Fetch payment transactions for a specific fee record.
  Future<Result<List<PaymentRecord>>> getPaymentsForFee(String feeRecordId);

  /// Reverse a payment with required audit reason.
  Future<Result<PaymentRecord>> reversePayment({
    required PaymentRecord payment,
    required String reversedByUserId,
    required String reason,
  });
}

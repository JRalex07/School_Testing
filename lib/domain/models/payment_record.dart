import 'fee_record.dart';

/// Transaction record representing an individual payment towards a fee.
class PaymentRecord {
  final String id;
  final String schoolId;
  final String feeRecordId;
  final String studentId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String?
  referenceNumber; // e.g. Cheque No., Bank Ref, or Cash receipt No.
  final String receiptNumber;
  final DateTime paidAt;
  final String recordedByUserId;
  final String? notes;

  // Reversal / Correction tracking (Rule 8)
  final bool isReversed;
  final String? reversalReason;
  final String? reversedByUserId;
  final DateTime? reversedAt;

  const PaymentRecord({
    required this.id,
    required this.schoolId,
    required this.feeRecordId,
    required this.studentId,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    required this.receiptNumber,
    required this.paidAt,
    required this.recordedByUserId,
    this.notes,
    this.isReversed = false,
    this.reversalReason,
    this.reversedByUserId,
    this.reversedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'feeRecordId': feeRecordId,
      'studentId': studentId,
      'amount': amount,
      'paymentMethod': paymentMethod.value,
      'referenceNumber': referenceNumber,
      'receiptNumber': receiptNumber,
      'paidAt': paidAt.toIso8601String(),
      'recordedByUserId': recordedByUserId,
      'notes': notes,
      'isReversed': isReversed,
      'reversalReason': reversalReason,
      'reversedByUserId': reversedByUserId,
      'reversedAt': reversedAt?.toIso8601String(),
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentRecord(
      id: docId,
      schoolId: map['schoolId'] as String? ?? '',
      feeRecordId: map['feeRecordId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] as String?),
      referenceNumber: map['referenceNumber'] as String?,
      receiptNumber: map['receiptNumber'] as String? ?? '',
      paidAt:
          DateTime.tryParse(map['paidAt'] as String? ?? '') ?? DateTime.now(),
      recordedByUserId: map['recordedByUserId'] as String? ?? '',
      notes: map['notes'] as String?,
      isReversed: map['isReversed'] as bool? ?? false,
      reversalReason: map['reversalReason'] as String?,
      reversedByUserId: map['reversedByUserId'] as String?,
      reversedAt: map['reversedAt'] != null
          ? DateTime.tryParse(map['reversedAt'] as String)
          : null,
    );
  }
}

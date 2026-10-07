/// Payment status reflecting server-authoritative state.
enum PaymentStatus {
  unpaid('unpaid'),
  partiallyPaid('partiallyPaid'),
  paid('paid'),
  pendingVerification('pendingVerification'),
  reversed('reversed');

  final String value;
  const PaymentStatus(this.value);

  static PaymentStatus fromString(String? status) {
    return PaymentStatus.values.firstWhere(
      (s) => s.value.toLowerCase() == status?.toLowerCase(),
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

/// Payment method for fee collections (Manual / Offline Provider).
enum PaymentMethod {
  cash('cash'),
  cheque('cheque'),
  bankTransfer('bankTransfer'),
  demandDraft('demandDraft'),
  concession('concession');

  final String value;
  const PaymentMethod(this.value);

  static PaymentMethod fromString(String? method) {
    return PaymentMethod.values.firstWhere(
      (m) => m.value.toLowerCase() == method?.toLowerCase(),
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Strongly typed Fee and Payment record preserving complete financial audit trail.
class FeeRecord {
  final String id;
  final String schoolId;
  final String studentId;
  final String studentName;
  final String title;
  final double amount;
  final double paidAmount;
  final double concessionAmount;
  final String currency;
  final DateTime dueDate;
  final PaymentStatus status;

  // Manual payment details & Audit Trail
  final String? lastPaymentMethod;
  final String? lastReferenceNumber;
  final DateTime? paidAt;
  final String? receiptNumber;
  final bool isServerVerified;
  final String? auditCreatedBy;
  final DateTime? auditCreatedAt;
  final String? lastAuditNote;

  const FeeRecord({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.amount,
    this.paidAmount = 0.0,
    this.concessionAmount = 0.0,
    this.currency = 'INR',
    required this.dueDate,
    this.status = PaymentStatus.unpaid,
    this.lastPaymentMethod,
    this.lastReferenceNumber,
    this.paidAt,
    this.receiptNumber,
    this.isServerVerified = true,
    this.auditCreatedBy,
    this.auditCreatedAt,
    this.lastAuditNote,
  });

  double get balanceDue =>
      (amount - paidAmount - concessionAmount).clamp(0.0, double.infinity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'studentId': studentId,
      'studentName': studentName,
      'title': title,
      'amount': amount,
      'paidAmount': paidAmount,
      'concessionAmount': concessionAmount,
      'currency': currency,
      'dueDate': dueDate.toIso8601String(),
      'status': status.value,
      'lastPaymentMethod': lastPaymentMethod,
      'lastReferenceNumber': lastReferenceNumber,
      'paidAt': paidAt?.toIso8601String(),
      'receiptNumber': receiptNumber,
      'isServerVerified': isServerVerified,
      'auditCreatedBy': auditCreatedBy,
      'auditCreatedAt': auditCreatedAt?.toIso8601String(),
      'lastAuditNote': lastAuditNote,
    };
  }

  factory FeeRecord.fromMap(Map<String, dynamic> map, String docId) {
    return FeeRecord(
      id: docId,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      concessionAmount: (map['concessionAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'INR',
      dueDate:
          DateTime.tryParse(map['dueDate'] as String? ?? '') ?? DateTime.now(),
      status: PaymentStatus.fromString(map['status'] as String?),
      lastPaymentMethod: map['lastPaymentMethod'] as String?,
      lastReferenceNumber: map['lastReferenceNumber'] as String?,
      paidAt: map['paidAt'] != null
          ? DateTime.tryParse(map['paidAt'] as String)
          : null,
      receiptNumber: map['receiptNumber'] as String?,
      isServerVerified: map['isServerVerified'] as bool? ?? true,
      auditCreatedBy: map['auditCreatedBy'] as String?,
      auditCreatedAt: map['auditCreatedAt'] != null
          ? DateTime.tryParse(map['auditCreatedAt'] as String)
          : null,
      lastAuditNote: map['lastAuditNote'] as String?,
    );
  }
}

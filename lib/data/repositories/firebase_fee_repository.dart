import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/cache/cache_manager.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../../domain/models/fee_record.dart';
import '../../domain/models/payment_record.dart';
import '../../domain/repositories/fee_repository.dart';

/// Production Firestore implementation for Fee Management & Manual Payments (Rule 8).
class FirebaseFeeRepository implements FeeRepository {
  final FirebaseFirestore? _customFirestore;
  final CacheManager _cache;

  FirebaseFeeRepository({
    FirebaseFirestore? firestore,
    CacheManager? cache,
  })  : _customFirestore = firestore,
        _cache = cache ?? CacheManager();

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _feesRef =>
      _firestore.collection('fees');
  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _firestore.collection('payments');

  @override
  Future<Result<List<FeeRecord>>> getFeesForStudent(String studentId) async {
    final cacheKey = CacheKeys.studentFees(studentId);
    final cached = _cache.get<List<FeeRecord>>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logFirestore('READ /fees where studentId=$studentId');
      final snapshot = await _feesRef
          .where('studentId', isEqualTo: studentId)
          .orderBy('dueDate', descending: false)
          .get();

      final list = snapshot.docs
          .map((doc) => FeeRecord.fromMap(doc.data(), doc.id))
          .toList();

      _cache.set(
        cacheKey,
        list,
        ttl: const Duration(minutes: 5),
        scopeTag: 'student_$studentId',
      );
      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to fetch fees: $e'));
    }
  }

  @override
  Future<Result<Map<String, double>>> getSchoolFeeMetrics(
    String schoolId,
  ) async {
    final cacheKey = CacheKeys.schoolFeeMetrics(schoolId);
    final cached = _cache.get<Map<String, double>>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logFirestore('READ /fees aggregate for schoolId=$schoolId');
      final snapshot = await _feesRef
          .where('schoolId', isEqualTo: schoolId)
          .get();

      double totalAssigned = 0.0;
      double totalCollected = 0.0;
      double totalConcession = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalAssigned += (data['amount'] as num?)?.toDouble() ?? 0.0;
        totalCollected += (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
        totalConcession += (data['concessionAmount'] as num?)?.toDouble() ?? 0.0;
      }

      final pendingBalance = (totalAssigned - totalCollected - totalConcession)
          .clamp(0.0, double.infinity);

      final metrics = {
        'totalAssigned': totalAssigned,
        'totalCollected': totalCollected,
        'totalConcession': totalConcession,
        'pendingBalance': pendingBalance,
      };

      _cache.set(
        cacheKey,
        metrics,
        ttl: const Duration(minutes: 5),
        scopeTag: 'school_$schoolId',
      );
      return Result.success(metrics);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to fetch fee metrics: $e'));
    }
  }

  @override
  Future<Result<PaymentRecord>> recordOfflinePayment({
    required String schoolId,
    required FeeRecord feeRecord,
    required double amount,
    required PaymentMethod paymentMethod,
    String? referenceNumber,
    required String recordedByUserId,
    String? notes,
  }) async {
    if (amount <= 0) {
      return Result.failure(
        const ValidationError('Payment amount must be greater than zero'),
      );
    }

    try {
      _logFirestore('TRANSACTION recordOfflinePayment feeId=${feeRecord.id}');

      final paymentDocRef = _paymentsRef.doc();
      final feeDocRef = _feesRef.doc(feeRecord.id);
      final now = DateTime.now();
      final receiptNumber =
          'RCP-${now.millisecondsSinceEpoch.toString().substring(5)}';

      final payment = PaymentRecord(
        id: paymentDocRef.id,
        schoolId: schoolId,
        feeRecordId: feeRecord.id,
        studentId: feeRecord.studentId,
        amount: amount,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        receiptNumber: receiptNumber,
        paidAt: now,
        recordedByUserId: recordedByUserId,
        notes: notes,
      );

      await _firestore.runTransaction((transaction) async {
        final feeSnapshot = await transaction.get(feeDocRef);
        final currentFee = feeSnapshot.exists && feeSnapshot.data() != null
            ? FeeRecord.fromMap(feeSnapshot.data()!, feeSnapshot.id)
            : feeRecord;

        final newPaid = currentFee.paidAmount + amount;
        final newBalance = currentFee.amount - newPaid - currentFee.concessionAmount;
        final newStatus = newBalance <= 0
            ? PaymentStatus.paid
            : PaymentStatus.partiallyPaid;

        transaction.set(paymentDocRef, payment.toMap());
        transaction.update(feeDocRef, {
          'paidAmount': newPaid,
          'status': newStatus.value,
          'lastPaymentMethod': paymentMethod.value,
          'lastReferenceNumber': referenceNumber,
          'paidAt': now.toIso8601String(),
          'receiptNumber': receiptNumber,
          'lastAuditNote':
              'Offline payment recorded by $recordedByUserId at $now',
        });
      });

      // Cache Invalidation (Rule 10)
      _cache.invalidate(CacheKeys.studentFees(feeRecord.studentId));
      _cache.invalidateTag('student_${feeRecord.studentId}');
      _cache.invalidate(CacheKeys.schoolFeeMetrics(schoolId));
      _cache.invalidateTag('school_$schoolId');
      _cache.invalidateTag('fee_${feeRecord.id}');

      return Result.success(payment);
    } catch (e) {
      return Result.failure(
        DatabaseError('Failed to record offline payment: $e'),
      );
    }
  }

  @override
  Future<Result<List<PaymentRecord>>> getPaymentsForFee(
    String feeRecordId,
  ) async {
    final cacheKey = 'fee:$feeRecordId:payments';
    final cached = _cache.get<List<PaymentRecord>>(cacheKey);
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      _logFirestore('READ /payments where feeRecordId=$feeRecordId');
      final snapshot = await _paymentsRef
          .where('feeRecordId', isEqualTo: feeRecordId)
          .orderBy('paidAt', descending: true)
          .get();

      final list = snapshot.docs
          .map((doc) => PaymentRecord.fromMap(doc.data(), doc.id))
          .toList();

      _cache.set(
        cacheKey,
        list,
        ttl: const Duration(minutes: 5),
        scopeTag: 'fee_$feeRecordId',
      );
      return Result.success(list);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to fetch payments: $e'));
    }
  }

  @override
  Future<Result<PaymentRecord>> reversePayment({
    required PaymentRecord payment,
    required String reversedByUserId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      return Result.failure(
        const ValidationError('Reversal reason is strictly required (Rule 8)'),
      );
    }
    if (payment.isReversed) {
      return Result.failure(
        const ValidationError('Payment has already been reversed'),
      );
    }

    try {
      _logFirestore('TRANSACTION reversePayment paymentId=${payment.id}');
      final paymentDocRef = _paymentsRef.doc(payment.id);
      final feeDocRef = _feesRef.doc(payment.feeRecordId);
      final now = DateTime.now();

      final updatedPayment = PaymentRecord(
        id: payment.id,
        schoolId: payment.schoolId,
        feeRecordId: payment.feeRecordId,
        studentId: payment.studentId,
        amount: payment.amount,
        paymentMethod: payment.paymentMethod,
        referenceNumber: payment.referenceNumber,
        receiptNumber: payment.receiptNumber,
        paidAt: payment.paidAt,
        recordedByUserId: payment.recordedByUserId,
        notes: payment.notes,
        isReversed: true,
        reversalReason: reason,
        reversedByUserId: reversedByUserId,
        reversedAt: now,
      );

      await _firestore.runTransaction((transaction) async {
        final feeSnapshot = await transaction.get(feeDocRef);
        if (feeSnapshot.exists && feeSnapshot.data() != null) {
          final currentFee =
              FeeRecord.fromMap(feeSnapshot.data()!, feeSnapshot.id);
          final newPaid = (currentFee.paidAmount - payment.amount).clamp(
            0.0,
            double.infinity,
          );
          final newBalance =
              currentFee.amount - newPaid - currentFee.concessionAmount;
          final newStatus = newBalance <= 0
              ? PaymentStatus.paid
              : (newPaid > 0 ? PaymentStatus.partiallyPaid : PaymentStatus.unpaid);

          transaction.update(feeDocRef, {
            'paidAmount': newPaid,
            'status': newStatus.value,
            'lastAuditNote':
                'Payment ${payment.id} reversed by $reversedByUserId for reason: $reason',
          });
        }

        transaction.set(paymentDocRef, updatedPayment.toMap());
      });

      // Invalidate caches
      _cache.invalidate(CacheKeys.studentFees(payment.studentId));
      _cache.invalidateTag('student_${payment.studentId}');
      _cache.invalidate(CacheKeys.schoolFeeMetrics(payment.schoolId));
      _cache.invalidateTag('school_${payment.schoolId}');
      _cache.invalidateTag('fee_${payment.feeRecordId}');

      return Result.success(updatedPayment);
    } catch (e) {
      return Result.failure(DatabaseError('Failed to reverse payment: $e'));
    }
  }

  void _logFirestore(String message) {
    if (kDebugMode) {
      debugPrint('[FIRESTORE $message]');
    }
  }
}

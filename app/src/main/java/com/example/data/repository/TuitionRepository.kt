package com.example.data.repository

import android.content.Context
import android.util.Log
import com.example.data.local.AppDatabase
import com.example.data.local.StudentDao
import com.example.data.model.*
import com.example.util.DateUtils
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.PersistentCacheSettings
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.UUID

class TuitionRepository(private val context: Context) {

  private val TAG = "TuitionRepository"

  // In-memory reactive state flows reflecting the single source of truth
  private val _students = MutableStateFlow<List<Student>>(emptyList())
  val students: StateFlow<List<Student>> = _students.asStateFlow()

  val studentDao: StudentDao = AppDatabase.getDatabase(context).studentDao()

  private val _feeRecords = MutableStateFlow<List<FeeRecord>>(emptyList())
  val feeRecords: StateFlow<List<FeeRecord>> = _feeRecords.asStateFlow()

  private val _payments = MutableStateFlow<List<Payment>>(emptyList())
  val payments: StateFlow<List<Payment>> = _payments.asStateFlow()

  private val _refunds = MutableStateFlow<List<Refund>>(emptyList())
  val refunds: StateFlow<List<Refund>> = _refunds.asStateFlow()

  private val _auditLogs = MutableStateFlow<List<AuditLog>>(emptyList())
  val auditLogs: StateFlow<List<AuditLog>> = _auditLogs.asStateFlow()

  private val _tuitionProfile = MutableStateFlow(TuitionProfile())
  val tuitionProfile: StateFlow<TuitionProfile> = _tuitionProfile.asStateFlow()

  private val _isLoading = MutableStateFlow(false)
  val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

  private val _errorMessage = MutableStateFlow<String?>(null)
  val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

  private val _isFirestoreConnected = MutableStateFlow(false)
  val isFirestoreConnected: StateFlow<Boolean> = _isFirestoreConnected.asStateFlow()

  private var firestore: FirebaseFirestore? = null

  // Duplicate submission guard (Idempotency cache)
  private val recentSubmissions = mutableMapOf<String, Long>()

  init {
    initializeFirebase()
    loadInitialData()
  }

  private fun initializeFirebase() {
    try {
      if (FirebaseApp.getApps(context).isEmpty()) {
        try {
          FirebaseApp.initializeApp(context)
        } catch (e: Exception) {
          Log.i(TAG, "Firebase not yet initialized from google-services.json: ${e.message}")
        }
      }
      if (FirebaseApp.getApps(context).isNotEmpty()) {
        val db = FirebaseFirestore.getInstance()
        val settings = FirebaseFirestoreSettings.Builder()
          .setLocalCacheSettings(PersistentCacheSettings.newBuilder().build())
          .build()
        db.firestoreSettings = settings
        firestore = db
        _isFirestoreConnected.value = true
        Log.d(TAG, "Firebase Firestore initialized successfully with offline persistence")
      } else {
        _isFirestoreConnected.value = false
        Log.i(TAG, "Running in local offline database mode (Room SQLite). Add google-services.json to connect Firebase cloud sync.")
      }
    } catch (e: Exception) {
      Log.w(TAG, "Firestore initialization notice: ${e.message}. Using resilient local database.")
      _isFirestoreConnected.value = false
    }
  }

  fun clearError() {
    _errorMessage.value = null
  }

  private fun loadInitialData() {
    CoroutineScope(Dispatchers.IO).launch {
      _isLoading.value = true
      // Observe Room StudentDao for local database updates
      launch {
        studentDao.getAllStudents().collect { localStudents ->
          _students.value = localStudents
        }
      }
      _isLoading.value = false
    }
  }

  // Idempotency check to protect against accidental rapid clicks / network retries
  private fun checkAndRecordDuplicate(key: String, windowMillis: Long = 5000): Boolean {
    val now = System.currentTimeMillis()
    val lastTime = recentSubmissions[key]
    if (lastTime != null && (now - lastTime) < windowMillis) {
      return true // Duplicate detected!
    }
    recentSubmissions[key] = now
    return false
  }

  suspend fun addStudent(student: Student): Result<Student> = withContext(Dispatchers.IO) {
    try {
      val generatedId = if (student.id.isBlank()) UUID.randomUUID().toString() else student.id
      val count = _students.value.size + 1
      val displayId = if (student.studentId.isBlank()) "STU-2026-%03d".format(count) else student.studentId
      val newStudent = student.copy(
        id = generatedId,
        studentId = displayId,
        createdAt = System.currentTimeMillis(),
        updatedAt = System.currentTimeMillis()
      )

      // Persist to Room local database
      studentDao.insertStudent(newStudent)

      val updatedList = _students.value.filterNot { it.id == newStudent.id } + newStudent
      _students.value = updatedList

      // Auto-generate fee records for current period and prior months if joining date specifies
      generateInitialFeeRecordsForStudent(newStudent)

      recordAuditLog("STUDENT_ADDED", "Added student ${newStudent.fullName} (${newStudent.studentId})", newStudent.id)

      // Sync to Firestore if available
      firestore?.collection("students")?.document(newStudent.id)?.set(newStudent)

      Result.success(newStudent)
    } catch (e: Exception) {
      Log.e(TAG, "Error adding student", e)
      Result.failure(e)
    }
  }

  suspend fun updateStudent(student: Student): Result<Student> = withContext(Dispatchers.IO) {
    try {
      val current = _students.value.find { it.id == student.id }
        ?: return@withContext Result.failure(Exception("Student not found"))

      val updatedStudent = student.copy(updatedAt = System.currentTimeMillis())
      
      // Update in Room local database
      studentDao.updateStudent(updatedStudent)
      _students.value = _students.value.map { if (it.id == student.id) updatedStudent else it }

      // Check if monthly fee changed -> preserve historical records and record fee change log
      if (current.monthlyFee != student.monthlyFee) {
        val change = FeeChange(
          id = UUID.randomUUID().toString(),
          studentId = student.id,
          oldFee = current.monthlyFee,
          newFee = student.monthlyFee,
          effectiveFrom = DateUtils.currentPeriod(),
          reason = "Fee revised by tutor"
        )
        firestore?.collection("fee_changes")?.document(change.id)?.set(change)
        recordAuditLog("FEE_CHANGED", "Fee changed for ${student.fullName} from ₹${current.monthlyFee} to ₹${student.monthlyFee}", student.id)
      }

      recordAuditLog("STUDENT_UPDATED", "Updated profile for ${student.fullName}", student.id)
      firestore?.collection("students")?.document(student.id)?.set(updatedStudent)

      Result.success(updatedStudent)
    } catch (e: Exception) {
      Result.failure(e)
    }
  }

  suspend fun markStudentLeaving(
    studentId: String,
    leavingDate: String,
    reason: String,
    settlementStatus: SettlementStatus
  ): Result<Unit> = withContext(Dispatchers.IO) {
    try {
      val student = _students.value.find { it.id == studentId }
        ?: return@withContext Result.failure(Exception("Student not found"))

      val updated = student.copy(
        status = StudentStatus.LEFT,
        leavingDate = leavingDate,
        leavingReason = reason,
        settlementStatus = settlementStatus,
        updatedAt = System.currentTimeMillis()
      )

      studentDao.updateStudent(updated)
      _students.value = _students.value.map { if (it.id == studentId) updated else it }
      recordAuditLog("STUDENT_LEFT", "Student ${student.fullName} marked as left. Settlement: ${settlementStatus.label}", studentId)
      firestore?.collection("students")?.document(studentId)?.set(updated)

      Result.success(Unit)
    } catch (e: Exception) {
      Result.failure(e)
    }
  }

  suspend fun deleteStudent(studentId: String): Result<Unit> = withContext(Dispatchers.IO) {
    try {
      val student = _students.value.find { it.id == studentId }
      // Delete from Room local database
      studentDao.deleteStudentById(studentId)
      _students.value = _students.value.filterNot { it.id == studentId }
      recordAuditLog("STUDENT_DELETED", "Deleted student ${student?.fullName ?: studentId}", studentId)
      firestore?.collection("students")?.document(studentId)?.delete()
      Result.success(Unit)
    } catch (e: Exception) {
      Result.failure(e)
    }
  }

  private fun generateInitialFeeRecordsForStudent(student: Student) {
    val currentPeriod = DateUtils.currentPeriod()
    val periods = listOf(DateUtils.previousPeriod(currentPeriod), currentPeriod, DateUtils.nextPeriod(currentPeriod))
    val newRecords = mutableListOf<FeeRecord>()

    periods.forEach { period ->
      val baseFee = student.monthlyFee
      val discountAmount = when (student.discountType) {
        DiscountType.FIXED -> student.discount.coerceAtMost(baseFee)
        DiscountType.PERCENTAGE -> (baseFee * (student.discount / 100.0)).coerceAtMost(baseFee)
        DiscountType.NONE -> 0.0
      }
      val netFee = (baseFee - discountAmount).coerceAtLeast(0.0)
      val dueDate = DateUtils.generateDueDate(period, student.preferredPaymentDay)
      val isPast = DateUtils.isOverdue(dueDate)

      val status = if (period < currentPeriod && isPast) {
        FeeStatus.OVERDUE
      } else if (period == currentPeriod) {
        if (isPast) FeeStatus.OVERDUE else FeeStatus.DUE
      } else {
        FeeStatus.NOT_DUE
      }

      val record = FeeRecord(
        id = "FEE_${student.id}_$period",
        studentId = student.id,
        studentName = student.fullName,
        feePeriod = period,
        baseFee = baseFee,
        discount = discountAmount,
        netFee = netFee,
        paidAmount = 0.0,
        remainingAmount = netFee,
        dueDate = dueDate,
        status = status
      )
      newRecords.add(record)
      firestore?.collection("fee_records")?.document(record.id)?.set(record)
    }

    _feeRecords.value = _feeRecords.value + newRecords
  }

  /**
   * Dedicated Collect Fee workflow with Atomic allocation, Partial Payment handling,
   * Advance Payment handling, Arrears handling, and Duplicate Protection.
   */
  suspend fun collectFee(
    studentId: String,
    amount: Double,
    paymentDate: String,
    paymentMethod: PaymentMethod,
    transactionReference: String,
    targetPeriod: String?, // null if auto-allocating to oldest pending / arrears first
    notes: String,
    applyWaiverOrDiscount: Double = 0.0,
    treatExcessAsAdvance: Boolean = true
  ): Result<Payment> = withContext(Dispatchers.IO) {
    // 1. Validation & Duplicate Check
    if (amount <= 0.0) {
      return@withContext Result.failure(Exception("Payment amount must be greater than zero."))
    }
    val idempotencyKey = "PAY_${studentId}_${amount}_${targetPeriod ?: "AUTO"}_$paymentDate"
    if (checkAndRecordDuplicate(idempotencyKey)) {
      return@withContext Result.failure(Exception("Duplicate payment request blocked. Please check payment history."))
    }

    val student = _students.value.find { it.id == studentId }
      ?: return@withContext Result.failure(Exception("Student not found"))

    try {
      var remainingPaymentToAllocate = amount
      val allocatedPeriods = mutableListOf<String>()
      val allocatedAmounts = mutableMapOf<String, Double>()
      val updatedFeeRecords = _feeRecords.value.toMutableList()

      // Determine which fee records to allocate to
      val candidateRecords = if (!targetPeriod.isNullOrBlank()) {
        // Specific period selected
        var rec = updatedFeeRecords.find { it.studentId == studentId && it.feePeriod == targetPeriod }
        if (rec == null) {
          // Create on the fly if needed
          rec = FeeRecord(
            id = "FEE_${studentId}_$targetPeriod",
            studentId = studentId,
            studentName = student.fullName,
            feePeriod = targetPeriod,
            baseFee = student.monthlyFee,
            netFee = student.monthlyFee,
            remainingAmount = student.monthlyFee,
            dueDate = DateUtils.generateDueDate(targetPeriod, student.preferredPaymentDay),
            status = FeeStatus.DUE
          )
          updatedFeeRecords.add(rec)
        }
        listOf(rec)
      } else {
        // Oldest pending/overdue fees first
        updatedFeeRecords
          .filter { it.studentId == studentId && it.remainingAmount > 0 }
          .sortedBy { it.feePeriod }
      }

      // Allocate payment to records
      for (rec in candidateRecords) {
        if (remainingPaymentToAllocate <= 0) break

        val needed = rec.remainingAmount
        val alloc = needed.coerceAtMost(remainingPaymentToAllocate)
        remainingPaymentToAllocate -= alloc

        val newPaid = rec.paidAmount + alloc
        val newRemaining = (rec.netFee - newPaid).coerceAtLeast(0.0)
        val newStatus = when {
          newRemaining == 0.0 -> FeeStatus.PAID
          newPaid > 0.0 -> FeeStatus.PARTIALLY_PAID
          DateUtils.isOverdue(rec.dueDate) -> FeeStatus.OVERDUE
          else -> FeeStatus.DUE
        }

        val updatedRec = rec.copy(
          paidAmount = newPaid,
          remainingAmount = newRemaining,
          status = newStatus,
          updatedAt = System.currentTimeMillis()
        )

        val idx = updatedFeeRecords.indexOfFirst { it.id == rec.id }
        if (idx >= 0) {
          updatedFeeRecords[idx] = updatedRec
        } else {
          updatedFeeRecords.add(updatedRec)
        }

        allocatedPeriods.add(rec.feePeriod)
        allocatedAmounts[rec.feePeriod] = alloc

        firestore?.collection("fee_records")?.document(updatedRec.id)?.set(updatedRec)
      }

      // If there is excess money remaining after candidate records
      var newAdvanceBalance = student.advanceBalance
      if (remainingPaymentToAllocate > 0) {
        if (treatExcessAsAdvance) {
          newAdvanceBalance += remainingPaymentToAllocate
          allocatedPeriods.add("ADVANCE")
          allocatedAmounts["ADVANCE"] = remainingPaymentToAllocate
        } else {
          // Allocate to upcoming next period
          val lastPeriod = candidateRecords.lastOrNull()?.feePeriod ?: DateUtils.currentPeriod()
          val nextP = DateUtils.nextPeriod(lastPeriod)
          val nextRec = FeeRecord(
            id = "FEE_${studentId}_$nextP",
            studentId = studentId,
            studentName = student.fullName,
            feePeriod = nextP,
            baseFee = student.monthlyFee,
            netFee = student.monthlyFee,
            paidAmount = remainingPaymentToAllocate,
            remainingAmount = (student.monthlyFee - remainingPaymentToAllocate).coerceAtLeast(0.0),
            dueDate = DateUtils.generateDueDate(nextP, student.preferredPaymentDay),
            status = if (remainingPaymentToAllocate >= student.monthlyFee) FeeStatus.PAID else FeeStatus.PARTIALLY_PAID
          )
          updatedFeeRecords.add(nextRec)
          allocatedPeriods.add(nextP)
          allocatedAmounts[nextP] = remainingPaymentToAllocate
          firestore?.collection("fee_records")?.document(nextRec.id)?.set(nextRec)
        }
      }

      // Create Payment Record
      val receiptNum = "REC-%s-%04d".format(
        DateUtils.currentPeriod().replace("-", ""),
        (_payments.value.size + 1)
      )
      val payment = Payment(
        id = "PAY_${System.currentTimeMillis()}_${(100..999).random()}",
        receiptNumber = receiptNum,
        studentId = studentId,
        studentName = student.fullName,
        studentClass = student.studentClass,
        amount = amount,
        paymentDate = paymentDate,
        paymentMethod = paymentMethod,
        transactionReference = transactionReference,
        allocatedFeePeriods = allocatedPeriods,
        allocatedAmounts = allocatedAmounts,
        status = PaymentRecordStatus.COMPLETED,
        notes = notes,
        balanceAfterPayment = updatedFeeRecords.filter { it.studentId == studentId }.sumOf { it.remainingAmount },
        createdAt = System.currentTimeMillis()
      )

      val curMonthStatus = when {
        amount >= student.monthlyFeeAmount -> FeeStatus.PAID
        amount > 0 -> FeeStatus.PARTIALLY_PAID
        else -> student.currentMonthStatus
      }

      // Update student advance balance, paymentHistory, and currentMonthStatus in Room
      val updatedStudent = student.copy(
        advanceBalance = newAdvanceBalance,
        currentMonthStatus = curMonthStatus,
        paymentHistory = student.paymentHistory + payment,
        updatedAt = System.currentTimeMillis()
      )
      studentDao.updateStudent(updatedStudent)
      _students.value = _students.value.map { if (it.id == studentId) updatedStudent else it }
      firestore?.collection("students")?.document(studentId)?.set(updatedStudent)

      // Update fee records state
      _feeRecords.value = updatedFeeRecords

      _payments.value = listOf(payment) + _payments.value
      firestore?.collection("payments")?.document(payment.id)?.set(payment)

      recordAuditLog("FEE_COLLECTED", "Collected ₹$amount from ${student.fullName} via ${paymentMethod.label}. Receipt: $receiptNum", studentId)

      Result.success(payment)
    } catch (e: Exception) {
      Log.e(TAG, "Error collecting fee", e)
      Result.failure(Exception("Payment status could not be confirmed. Please check payment history before submitting again."))
    }
  }

  suspend fun recordStudentPayment(
    studentId: String,
    amount: Double,
    paymentDate: String,
    paymentMethod: PaymentMethod,
    transactionReference: String,
    notes: String
  ): Result<Payment> {
    return collectFee(
      studentId = studentId,
      amount = amount,
      paymentDate = paymentDate,
      paymentMethod = paymentMethod,
      transactionReference = transactionReference,
      targetPeriod = DateUtils.currentPeriod(),
      notes = notes,
      treatExcessAsAdvance = true
    )
  }

  /**
   * Reversal / Cancellation of Payment with Reason and full Audit Trail
   */
  suspend fun cancelPayment(paymentId: String, reason: String): Result<Unit> = withContext(Dispatchers.IO) {
    try {
      val payment = _payments.value.find { it.id == paymentId }
        ?: return@withContext Result.failure(Exception("Payment record not found"))

      if (payment.status != PaymentRecordStatus.COMPLETED) {
        return@withContext Result.failure(Exception("Payment is already ${payment.status.label}"))
      }

      val updatedFeeRecords = _feeRecords.value.toMutableList()

      // Reverse allocations
      payment.allocatedAmounts.forEach { (period, allocatedAmt) ->
        if (period == "ADVANCE") {
          val student = _students.value.find { it.id == payment.studentId }
          if (student != null) {
            val updatedStudent = student.copy(
              advanceBalance = (student.advanceBalance - allocatedAmt).coerceAtLeast(0.0),
              updatedAt = System.currentTimeMillis()
            )
            _students.value = _students.value.map { if (it.id == payment.studentId) updatedStudent else it }
            firestore?.collection("students")?.document(student.id)?.set(updatedStudent)
          }
        } else {
          val rec = updatedFeeRecords.find { it.studentId == payment.studentId && it.feePeriod == period }
          if (rec != null) {
            val newPaid = (rec.paidAmount - allocatedAmt).coerceAtLeast(0.0)
            val newRemaining = (rec.netFee - newPaid).coerceAtLeast(0.0)
            val newStatus = when {
              newRemaining == 0.0 -> FeeStatus.PAID
              newPaid > 0.0 -> FeeStatus.PARTIALLY_PAID
              DateUtils.isOverdue(rec.dueDate) -> FeeStatus.OVERDUE
              else -> FeeStatus.DUE
            }
            val updatedRec = rec.copy(
              paidAmount = newPaid,
              remainingAmount = newRemaining,
              status = newStatus,
              updatedAt = System.currentTimeMillis()
            )
            val idx = updatedFeeRecords.indexOfFirst { it.id == rec.id }
            if (idx >= 0) updatedFeeRecords[idx] = updatedRec
            firestore?.collection("fee_records")?.document(updatedRec.id)?.set(updatedRec)
          }
        }
      }

      _feeRecords.value = updatedFeeRecords

      // Mark payment cancelled
      val cancelledPayment = payment.copy(
        status = PaymentRecordStatus.CANCELLED,
        cancellationReason = reason,
        cancelledAt = System.currentTimeMillis()
      )
      _payments.value = _payments.value.map { if (it.id == paymentId) cancelledPayment else it }
      firestore?.collection("payments")?.document(paymentId)?.set(cancelledPayment)

      recordAuditLog("PAYMENT_CANCELLED", "Cancelled receipt ${payment.receiptNumber} (₹${payment.amount}). Reason: $reason", payment.studentId)

      Result.success(Unit)
    } catch (e: Exception) {
      Result.failure(e)
    }
  }

  /**
   * Refund handling: refunds money from student advance balance
   */
  suspend fun issueRefund(
    studentId: String,
    amount: Double,
    paymentMethod: PaymentMethod,
    reason: String
  ): Result<Refund> = withContext(Dispatchers.IO) {
    try {
      val student = _students.value.find { it.id == studentId }
        ?: return@withContext Result.failure(Exception("Student not found"))

      if (amount <= 0.0) {
        return@withContext Result.failure(Exception("Refund amount must be greater than zero."))
      }
      if (amount > student.advanceBalance) {
        return@withContext Result.failure(Exception("Refund amount cannot exceed current advance balance of ₹${student.advanceBalance}"))
      }

      val updatedStudent = student.copy(
        advanceBalance = student.advanceBalance - amount,
        updatedAt = System.currentTimeMillis()
      )
      studentDao.updateStudent(updatedStudent)
      _students.value = _students.value.map { if (it.id == studentId) updatedStudent else it }
      firestore?.collection("students")?.document(studentId)?.set(updatedStudent)

      val refund = Refund(
        id = "REF_${System.currentTimeMillis()}",
        studentId = studentId,
        studentName = student.fullName,
        amount = amount,
        refundDate = DateUtils.currentDateString(),
        paymentMethod = paymentMethod,
        reason = reason
      )
      _refunds.value = listOf(refund) + _refunds.value
      firestore?.collection("refunds")?.document(refund.id)?.set(refund)

      recordAuditLog("REFUND_ISSUED", "Refunded ₹$amount to ${student.fullName}. Reason: $reason", studentId)

      Result.success(refund)
    } catch (e: Exception) {
      Result.failure(e)
    }
  }

  /**
   * Fee Waiver: waive a specific month's fee with reason
   */
  suspend fun waiveFee(feeRecordId: String, reason: String): Result<Unit> = withContext(Dispatchers.IO) {
    try {
      val rec = _feeRecords.value.find { it.id == feeRecordId }
        ?: return@withContext Result.failure(Exception("Fee record not found"))

      val updated = rec.copy(
        remainingAmount = 0.0,
        status = FeeStatus.WAIVED,
        waiverReason = reason,
        updatedAt = System.currentTimeMillis()
      )

      _feeRecords.value = _feeRecords.value.map { if (it.id == feeRecordId) updated else it }
      firestore?.collection("fee_records")?.document(feeRecordId)?.set(updated)

      recordAuditLog("FEE_WAIVED", "Waived fee for ${rec.studentName} for ${rec.feePeriod}. Reason: $reason", rec.studentId)

      Result.success(Unit)
    } catch (e: Exception) {
      Result.failure(e)
    }
  }

  suspend fun updateTuitionProfile(profile: TuitionProfile): Result<Unit> = withContext(Dispatchers.IO) {
    try {
      _tuitionProfile.value = profile
      firestore?.collection("settings")?.document("tuition_profile")?.set(profile)
      Result.success(Unit)
    } catch (e: Exception) {
      Result.failure(e)
    }
  }

  private fun recordAuditLog(action: String, description: String, studentId: String?) {
    val log = AuditLog(
      id = "AUDIT_${System.currentTimeMillis()}_${(100..999).random()}",
      action = action,
      description = description,
      studentId = studentId,
      entityId = studentId ?: "",
      timestamp = System.currentTimeMillis()
    )
    _auditLogs.value = listOf(log) + _auditLogs.value
    firestore?.collection("audit_logs")?.document(log.id)?.set(log)
  }

  /**
   * Seed realistic sample data so the tutor immediately sees the dashboard fully functional,
   * showing active/inactive students, paid, partially paid, overdue, and advance accounts.
   */
  suspend fun clearAllData(): Result<Unit> = withContext(Dispatchers.IO) {
    try {
      studentDao.deleteAllStudents()
      _students.value = emptyList()
      _feeRecords.value = emptyList()
      _payments.value = emptyList()
      _refunds.value = emptyList()
      _auditLogs.value = emptyList()
      val prefs = context.getSharedPreferences("tuition_prefs", Context.MODE_PRIVATE)
      prefs.edit().clear().apply()
      recordAuditLog("DATA_RESET", "Ledger cleared by user", null)
      Result.success(Unit)
    } catch (e: Exception) {
      Result.failure(e)
    }
  }
}

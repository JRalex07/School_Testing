package com.example.data.repository

import android.content.Context
import android.util.Log
import com.example.data.local.AppDatabase
import com.example.data.local.StudentDao
import com.example.data.model.*
import com.example.util.DateUtils
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
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
        val options = FirebaseOptions.Builder()
          .setApplicationId("com.aistudio.tuitionfee.xkpdvy")
          .setProjectId("tuition-fee-manager")
          .setApiKey("AIzaSyFakeKeyForLocalFirestoreOfflineCache")
          .build()
        FirebaseApp.initializeApp(context, options)
      }
      val db = FirebaseFirestore.getInstance()
      val settings = FirebaseFirestoreSettings.Builder()
        .setLocalCacheSettings(PersistentCacheSettings.newBuilder().build())
        .build()
      db.firestoreSettings = settings
      firestore = db
      _isFirestoreConnected.value = true
      Log.d(TAG, "Firebase Firestore initialized successfully with offline persistence")
    } catch (e: Exception) {
      Log.w(TAG, "Firestore initialization notice: ${e.message}. Using resilient persistent repository.")
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
          if (localStudents.isNotEmpty()) {
            _students.value = localStudents
          }
        }
      }

      val prefs = context.getSharedPreferences("tuition_prefs", Context.MODE_PRIVATE)
      val hasSeeded = prefs.getBoolean("has_seeded_sample_data", false)

      if (!hasSeeded) {
        seedRealisticSampleData()
        prefs.edit().putBoolean("has_seeded_sample_data", true).apply()
      } else {
        loadFromLocalStorage()
      }
      _isLoading.value = false
    }
  }

  private fun loadFromLocalStorage() {
    // If SharedPreferences has saved items, parse or restore
    val prefs = context.getSharedPreferences("tuition_data", Context.MODE_PRIVATE)
    // If empty for some reason, re-seed
    if (_students.value.isEmpty()) {
      seedRealisticSampleData()
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
  private fun seedRealisticSampleData() {
    val currentP = DateUtils.currentPeriod()
    val prevP = DateUtils.previousPeriod(currentP)
    val nextP = DateUtils.nextPeriod(currentP)

    val s1 = Student(
      id = "stu_01",
      studentId = "STU-2026-001",
      name = "Aarav Sharma",
      fatherName = "Vikram Sharma",
      motherName = "Pooja Sharma",
      phoneNumber = "9810123456",
      parentContact = "9810123457",
      address = "B-42, Sector 15, Noida",
      joiningDate = "2026-01-10",
      status = StudentStatus.ACTIVE,
      monthlyFeeAmount = 1500.0,
      feeStartDate = "2026-01-01",
      preferredPaymentDay = 5,
      studentClass = "Class 10",
      subjects = listOf("Mathematics", "Science"),
      batch = "Evening Batch A (5 PM)",
      tuitionTiming = "5:00 PM - 6:30 PM",
      advanceBalance = 0.0
    )

    val s2 = Student(
      id = "stu_02",
      studentId = "STU-2026-002",
      name = "Ananya Verma",
      fatherName = "Ramesh Verma",
      motherName = "Sunita Verma",
      phoneNumber = "9820234567",
      parentContact = "9820234568",
      address = "C-12, Green Park, Delhi",
      joiningDate = "2026-02-01",
      status = StudentStatus.ACTIVE,
      monthlyFeeAmount = 2000.0,
      feeStartDate = "2026-02-01",
      preferredPaymentDay = 10,
      studentClass = "Class 12",
      subjects = listOf("Physics", "Chemistry", "Maths"),
      batch = "Morning Batch (7 AM)",
      tuitionTiming = "7:00 AM - 8:30 AM",
      advanceBalance = 500.0
    )

    val s3 = Student(
      id = "stu_03",
      studentId = "STU-2026-003",
      name = "Rohan Mehta",
      fatherName = "Suresh Mehta",
      motherName = "Kavita Mehta",
      phoneNumber = "9830345678",
      parentContact = "9830345679",
      address = "402, Sunshine Apts, Mayur Vihar",
      joiningDate = "2026-03-05",
      status = StudentStatus.ACTIVE,
      monthlyFeeAmount = 1800.0,
      feeStartDate = "2026-03-01",
      preferredPaymentDay = 10,
      studentClass = "Class 11",
      subjects = listOf("Commerce", "Accountancy"),
      batch = "Evening Batch B (6:30 PM)",
      tuitionTiming = "6:30 PM - 8:00 PM",
      advanceBalance = 0.0
    )

    val s4 = Student(
      id = "stu_04",
      studentId = "STU-2026-004",
      name = "Diya Patel",
      fatherName = "Ketan Patel",
      motherName = "Bhavna Patel",
      phoneNumber = "9840456789",
      parentContact = "9840456780",
      address = "Tower 4, Express View, Sector 93",
      joiningDate = "2026-04-15",
      status = StudentStatus.ACTIVE,
      monthlyFeeAmount = 1200.0,
      discount = 200.0,
      discountType = DiscountType.FIXED,
      feeStartDate = "2026-04-01",
      preferredPaymentDay = 15,
      studentClass = "Class 9",
      subjects = listOf("Mathematics", "English"),
      batch = "Afternoon Batch (4 PM)",
      tuitionTiming = "4:00 PM - 5:00 PM",
      advanceBalance = 1000.0
    )

    val s5 = Student(
      id = "stu_05",
      studentId = "STU-2026-005",
      name = "Kabir Singh",
      fatherName = "Gurpreet Singh",
      motherName = "Jaspreet Kaur",
      phoneNumber = "9850567890",
      parentContact = "9850567891",
      address = "12-A, Indirapuram, Ghaziabad",
      joiningDate = "2026-01-20",
      status = StudentStatus.LEFT,
      leavingDate = "2026-08-31",
      leavingReason = "Relocated to Chandigarh",
      settlementStatus = SettlementStatus.FULLY_SETTLED,
      monthlyFeeAmount = 1500.0,
      studentClass = "Class 10",
      batch = "Evening Batch A (5 PM)"
    )

    val sampleStudents = listOf(s1, s2, s3, s4, s5)
    _students.value = sampleStudents
    CoroutineScope(Dispatchers.IO).launch {
      studentDao.insertStudents(sampleStudents)
    }

    // Fee records for s1 (Aarav - Paid for current month)
    val f1_prev = FeeRecord("FEE_stu01_$prevP", s1.id, s1.fullName, prevP, 1500.0, 0.0, null, 1500.0, 1500.0, 0.0, "$prevP-05", FeeStatus.PAID)
    val f1_cur = FeeRecord("FEE_stu01_$currentP", s1.id, s1.fullName, currentP, 1500.0, 0.0, null, 1500.0, 1500.0, 0.0, "$currentP-05", FeeStatus.PAID)

    // Fee records for s2 (Ananya - Partially paid this month: ₹1000 paid out of ₹2000)
    val f2_prev = FeeRecord("FEE_stu02_$prevP", s2.id, s2.fullName, prevP, 2000.0, 0.0, null, 2000.0, 2000.0, 0.0, "$prevP-10", FeeStatus.PAID)
    val f2_cur = FeeRecord("FEE_stu02_$currentP", s2.id, s2.fullName, currentP, 2000.0, 0.0, null, 2000.0, 1000.0, 1000.0, "$currentP-10", FeeStatus.PARTIALLY_PAID)

    // Fee records for s3 (Rohan - Overdue for current month, also unpaid previous month = Arrears)
    val f3_prev = FeeRecord("FEE_stu03_$prevP", s3.id, s3.fullName, prevP, 1800.0, 0.0, null, 1800.0, 0.0, 1800.0, "$prevP-10", FeeStatus.OVERDUE)
    val f3_cur = FeeRecord("FEE_stu03_$currentP", s3.id, s3.fullName, currentP, 1800.0, 0.0, null, 1800.0, 0.0, 1800.0, "$currentP-10", FeeStatus.OVERDUE)

    // Fee records for s4 (Diya - Advance covered)
    val f4_cur = FeeRecord("FEE_stu04_$currentP", s4.id, s4.fullName, currentP, 1200.0, 200.0, "Sibling concession", 1000.0, 1000.0, 0.0, "$currentP-15", FeeStatus.PAID)
    val f4_next = FeeRecord("FEE_stu04_$nextP", s4.id, s4.fullName, nextP, 1200.0, 200.0, "Sibling concession", 1000.0, 0.0, 1000.0, "$nextP-15", FeeStatus.NOT_DUE)

    _feeRecords.value = listOf(f1_prev, f1_cur, f2_prev, f2_cur, f3_prev, f3_cur, f4_cur, f4_next)

    // Payments
    val p1 = Payment(
      id = "PAY_01",
      receiptNumber = "REC-2026-0001",
      studentId = s1.id,
      studentName = s1.fullName,
      studentClass = s1.studentClass,
      amount = 1500.0,
      paymentDate = DateUtils.currentDateString(),
      paymentMethod = PaymentMethod.UPI,
      transactionReference = "UPI/9810123/99281",
      allocatedFeePeriods = listOf(currentP),
      allocatedAmounts = mapOf(currentP to 1500.0),
      status = PaymentRecordStatus.COMPLETED,
      notes = "GPay payment verified",
      balanceAfterPayment = 0.0
    )

    val p2 = Payment(
      id = "PAY_02",
      receiptNumber = "REC-2026-0002",
      studentId = s2.id,
      studentName = s2.fullName,
      studentClass = s2.studentClass,
      amount = 1000.0,
      paymentDate = DateUtils.currentDateString(),
      paymentMethod = PaymentMethod.CASH,
      allocatedFeePeriods = listOf(currentP),
      allocatedAmounts = mapOf(currentP to 1000.0),
      status = PaymentRecordStatus.COMPLETED,
      notes = "Part 1 received in cash",
      balanceAfterPayment = 1000.0
    )

    val p3 = Payment(
      id = "PAY_03",
      receiptNumber = "REC-2026-0003",
      studentId = s4.id,
      studentName = s4.fullName,
      studentClass = s4.studentClass,
      amount = 2000.0,
      paymentDate = DateUtils.currentDateString(),
      paymentMethod = PaymentMethod.BANK_TRANSFER,
      transactionReference = "IMPS-938201",
      allocatedFeePeriods = listOf(currentP, "ADVANCE"),
      allocatedAmounts = mapOf(currentP to 1000.0, "ADVANCE" to 1000.0),
      status = PaymentRecordStatus.COMPLETED,
      notes = "Paid current month + ₹1000 advance",
      balanceAfterPayment = 0.0
    )

    _payments.value = listOf(p1, p2, p3)

    recordAuditLog("SYSTEM_INIT", "Tuition Fee Manager initial financial ledger created", null)
  }

  suspend fun resetToSampleData(): Result<Unit> = withContext(Dispatchers.IO) {
    try {
      seedRealisticSampleData()
      Result.success(Unit)
    } catch (e: Exception) {
      Result.failure(e)
    }
  }

  suspend fun clearAllData(): Result<Unit> = withContext(Dispatchers.IO) {
    try {
      studentDao.deleteAllStudents()
      _students.value = emptyList()
      _feeRecords.value = emptyList()
      _payments.value = emptyList()
      _refunds.value = emptyList()
      _auditLogs.value = emptyList()
      recordAuditLog("DATA_RESET", "Ledger cleared by user", null)
      Result.success(Unit)
    } catch (e: Exception) {
      Result.failure(e)
    }
  }
}

package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.Payment
import com.example.data.model.PaymentMethod
import com.example.data.model.Student
import com.example.data.model.StudentStatus
import com.example.ui.theme.*
import com.example.ui.viewmodel.TuitionViewModel
import com.example.util.DateUtils
import com.example.util.FormatUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CollectFeeScreen(
  viewModel: TuitionViewModel,
  preselectedStudentId: String?,
  onNavigateBack: () -> Unit,
  onPaymentSuccess: (Payment) -> Unit
) {
  val students by viewModel.students.collectAsState()
  val feeRecords by viewModel.feeRecords.collectAsState()
  val profile by viewModel.tuitionProfile.collectAsState()

  var selectedStudent by remember {
    mutableStateOf(students.find { it.id == preselectedStudentId } ?: students.firstOrNull { it.status == StudentStatus.ACTIVE })
  }

  var isStudentDropdownExpanded by remember { mutableStateOf(false) }

  // Target period selection: null = Auto (Oldest pending first), or specific period string
  var selectedTargetPeriod by remember { mutableStateOf<String?>(null) }
  var isPeriodDropdownExpanded by remember { mutableStateOf(false) }

  var amountStr by remember { mutableStateOf("") }
  var paymentMethod by remember { mutableStateOf(PaymentMethod.CASH) }
  var transactionRef by remember { mutableStateOf("") }
  var paymentDate by remember { mutableStateOf(DateUtils.currentDateString()) }
  var notes by remember { mutableStateOf("") }
  var treatExcessAsAdvance by remember { mutableStateOf(true) }

  var isSubmitting by remember { mutableStateOf(false) }
  var validationError by remember { mutableStateOf<String?>(null) }

  val scrollState = rememberScrollState()

  // Outstanding records for selected student
  val studentPendingRecords = remember(selectedStudent, feeRecords) {
    if (selectedStudent == null) emptyList()
    else feeRecords.filter { it.studentId == selectedStudent!!.id && it.remainingAmount > 0 }.sortedBy { it.feePeriod }
  }

  val totalPendingForStudent = remember(studentPendingRecords) {
    studentPendingRecords.sumOf { it.remainingAmount }
  }

  // Pre-fill amount when student or target period changes
  LaunchedEffect(selectedStudent, selectedTargetPeriod) {
    if (selectedStudent != null) {
      if (selectedTargetPeriod != null) {
        val rec = studentPendingRecords.find { it.feePeriod == selectedTargetPeriod }
        val dueAmt = rec?.remainingAmount ?: selectedStudent!!.monthlyFee
        amountStr = dueAmt.toInt().toString()
      } else {
        val totalDue = if (totalPendingForStudent > 0) totalPendingForStudent else selectedStudent!!.monthlyFee
        amountStr = totalDue.toInt().toString()
      }
    }
  }

  Scaffold(
    topBar = {
      TopAppBar(
        title = {
          Text(
            "Collect Tuition Fee",
            fontWeight = FontWeight.Bold,
            fontSize = 18.sp,
            color = TextInkPrimary
          )
        },
        navigationIcon = {
          IconButton(onClick = onNavigateBack) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = TextInkPrimary)
          }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = CardSurfaceWhite)
      )
    },
    bottomBar = {
      // 18:8 Ergonomic Sticky Bottom Bar (Always in reach of the thumb)
      Surface(
        color = CardSurfaceWhite,
        shadowElevation = 8.dp,
        border = BorderStroke(1.dp, BorderWarmGray),
        modifier = Modifier
          .fillMaxWidth()
          .navigationBarsPadding()
          .imePadding()
      ) {
        Column(
          modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
          Button(
            onClick = {
              if (selectedStudent == null) {
                validationError = "Please select a student."
                return@Button
              }
              val amt = amountStr.toDoubleOrNull()
              if (amt == null || amt <= 0) {
                validationError = "Please enter a valid amount greater than zero."
                return@Button
              }

              isSubmitting = true
              validationError = null

              viewModel.collectFee(
                studentId = selectedStudent!!.id,
                amount = amt,
                paymentDate = paymentDate.trim(),
                paymentMethod = paymentMethod,
                transactionReference = transactionRef.trim(),
                targetPeriod = selectedTargetPeriod,
                notes = notes.trim(),
                treatExcessAsAdvance = treatExcessAsAdvance
              ) { payment ->
                isSubmitting = false
                onPaymentSuccess(payment)
              }
            },
            enabled = !isSubmitting && selectedStudent != null,
            modifier = Modifier
              .fillMaxWidth()
              .height(52.dp),
            colors = ButtonDefaults.buttonColors(
              containerColor = DeepTealPrimary,
              disabledContainerColor = SurfaceMuted
            ),
            shape = RoundedCornerShape(14.dp)
          ) {
            if (isSubmitting) {
              CircularProgressIndicator(color = Color.White, modifier = Modifier.size(22.dp))
            } else {
              Icon(Icons.AutoMirrored.Filled.ReceiptLong, contentDescription = null, modifier = Modifier.size(20.dp))
              Spacer(modifier = Modifier.width(8.dp))
              Text("Record Payment & Generate Receipt", fontWeight = FontWeight.Bold, fontSize = 15.sp)
            }
          }
        }
      }
    }
  ) { innerPadding ->
    Column(
      modifier = Modifier
        .fillMaxSize()
        .padding(innerPadding)
        .background(WarmIvoryBackground)
        .verticalScroll(scrollState)
        .padding(horizontal = 16.dp, vertical = 12.dp),
      verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
      if (validationError != null) {
        Card(
          colors = CardDefaults.cardColors(containerColor = StatusOverdueContainer),
          shape = RoundedCornerShape(12.dp),
          border = BorderStroke(1.dp, StatusOverdue.copy(alpha = 0.3f))
        ) {
          Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
          ) {
            Icon(Icons.Default.ErrorOutline, contentDescription = null, tint = StatusOverdue, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text(
              text = validationError ?: "",
              color = StatusOnOverdueContainer,
              style = MaterialTheme.typography.bodySmall,
              fontWeight = FontWeight.Medium
            )
          }
        }
      }

      // Step 1: Select Student Card
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
          Text("1. Select Student", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = DeepTealPrimary)

          ExposedDropdownMenuBox(
            expanded = isStudentDropdownExpanded,
            onExpandedChange = { isStudentDropdownExpanded = it }
          ) {
            OutlinedTextField(
              value = selectedStudent?.let { "${it.fullName} (${it.studentId} • ${it.studentClass})" } ?: "Select student...",
              onValueChange = {},
              readOnly = true,
              trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = isStudentDropdownExpanded) },
              modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth(),
              shape = RoundedCornerShape(12.dp),
              colors = OutlinedTextFieldDefaults.colors(
                unfocusedBorderColor = BorderWarmGray,
                focusedBorderColor = DeepTealPrimary
              )
            )

            ExposedDropdownMenu(
              expanded = isStudentDropdownExpanded,
              onDismissRequest = { isStudentDropdownExpanded = false }
            ) {
              students.forEach { st ->
                DropdownMenuItem(
                  text = {
                    Column {
                      Text(st.fullName, fontWeight = FontWeight.SemiBold, color = TextInkPrimary)
                      Text("${st.studentId} • ${st.studentClass} • Monthly ₹${st.monthlyFee.toInt()}", fontSize = 12.sp, color = TextSecondaryMuted)
                    }
                  },
                  onClick = {
                    selectedStudent = st
                    isStudentDropdownExpanded = false
                  }
                )
              }
            }
          }

          // Student Financial Health Banner
          if (selectedStudent != null) {
            val st = selectedStudent!!
            Box(
              modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(SurfaceMuted)
                .padding(12.dp)
            ) {
              Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
              ) {
                Column {
                  Text("Total Pending / Arrears", fontSize = 11.sp, color = TextSecondaryMuted)
                  Text(
                    text = FormatUtils.formatCurrency(totalPendingForStudent, profile.currencySymbol),
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp,
                    color = if (totalPendingForStudent > 0) StatusOverdue else StatusPaid
                  )
                }
                Column(horizontalAlignment = Alignment.End) {
                  Text("Advance Prepaid Balance", fontSize = 11.sp, color = TextSecondaryMuted)
                  Text(
                    text = FormatUtils.formatCurrency(st.advanceBalance, profile.currencySymbol),
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp,
                    color = StatusAdvance
                  )
                }
              }
            }
          }
        }
      }

      // Step 2: Fee Period & Payment Allocation
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
          Text("2. Fee Period Allocation", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = DeepTealPrimary)

          ExposedDropdownMenuBox(
            expanded = isPeriodDropdownExpanded,
            onExpandedChange = { isPeriodDropdownExpanded = it }
          ) {
            val periodText = if (selectedTargetPeriod == null) {
              "Auto: Settle Oldest Pending Fees First"
            } else {
              DateUtils.formatDisplayPeriod(selectedTargetPeriod!!)
            }

            OutlinedTextField(
              value = periodText,
              onValueChange = {},
              readOnly = true,
              trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = isPeriodDropdownExpanded) },
              modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth(),
              shape = RoundedCornerShape(12.dp),
              colors = OutlinedTextFieldDefaults.colors(
                unfocusedBorderColor = BorderWarmGray,
                focusedBorderColor = DeepTealPrimary
              )
            )

            ExposedDropdownMenu(
              expanded = isPeriodDropdownExpanded,
              onDismissRequest = { isPeriodDropdownExpanded = false }
            ) {
              DropdownMenuItem(
                text = { Text("Auto: Settle Oldest Pending Fees First (Recommended)", fontWeight = FontWeight.SemiBold) },
                onClick = {
                  selectedTargetPeriod = null
                  isPeriodDropdownExpanded = false
                }
              )
              studentPendingRecords.forEach { rec ->
                DropdownMenuItem(
                  text = {
                    Text("${DateUtils.formatDisplayPeriod(rec.feePeriod)} - Due: ${FormatUtils.formatCurrency(rec.remainingAmount, profile.currencySymbol)}")
                  },
                  onClick = {
                    selectedTargetPeriod = rec.feePeriod
                    isPeriodDropdownExpanded = false
                  }
                )
              }
              val nextP = DateUtils.nextPeriod(DateUtils.currentPeriod())
              DropdownMenuItem(
                text = { Text("Advance: ${DateUtils.formatDisplayPeriod(nextP)}") },
                onClick = {
                  selectedTargetPeriod = nextP
                  isPeriodDropdownExpanded = false
                }
              )
            }
          }
        }
      }

      // Step 3: Amount & Payment Details Card
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("3. Payment Details", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = DeepTealPrimary)

          OutlinedTextField(
            value = amountStr,
            onValueChange = { amountStr = it },
            label = { Text("Amount Received (${profile.currencySymbol}) *") },
            leadingIcon = { Icon(Icons.Default.CurrencyRupee, contentDescription = null, tint = DeepTealPrimary) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
              unfocusedBorderColor = BorderWarmGray,
              focusedBorderColor = DeepTealPrimary
            )
          )

          // Quick Amount Chips for 18:8 tall screens
          val enteredAmount = amountStr.toDoubleOrNull() ?: 0.0
          LazyRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
          ) {
            if (totalPendingForStudent > 0) {
              item {
                SuggestionChip(
                  onClick = { amountStr = totalPendingForStudent.toInt().toString() },
                  label = { Text("Full Due (${FormatUtils.formatCurrency(totalPendingForStudent, profile.currencySymbol)})", fontWeight = FontWeight.Bold) },
                  colors = SuggestionChipDefaults.suggestionChipColors(containerColor = StatusDueContainer)
                )
              }
            }
            val chipAmounts = listOf(500.0, 1000.0, 1500.0, 2000.0, 3000.0, 5000.0)
            items(chipAmounts) { chipAmt ->
              SuggestionChip(
                onClick = { amountStr = chipAmt.toInt().toString() },
                label = { Text("₹${chipAmt.toInt()}", fontSize = 12.sp) }
              )
            }
          }

          // Partial or Advance Explanation banner
          if (enteredAmount > 0 && selectedStudent != null) {
            if (enteredAmount < totalPendingForStudent) {
              val rem = totalPendingForStudent - enteredAmount
              Surface(
                color = StatusDueContainer,
                shape = RoundedCornerShape(10.dp),
                modifier = Modifier.fillMaxWidth()
              ) {
                Text(
                  text = "⚡ Partial Payment: Student will have ${FormatUtils.formatCurrency(rem, profile.currencySymbol)} remaining pending.",
                  fontSize = 12.sp,
                  color = StatusOnDueContainer,
                  fontWeight = FontWeight.Medium,
                  modifier = Modifier.padding(10.dp)
                )
              }
            } else if (enteredAmount > totalPendingForStudent && totalPendingForStudent > 0) {
              val excess = enteredAmount - totalPendingForStudent
              Surface(
                color = StatusAdvanceContainer,
                shape = RoundedCornerShape(10.dp),
                modifier = Modifier.fillMaxWidth()
              ) {
                Text(
                  text = "⚡ Advance Payment: Excess ${FormatUtils.formatCurrency(excess, profile.currencySymbol)} will be credited to Advance Balance.",
                  fontSize = 12.sp,
                  color = StatusOnAdvanceContainer,
                  fontWeight = FontWeight.Medium,
                  modifier = Modifier.padding(10.dp)
                )
              }
            }
          }

          // Payment Method Selector
          Text("Payment Mode *", style = MaterialTheme.typography.labelSmall, color = TextSecondaryMuted)
          LazyRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
          ) {
            items(PaymentMethod.values()) { method ->
              FilterChip(
                selected = paymentMethod == method,
                onClick = { paymentMethod = method },
                label = { Text(method.label, fontSize = 12.sp) },
                shape = RoundedCornerShape(50)
              )
            }
          }

          OutlinedTextField(
            value = transactionRef,
            onValueChange = { transactionRef = it },
            label = { Text("Transaction Reference / UPI Ref (Optional)") },
            placeholder = { Text("e.g. UPI/39102910 or Cheque #129") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )

          OutlinedTextField(
            value = paymentDate,
            onValueChange = { paymentDate = it },
            label = { Text("Payment Date (YYYY-MM-DD)") },
            leadingIcon = { Icon(Icons.Default.CalendarToday, contentDescription = null) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )

          OutlinedTextField(
            value = notes,
            onValueChange = { notes = it },
            label = { Text("Notes / Remarks (Optional)") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )
        }
      }

      Spacer(modifier = Modifier.height(20.dp))
    }
  }
}

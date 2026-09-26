package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
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
import com.example.data.model.FeeStatus
import com.example.data.model.Student
import com.example.ui.components.FeeStatusBadge
import com.example.ui.components.PaymentStatusBadge
import com.example.ui.components.RecordPaymentDialog
import com.example.ui.components.StatCard
import com.example.ui.theme.*
import com.example.ui.viewmodel.TuitionViewModel
import com.example.util.DateUtils
import com.example.util.FormatUtils

@Composable
fun DashboardScreen(
  viewModel: TuitionViewModel,
  onNavigateToStudents: () -> Unit,
  onNavigateToAddStudent: () -> Unit,
  onNavigateToCollectFee: (String?) -> Unit,
  onNavigateToPendingFees: () -> Unit,
  onNavigateToPayments: () -> Unit,
  onNavigateToReports: () -> Unit,
  onNavigateToSettings: () -> Unit
) {
  val stats by viewModel.dashboardStats.collectAsState()
  val profile by viewModel.tuitionProfile.collectAsState()
  val payments by viewModel.payments.collectAsState()
  val students by viewModel.students.collectAsState()
  val feeRecords by viewModel.feeRecords.collectAsState()

  val currentPeriod = DateUtils.currentPeriod()
  val displayPeriod = DateUtils.formatDisplayPeriod(currentPeriod)

  // Direct 1-tap record payment dialog
  var studentForQuickPayment by remember { mutableStateOf<Student?>(null) }

  val collectionRate = if (stats.expectedFeeThisMonth > 0) {
    ((stats.collectedThisMonth / stats.expectedFeeThisMonth) * 100).toInt().coerceIn(0, 100)
  } else 0

  // Actionable receivables: students with pending or overdue fee this month
  val pendingActionStudents = remember(students, feeRecords, currentPeriod) {
    students.filter { student ->
      val rec = feeRecords.find { it.studentId == student.id && it.feePeriod == currentPeriod }
      val isUnpaid = rec != null && rec.status in listOf(FeeStatus.DUE, FeeStatus.OVERDUE, FeeStatus.PARTIALLY_PAID)
      isUnpaid || student.currentMonthStatus in listOf(FeeStatus.DUE, FeeStatus.OVERDUE, FeeStatus.PARTIALLY_PAID)
    }.take(4)
  }

  LazyColumn(
    modifier = Modifier
      .fillMaxSize()
      .background(WarmIvoryBackground),
    contentPadding = PaddingValues(bottom = 96.dp)
  ) {
    // 1. Calm, Human-Designed Header for Independent Tutor
    item {
      Surface(
        color = CardSurfaceWhite,
        modifier = Modifier.fillMaxWidth(),
        border = BorderStroke(1.dp, BorderWarmGray)
      ) {
        Column(
          modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 18.dp)
        ) {
          Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
          ) {
            Column {
              Text(
                text = profile.tuitionName.ifBlank { "Tutor Ledger" },
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = TextInkPrimary,
                fontSize = 20.sp
              )
              Spacer(modifier = Modifier.height(2.dp))
              Text(
                text = "${profile.teacherName.ifBlank { "Private Tutor" }} • $displayPeriod",
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondaryMuted,
                fontSize = 13.sp
              )
            }

            IconButton(
              onClick = onNavigateToSettings,
              modifier = Modifier
                .size(38.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(SurfaceMuted)
            ) {
              Icon(
                Icons.Default.Settings,
                contentDescription = "Settings",
                tint = TextSecondaryMuted,
                modifier = Modifier.size(18.dp)
              )
            }
          }

          Spacer(modifier = Modifier.height(16.dp))

          // Primary Actions: Deep Teal for Collect Fee and Add Student
          Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
          ) {
            Button(
              onClick = { onNavigateToCollectFee(null) },
              modifier = Modifier.weight(1.3f),
              colors = ButtonDefaults.buttonColors(containerColor = DeepTealPrimary),
              shape = RoundedCornerShape(12.dp)
            ) {
              Icon(Icons.Default.Payments, contentDescription = null, modifier = Modifier.size(16.dp))
              Spacer(modifier = Modifier.width(6.dp))
              Text("Collect Fee", fontWeight = FontWeight.Bold, fontSize = 13.sp)
            }

            OutlinedButton(
              onClick = onNavigateToAddStudent,
              modifier = Modifier.weight(1f),
              colors = ButtonDefaults.outlinedButtonColors(contentColor = DeepTealPrimary),
              border = BorderStroke(1.dp, DeepTealPrimary.copy(alpha = 0.5f)),
              shape = RoundedCornerShape(12.dp)
            ) {
              Icon(Icons.Default.PersonAdd, contentDescription = null, modifier = Modifier.size(16.dp))
              Spacer(modifier = Modifier.width(6.dp))
              Text("Add Student", fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
            }
          }
        }
      }
    }

    // 2. Overdue Attention Banner (Calm Brick Red indicator, not flashing/neon)
    if (stats.overdueAmount > 0) {
      item {
        Card(
          modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .clickable { onNavigateToPendingFees() },
          colors = CardDefaults.cardColors(containerColor = StatusOverdueContainer),
          shape = RoundedCornerShape(14.dp),
          border = BorderStroke(1.dp, StatusOverdue.copy(alpha = 0.35f)),
          elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
        ) {
          Row(
            modifier = Modifier
              .fillMaxWidth()
              .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
          ) {
            Row(
              verticalAlignment = Alignment.CenterVertically,
              horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
              Box(
                modifier = Modifier
                  .size(32.dp)
                  .clip(RoundedCornerShape(8.dp))
                  .background(StatusOverdue),
                contentAlignment = Alignment.Center
              ) {
                Icon(Icons.Default.Warning, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
              }
              Column {
                Text(
                  text = "Overdue Fees Follow-Up",
                  fontWeight = FontWeight.Bold,
                  color = StatusOnOverdueContainer,
                  fontSize = 14.sp
                )
                Text(
                  text = "${FormatUtils.formatCurrency(stats.overdueAmount, profile.currencySymbol)} pending across ${stats.overdueStudentsCount} student(s)",
                  fontSize = 12.sp,
                  color = StatusOnOverdueContainer.copy(alpha = 0.85f)
                )
              }
            }
            Text(
              text = "Review →",
              fontWeight = FontWeight.Bold,
              color = StatusOnOverdueContainer,
              fontSize = 13.sp
            )
          }
        }
      }
    }

    // 3. Actionable Receivables Queue (Clean white card, one-tap fee collection)
    if (pendingActionStudents.isNotEmpty()) {
      item {
        Card(
          modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
          colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
          shape = RoundedCornerShape(14.dp),
          border = BorderStroke(1.dp, BorderWarmGray),
          elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
        ) {
          Column(modifier = Modifier.padding(16.dp)) {
            Row(
              modifier = Modifier.fillMaxWidth(),
              horizontalArrangement = Arrangement.SpaceBetween,
              verticalAlignment = Alignment.CenterVertically
            ) {
              Column {
                Text(
                  text = "ACTIONABLE RECEIVABLES",
                  style = MaterialTheme.typography.labelSmall,
                  fontWeight = FontWeight.Bold,
                  color = DeepTealPrimary,
                  letterSpacing = 0.5.sp,
                  fontSize = 10.sp
                )
                Text(
                  text = "Uncollected Tuition This Month",
                  style = MaterialTheme.typography.titleMedium,
                  fontWeight = FontWeight.Bold,
                  color = TextInkPrimary
                )
              }
              Text(
                text = "View All →",
                style = MaterialTheme.typography.labelMedium,
                color = DeepTealPrimary,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.clickable { onNavigateToPendingFees() }
              )
            }

            Spacer(modifier = Modifier.height(12.dp))

            pendingActionStudents.forEachIndexed { index, student ->
              val rec = feeRecords.find { it.studentId == student.id && it.feePeriod == currentPeriod }
              val pendingAmount = rec?.remainingAmount ?: student.monthlyFeeAmount
              val status = rec?.status ?: student.currentMonthStatus

              Row(
                modifier = Modifier
                  .fillMaxWidth()
                  .padding(vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
              ) {
                Column(modifier = Modifier.weight(1f)) {
                  Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                      text = student.name,
                      fontWeight = FontWeight.Bold,
                      fontSize = 14.sp,
                      color = TextInkPrimary
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    FeeStatusBadge(status = status)
                  }
                  Text(
                    text = "${student.studentClass} • Due: ${FormatUtils.formatCurrency(pendingAmount, profile.currencySymbol)}",
                    fontSize = 12.sp,
                    color = TextSecondaryMuted
                  )
                }

                // Deep Teal 1-Tap Collection Button
                Button(
                  onClick = { studentForQuickPayment = student },
                  colors = ButtonDefaults.buttonColors(containerColor = DeepTealPrimary),
                  shape = RoundedCornerShape(8.dp),
                  contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                ) {
                  Icon(Icons.Default.Payment, contentDescription = null, modifier = Modifier.size(14.dp))
                  Spacer(modifier = Modifier.width(4.dp))
                  Text("Collect", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
              }

              if (index < pendingActionStudents.size - 1) {
                HorizontalDivider(color = BorderWarmGray.copy(alpha = 0.7f))
              }
            }
          }
        }
      }
    }

    // 4. Monthly Collection Realization Card (White card, subtle border)
    item {
      Card(
        modifier = Modifier
          .fillMaxWidth()
          .padding(horizontal = 16.dp, vertical = 6.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        shape = RoundedCornerShape(14.dp),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp)) {
          Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
          ) {
            Column {
              Text(
                text = "MONTHLY REALIZATION",
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = TextSecondaryMuted,
                letterSpacing = 0.5.sp,
                fontSize = 10.sp
              )
              Text(
                text = "${FormatUtils.formatCurrency(stats.collectedThisMonth, profile.currencySymbol)} of ${FormatUtils.formatCurrency(stats.expectedFeeThisMonth, profile.currencySymbol)}",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = TextInkPrimary
              )
            }
            Box(
              modifier = Modifier
                .clip(RoundedCornerShape(6.dp))
                .background(if (collectionRate >= 80) StatusPaidContainer else StatusDueContainer)
                .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
              Text(
                text = "$collectionRate% Realized",
                color = if (collectionRate >= 80) StatusOnPaidContainer else StatusOnDueContainer,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp
              )
            }
          }

          Spacer(modifier = Modifier.height(10.dp))
          LinearProgressIndicator(
            progress = { (collectionRate / 100f).coerceIn(0f, 1f) },
            modifier = Modifier
              .fillMaxWidth()
              .height(6.dp)
              .clip(RoundedCornerShape(3.dp)),
            color = DeepTealPrimary,
            trackColor = SurfaceMuted
          )

          Spacer(modifier = Modifier.height(10.dp))
          Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
          ) {
            Text(
              text = "Uncollected: ${FormatUtils.formatCurrency(stats.pendingThisMonth, profile.currencySymbol)}",
              fontSize = 12.sp,
              color = StatusDue,
              fontWeight = FontWeight.SemiBold
            )
            Text(
              text = "${stats.paidStudentsCount} of ${stats.activeStudents} students paid",
              fontSize = 12.sp,
              color = TextSecondaryMuted
            )
          }
        }
      }
    }

    // 5. Financial Ledger Overview (Neutral white cards, subtle borders, semantic accents)
    item {
      Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 6.dp)) {
        Text(
          text = "FINANCIAL SUMMARY",
          style = MaterialTheme.typography.labelSmall,
          fontWeight = FontWeight.Bold,
          color = TextSecondaryMuted,
          letterSpacing = 0.5.sp,
          modifier = Modifier.padding(vertical = 4.dp)
        )

        Row(
          modifier = Modifier.fillMaxWidth(),
          horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
          StatCard(
            title = "Collected",
            value = FormatUtils.formatCurrency(stats.collectedThisMonth, profile.currencySymbol),
            subtitle = "${stats.paidStudentsCount} settled",
            icon = Icons.Default.CheckCircle,
            iconBackgroundColor = StatusPaidContainer,
            iconTintColor = StatusPaid,
            indicatorText = "$collectionRate%",
            indicatorColor = StatusPaid,
            modifier = Modifier.weight(1f),
            onClick = onNavigateToPayments
          )

          StatCard(
            title = "Pending",
            value = FormatUtils.formatCurrency(stats.pendingThisMonth, profile.currencySymbol),
            subtitle = "${stats.pendingStudentsCount} students",
            icon = Icons.Default.HourglassBottom,
            iconBackgroundColor = StatusDueContainer,
            iconTintColor = StatusDue,
            indicatorText = "Due",
            indicatorColor = StatusDue,
            modifier = Modifier.weight(1f),
            onClick = onNavigateToPendingFees
          )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Row(
          modifier = Modifier.fillMaxWidth(),
          horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
          StatCard(
            title = "Overdue",
            value = FormatUtils.formatCurrency(stats.overdueAmount, profile.currencySymbol),
            subtitle = "Needs follow-up",
            icon = Icons.Default.Warning,
            iconBackgroundColor = StatusOverdueContainer,
            iconTintColor = StatusOverdue,
            indicatorText = "Arrears",
            indicatorColor = StatusOverdue,
            modifier = Modifier.weight(1f),
            onClick = onNavigateToPendingFees
          )

          StatCard(
            title = "Advance Held",
            value = FormatUtils.formatCurrency(stats.advanceAmountTotal, profile.currencySymbol),
            subtitle = "Prepaid balance",
            icon = Icons.Default.Savings,
            iconBackgroundColor = StatusAdvanceContainer,
            iconTintColor = StatusAdvance,
            indicatorText = "Prepaid",
            indicatorColor = StatusAdvance,
            modifier = Modifier.weight(1f),
            onClick = onNavigateToStudents
          )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Row(
          modifier = Modifier.fillMaxWidth(),
          horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
          StatCard(
            title = "Today",
            value = FormatUtils.formatCurrency(stats.paymentsTodayAmount, profile.currencySymbol),
            subtitle = "${stats.paymentsTodayCount} receipts",
            icon = Icons.Default.Today,
            modifier = Modifier.weight(1f),
            onClick = onNavigateToPayments
          )

          StatCard(
            title = "This Week",
            value = FormatUtils.formatCurrency(stats.paymentsThisWeekAmount, profile.currencySymbol),
            subtitle = "Weekly collection",
            icon = Icons.Default.DateRange,
            modifier = Modifier.weight(1f),
            onClick = onNavigateToPayments
          )
        }
      }
    }

    // 6. Student Roster Ratios Card
    item {
      Card(
        modifier = Modifier
          .fillMaxWidth()
          .padding(horizontal = 16.dp, vertical = 6.dp)
          .clickable { onNavigateToStudents() },
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        shape = RoundedCornerShape(14.dp),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp)) {
          Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
          ) {
            Text(
              text = "STUDENTS DIRECTORY",
              style = MaterialTheme.typography.labelSmall,
              fontWeight = FontWeight.Bold,
              color = DeepTealPrimary,
              letterSpacing = 0.5.sp,
              fontSize = 10.sp
            )
            Text(
              text = "Manage →",
              style = MaterialTheme.typography.labelMedium,
              color = DeepTealPrimary,
              fontWeight = FontWeight.Bold
            )
          }

          Spacer(modifier = Modifier.height(12.dp))

          Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceAround
          ) {
            EnrollmentStat(label = "Total", count = stats.totalStudents, color = TextInkPrimary)
            EnrollmentStat(label = "Active", count = stats.activeStudents, color = StatusPaid)
            EnrollmentStat(label = "Paid", count = stats.paidStudentsCount, color = DeepTealPrimary)
            EnrollmentStat(label = "Pending", count = stats.pendingStudentsCount, color = StatusDue)
            EnrollmentStat(label = "Left/Past", count = stats.inactiveStudents, color = TextSecondaryMuted)
          }
        }
      }
    }

    // 7. Recent Verified Receipts Feed
    item {
      Row(
        modifier = Modifier
          .fillMaxWidth()
          .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
      ) {
        Text(
          text = "RECENT RECEIPTS",
          style = MaterialTheme.typography.labelSmall,
          fontWeight = FontWeight.Bold,
          color = TextSecondaryMuted,
          letterSpacing = 0.5.sp
        )
        Text(
          text = "All Receipts →",
          style = MaterialTheme.typography.labelMedium,
          color = DeepTealPrimary,
          fontWeight = FontWeight.Bold,
          modifier = Modifier.clickable { onNavigateToPayments() }
        )
      }
    }

    val recentPayments = payments.take(4)
    if (recentPayments.isEmpty()) {
      item {
        Card(
          modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
          colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
          shape = RoundedCornerShape(14.dp),
          border = BorderStroke(1.dp, BorderWarmGray)
        ) {
          Text(
            text = "No payments recorded yet. Collect a fee to begin the transaction ledger.",
            modifier = Modifier.padding(16.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = TextSecondaryMuted
          )
        }
      }
    } else {
      items(recentPayments) { payment ->
        Card(
          modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .clickable { viewModel.selectReceiptPayment(payment) },
          colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
          shape = RoundedCornerShape(14.dp),
          border = BorderStroke(1.dp, BorderWarmGray),
          elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
        ) {
          Row(
            modifier = Modifier
              .fillMaxWidth()
              .padding(14.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
          ) {
            Column {
              Text(
                text = payment.studentName,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp,
                color = TextInkPrimary
              )
              Text(
                text = "${payment.receiptNumber} • ${payment.paymentMethod.label} • ${DateUtils.formatDisplayDate(payment.paymentDate)}",
                fontSize = 12.sp,
                color = TextSecondaryMuted
              )
            }
            Column(horizontalAlignment = Alignment.End) {
              Text(
                text = FormatUtils.formatCurrency(payment.amount, profile.currencySymbol),
                fontWeight = FontWeight.Bold,
                color = StatusPaid,
                fontSize = 15.sp
              )
              PaymentStatusBadge(status = payment.status)
            }
          }
        }
      }
    }
  }

  // Quick 1-Tap Payment Dialog
  if (studentForQuickPayment != null) {
    RecordPaymentDialog(
      student = studentForQuickPayment!!,
      currencySymbol = profile.currencySymbol,
      onDismiss = { studentForQuickPayment = null },
      onConfirmPayment = { amount, method, date, reference, notes ->
        viewModel.recordStudentPayment(
          studentId = studentForQuickPayment!!.id,
          amount = amount,
          paymentMethod = method,
          paymentDate = date,
          transactionReference = reference,
          notes = notes
        )
        studentForQuickPayment = null
      }
    )
  }
}

@Composable
private fun EnrollmentStat(label: String, count: Int, color: Color) {
  Column(horizontalAlignment = Alignment.CenterHorizontally) {
    Text(
      text = count.toString(),
      fontWeight = FontWeight.Bold,
      fontSize = 17.sp,
      color = color
    )
    Text(
      text = label,
      fontSize = 11.sp,
      color = TextSecondaryMuted,
      fontWeight = FontWeight.Normal
    )
  }
}

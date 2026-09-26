package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
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
import com.example.data.model.PaymentMethod
import com.example.data.model.PaymentRecordStatus
import com.example.ui.components.PaymentStatusBadge
import com.example.ui.theme.*
import com.example.ui.viewmodel.TuitionViewModel
import com.example.util.DateUtils
import com.example.util.FormatUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaymentHistoryScreen(
  viewModel: TuitionViewModel,
  onNavigateToStudentDetail: (String) -> Unit
) {
  val payments by viewModel.payments.collectAsState()
  val profile by viewModel.tuitionProfile.collectAsState()

  var searchQuery by remember { mutableStateOf("") }
  var dateFilter by remember { mutableStateOf("ALL") } // "TODAY", "THIS_WEEK", "THIS_MONTH", "ALL"
  var methodFilter by remember { mutableStateOf<PaymentMethod?>(null) }

  val filteredPayments = remember(payments, searchQuery, dateFilter, methodFilter) {
    payments.filter { p ->
      val matchesSearch = searchQuery.isBlank() ||
          p.studentName.contains(searchQuery, ignoreCase = true) ||
          p.receiptNumber.contains(searchQuery, ignoreCase = true) ||
          p.transactionReference.contains(searchQuery, ignoreCase = true)

      val matchesDate = when (dateFilter) {
        "TODAY" -> DateUtils.isToday(p.paymentDate)
        "THIS_WEEK" -> DateUtils.isThisWeek(p.paymentDate)
        "THIS_MONTH" -> DateUtils.isThisMonth(p.paymentDate)
        else -> true
      }

      val matchesMethod = methodFilter == null || p.paymentMethod == methodFilter

      matchesSearch && matchesDate && matchesMethod
    }
  }

  val totalCollectedInView = remember(filteredPayments) {
    filteredPayments.filter { it.status == PaymentRecordStatus.COMPLETED }.sumOf { it.amount }
  }

  Scaffold(
    topBar = {
      TopAppBar(
        title = {
          Column {
            Text("Payment History", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = TextInkPrimary)
            Text(
              "${filteredPayments.size} receipts • Total: ${FormatUtils.formatCurrency(totalCollectedInView, profile.currencySymbol)}",
              style = MaterialTheme.typography.bodySmall,
              color = TextSecondaryMuted
            )
          }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = CardSurfaceWhite)
      )
    }
  ) { innerPadding ->
    Column(
      modifier = Modifier
        .fillMaxSize()
        .padding(innerPadding)
        .background(WarmIvoryBackground)
    ) {
      // Search Box
      OutlinedTextField(
        value = searchQuery,
        onValueChange = { searchQuery = it },
        placeholder = { Text("Search by receipt #, student name, UTR...") },
        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = TextSecondaryMuted) },
        trailingIcon = {
          if (searchQuery.isNotBlank()) {
            IconButton(onClick = { searchQuery = "" }) {
              Icon(Icons.Default.Close, contentDescription = "Clear", tint = TextSecondaryMuted)
            }
          }
        },
        singleLine = true,
        shape = RoundedCornerShape(14.dp),
        modifier = Modifier
          .fillMaxWidth()
          .padding(horizontal = 16.dp, vertical = 6.dp),
        colors = OutlinedTextFieldDefaults.colors(
          unfocusedContainerColor = CardSurfaceWhite,
          focusedContainerColor = CardSurfaceWhite,
          unfocusedBorderColor = BorderWarmGray,
          focusedBorderColor = DeepTealPrimary
        )
      )

      // Date Range Filter Chips
      LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(vertical = 4.dp)
      ) {
        item {
          FilterChip(
            selected = dateFilter == "ALL",
            onClick = { dateFilter = "ALL" },
            label = { Text("All Time", fontSize = 12.sp) },
            shape = RoundedCornerShape(50)
          )
        }
        item {
          FilterChip(
            selected = dateFilter == "TODAY",
            onClick = { dateFilter = "TODAY" },
            label = { Text("Today", fontSize = 12.sp) },
            shape = RoundedCornerShape(50)
          )
        }
        item {
          FilterChip(
            selected = dateFilter == "THIS_WEEK",
            onClick = { dateFilter = "THIS_WEEK" },
            label = { Text("This Week", fontSize = 12.sp) },
            shape = RoundedCornerShape(50)
          )
        }
        item {
          FilterChip(
            selected = dateFilter == "THIS_MONTH",
            onClick = { dateFilter = "THIS_MONTH" },
            label = { Text("This Month", fontSize = 12.sp) },
            shape = RoundedCornerShape(50)
          )
        }
      }

      // Method Filter Chips
      LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(bottom = 6.dp)
      ) {
        item {
          FilterChip(
            selected = methodFilter == null,
            onClick = { methodFilter = null },
            label = { Text("All Modes", fontSize = 12.sp) },
            shape = RoundedCornerShape(50)
          )
        }
        items(PaymentMethod.values()) { m ->
          FilterChip(
            selected = methodFilter == m,
            onClick = { methodFilter = if (methodFilter == m) null else m },
            label = { Text(m.label, fontSize = 12.sp) },
            shape = RoundedCornerShape(50)
          )
        }
      }

      // List
      if (filteredPayments.isEmpty()) {
        Box(
          modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
          contentAlignment = Alignment.Center
        ) {
          Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
              modifier = Modifier
                .size(64.dp)
                .clip(CircleShape)
                .background(SurfaceMuted),
              contentAlignment = Alignment.Center
            ) {
              Icon(
                Icons.Default.Receipt,
                contentDescription = null,
                modifier = Modifier.size(32.dp),
                tint = TextSecondaryMuted
              )
            }
            Spacer(modifier = Modifier.height(14.dp))
            Text("No payments found", fontWeight = FontWeight.Bold, fontSize = 16.sp, color = TextInkPrimary)
            Text("Recorded payment receipts will appear here.", color = TextSecondaryMuted, fontSize = 13.sp)
          }
        }
      } else {
        LazyColumn(
          modifier = Modifier.fillMaxSize(),
          contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 100.dp),
          verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
          items(filteredPayments, key = { it.id }) { payment ->
            Card(
              modifier = Modifier
                .fillMaxWidth()
                .clickable { viewModel.selectReceiptPayment(payment) },
              shape = RoundedCornerShape(18.dp),
              colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
              border = BorderStroke(1.dp, BorderWarmGray),
              elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
              Column(modifier = Modifier.padding(16.dp)) {
                Row(
                  modifier = Modifier.fillMaxWidth(),
                  horizontalArrangement = Arrangement.SpaceBetween,
                  verticalAlignment = Alignment.CenterVertically
                ) {
                  Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.weight(1f)
                  ) {
                    Box(
                      modifier = Modifier
                        .size(38.dp)
                        .clip(CircleShape)
                        .background(StatusPaidContainer),
                      contentAlignment = Alignment.Center
                    ) {
                      Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = StatusPaid,
                        modifier = Modifier.size(20.dp)
                      )
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                      Text(
                        text = payment.studentName,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = TextInkPrimary
                      )
                      Text(
                        text = "${payment.receiptNumber} • ${payment.paymentMethod.label}",
                        fontSize = 12.sp,
                        color = TextSecondaryMuted
                      )
                    }
                  }

                  Column(horizontalAlignment = Alignment.End) {
                    Text(
                      text = FormatUtils.formatCurrency(payment.amount, profile.currencySymbol),
                      fontWeight = FontWeight.Bold,
                      fontSize = 16.sp,
                      color = StatusPaid
                    )
                    PaymentStatusBadge(status = payment.status)
                  }
                }

                Spacer(modifier = Modifier.height(10.dp))
                HorizontalDivider(color = BorderWarmGray.copy(alpha = 0.6f))
                Spacer(modifier = Modifier.height(10.dp))

                Row(
                  modifier = Modifier.fillMaxWidth(),
                  horizontalArrangement = Arrangement.SpaceBetween,
                  verticalAlignment = Alignment.CenterVertically
                ) {
                  Column {
                    Text(
                      text = "Date: ${DateUtils.formatDisplayDate(payment.paymentDate)}",
                      fontSize = 12.sp,
                      color = TextSecondaryMuted
                    )
                    if (payment.transactionReference.isNotBlank()) {
                      Text(
                        text = "Ref: ${payment.transactionReference}",
                        fontSize = 11.sp,
                        color = DeepTealPrimary,
                        fontWeight = FontWeight.Medium
                      )
                    }
                  }

                  Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(
                      onClick = { onNavigateToStudentDetail(payment.studentId) },
                      shape = RoundedCornerShape(10.dp),
                      colors = ButtonDefaults.outlinedButtonColors(contentColor = TextInkPrimary),
                      border = BorderStroke(1.dp, BorderWarmGray),
                      contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                      Text("Student", fontSize = 12.sp)
                    }

                    Button(
                      onClick = { viewModel.selectReceiptPayment(payment) },
                      shape = RoundedCornerShape(10.dp),
                      colors = ButtonDefaults.buttonColors(containerColor = DeepTealPrimary),
                      contentPadding = PaddingValues(horizontal = 14.dp, vertical = 6.dp)
                    ) {
                      Icon(Icons.Default.Receipt, contentDescription = null, modifier = Modifier.size(14.dp))
                      Spacer(modifier = Modifier.width(4.dp))
                      Text("Receipt", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

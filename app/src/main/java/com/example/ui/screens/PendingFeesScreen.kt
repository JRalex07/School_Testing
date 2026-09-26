package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
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
import com.example.ui.components.FeeStatusBadge
import com.example.ui.theme.*
import com.example.ui.viewmodel.TuitionViewModel
import com.example.util.DateUtils
import com.example.util.FormatUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PendingFeesScreen(
  viewModel: TuitionViewModel,
  onNavigateToCollectFee: (String) -> Unit,
  onNavigateToStudentDetail: (String) -> Unit
) {
  val feeRecords by viewModel.feeRecords.collectAsState()
  val students by viewModel.students.collectAsState()
  val profile by viewModel.tuitionProfile.collectAsState()

  var searchQuery by remember { mutableStateOf("") }
  var filterOnlyOverdue by remember { mutableStateOf(false) }
  var filterOnlyPartial by remember { mutableStateOf(false) }
  var sortByOldest by remember { mutableStateOf(true) }

  // Extract all pending fee records (remainingAmount > 0 and not waived)
  val allPending = remember(feeRecords) {
    feeRecords.filter { it.remainingAmount > 0 && it.status != FeeStatus.WAIVED }
  }

  val totalPendingAmount = remember(allPending) { allPending.sumOf { it.remainingAmount } }
  val overduePendingAmount = remember(allPending) {
    allPending.filter { it.status == FeeStatus.OVERDUE || DateUtils.isOverdue(it.dueDate) }.sumOf { it.remainingAmount }
  }

  val filteredRecords = remember(allPending, searchQuery, filterOnlyOverdue, filterOnlyPartial, sortByOldest) {
    var list = allPending.filter { rec ->
      val matchesSearch = searchQuery.isBlank() ||
          rec.studentName.contains(searchQuery, ignoreCase = true) ||
          rec.feePeriod.contains(searchQuery)

      val matchesOverdue = !filterOnlyOverdue || (rec.status == FeeStatus.OVERDUE || DateUtils.isOverdue(rec.dueDate))
      val matchesPartial = !filterOnlyPartial || rec.status == FeeStatus.PARTIALLY_PAID

      matchesSearch && matchesOverdue && matchesPartial
    }

    list = if (sortByOldest) {
      list.sortedBy { it.feePeriod }
    } else {
      list.sortedByDescending { it.remainingAmount }
    }
    list
  }

  Scaffold(
    topBar = {
      TopAppBar(
        title = {
          Column {
            Text("Pending & Overdue Fees", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = TextInkPrimary)
            Text(
              "${filteredRecords.size} outstanding entries",
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
      // Summary Card
      Card(
        modifier = Modifier
          .fillMaxWidth()
          .padding(horizontal = 16.dp, vertical = 8.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        shape = RoundedCornerShape(18.dp),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Row(
          modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
          horizontalArrangement = Arrangement.SpaceBetween
        ) {
          Column {
            Text("Total Outstanding", fontSize = 11.sp, color = TextSecondaryMuted, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(2.dp))
            Text(
              text = FormatUtils.formatCurrency(totalPendingAmount, profile.currencySymbol),
              fontWeight = FontWeight.Bold,
              fontSize = 20.sp,
              color = StatusDue
            )
          }
          Column(horizontalAlignment = Alignment.End) {
            Text("Critical Overdue", fontSize = 11.sp, color = TextSecondaryMuted, fontWeight = FontWeight.SemiBold)
            Spacer(modifier = Modifier.height(2.dp))
            Text(
              text = FormatUtils.formatCurrency(overduePendingAmount, profile.currencySymbol),
              fontWeight = FontWeight.Bold,
              fontSize = 20.sp,
              color = StatusOverdue
            )
          }
        }
      }

      // Search field
      OutlinedTextField(
        value = searchQuery,
        onValueChange = { searchQuery = it },
        placeholder = { Text("Search by student name or period...") },
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
          .padding(horizontal = 16.dp, vertical = 4.dp),
        colors = OutlinedTextFieldDefaults.colors(
          unfocusedContainerColor = CardSurfaceWhite,
          focusedContainerColor = CardSurfaceWhite,
          unfocusedBorderColor = BorderWarmGray,
          focusedBorderColor = DeepTealPrimary
        )
      )

      // Filter Chips
      LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(vertical = 6.dp)
      ) {
        item {
          FilterChip(
            selected = filterOnlyOverdue,
            onClick = { filterOnlyOverdue = !filterOnlyOverdue },
            label = { Text("Only Overdue", fontSize = 12.sp) },
            shape = RoundedCornerShape(50),
            leadingIcon = if (filterOnlyOverdue) {
              { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp)) }
            } else null
          )
        }
        item {
          FilterChip(
            selected = filterOnlyPartial,
            onClick = { filterOnlyPartial = !filterOnlyPartial },
            label = { Text("Partially Paid", fontSize = 12.sp) },
            shape = RoundedCornerShape(50),
            leadingIcon = if (filterOnlyPartial) {
              { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp)) }
            } else null
          )
        }
        item {
          FilterChip(
            selected = !sortByOldest,
            onClick = { sortByOldest = !sortByOldest },
            label = { Text(if (sortByOldest) "Sort: Oldest First" else "Sort: Highest Due", fontSize = 12.sp) },
            shape = RoundedCornerShape(50)
          )
        }
      }

      // Pending List
      if (filteredRecords.isEmpty()) {
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
                .background(StatusPaidContainer),
              contentAlignment = Alignment.Center
            ) {
              Icon(
                Icons.Default.CheckCircle,
                contentDescription = null,
                tint = StatusPaid,
                modifier = Modifier.size(36.dp)
              )
            }
            Spacer(modifier = Modifier.height(14.dp))
            Text("All Caught Up!", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = TextInkPrimary)
            Text(
              "No pending tuition fees found matching your criteria.",
              color = TextSecondaryMuted,
              fontSize = 13.sp
            )
          }
        }
      } else {
        LazyColumn(
          modifier = Modifier.fillMaxSize(),
          contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 100.dp),
          verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
          items(filteredRecords, key = { it.id }) { rec ->
            val isOverdue = rec.status == FeeStatus.OVERDUE || DateUtils.isOverdue(rec.dueDate)
            val studentObj = students.find { it.id == rec.studentId }

            Card(
              modifier = Modifier.fillMaxWidth(),
              shape = RoundedCornerShape(18.dp),
              colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
              border = BorderStroke(1.dp, BorderWarmGray),
              elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
              Column(modifier = Modifier.padding(16.dp)) {
                Row(
                  modifier = Modifier.fillMaxWidth(),
                  horizontalArrangement = Arrangement.SpaceBetween,
                  verticalAlignment = Alignment.Top
                ) {
                  Column(modifier = Modifier.weight(1f)) {
                    Text(
                      text = rec.studentName,
                      fontWeight = FontWeight.Bold,
                      fontSize = 15.sp,
                      color = TextInkPrimary
                    )
                    Text(
                      text = "${DateUtils.formatDisplayPeriod(rec.feePeriod)} • Due: ${DateUtils.formatDisplayDate(rec.dueDate)}",
                      fontSize = 12.sp,
                      color = if (isOverdue) StatusOverdue else TextSecondaryMuted,
                      fontWeight = if (isOverdue) FontWeight.SemiBold else FontWeight.Normal
                    )
                    if (studentObj != null) {
                      Text(
                        text = "${studentObj.studentClass} • Contact: ${studentObj.parentContact.ifBlank { studentObj.phoneNumber }}",
                        fontSize = 11.sp,
                        color = TextSecondaryMuted
                      )
                    }
                  }

                  FeeStatusBadge(status = if (isOverdue && rec.status != FeeStatus.PARTIALLY_PAID) FeeStatus.OVERDUE else rec.status)
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
                      text = "Remaining: ${FormatUtils.formatCurrency(rec.remainingAmount, profile.currencySymbol)}",
                      fontWeight = FontWeight.Bold,
                      fontSize = 15.sp,
                      color = if (isOverdue) StatusOverdue else StatusDue
                    )
                    if (rec.paidAmount > 0) {
                      Text(
                        text = "Paid: ${FormatUtils.formatCurrency(rec.paidAmount, profile.currencySymbol)} of ${FormatUtils.formatCurrency(rec.netFee, profile.currencySymbol)}",
                        fontSize = 11.sp,
                        color = TextSecondaryMuted
                      )
                    }
                  }

                  Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(
                      onClick = { onNavigateToStudentDetail(rec.studentId) },
                      shape = RoundedCornerShape(10.dp),
                      colors = ButtonDefaults.outlinedButtonColors(contentColor = TextInkPrimary),
                      border = BorderStroke(1.dp, BorderWarmGray),
                      contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                      Text("Profile", fontSize = 12.sp)
                    }

                    Button(
                      onClick = { onNavigateToCollectFee(rec.studentId) },
                      shape = RoundedCornerShape(10.dp),
                      colors = ButtonDefaults.buttonColors(containerColor = DeepTealPrimary),
                      contentPadding = PaddingValues(horizontal = 14.dp, vertical = 6.dp)
                    ) {
                      Icon(Icons.Default.Payment, contentDescription = null, modifier = Modifier.size(15.dp))
                      Spacer(modifier = Modifier.width(4.dp))
                      Text("Collect Fee", fontSize = 12.sp, fontWeight = FontWeight.Bold)
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

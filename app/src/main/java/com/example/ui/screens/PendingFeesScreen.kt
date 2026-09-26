package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
            Text("Pending & Overdue Fees", fontWeight = FontWeight.Bold)
            Text(
              "${filteredRecords.size} outstanding entries",
              style = MaterialTheme.typography.bodySmall,
              color = MaterialTheme.colorScheme.onSurfaceVariant
            )
          }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
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
          .padding(16.dp, 8.dp, 16.dp, 8.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        shape = RoundedCornerShape(14.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.5.dp)
      ) {
        Row(
          modifier = Modifier
            .fillMaxWidth()
            .padding(14.dp),
          horizontalArrangement = Arrangement.SpaceBetween
        ) {
          Column {
            Text("Total Outstanding", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(
              text = FormatUtils.formatCurrency(totalPendingAmount, profile.currencySymbol),
              fontWeight = FontWeight.Bold,
              fontSize = 18.sp,
              color = StatusDue
            )
          }
          Column(horizontalAlignment = Alignment.End) {
            Text("Critical Overdue", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(
              text = FormatUtils.formatCurrency(overduePendingAmount, profile.currencySymbol),
              fontWeight = FontWeight.Bold,
              fontSize = 18.sp,
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
        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
        trailingIcon = {
          if (searchQuery.isNotBlank()) {
            IconButton(onClick = { searchQuery = "" }) {
              Icon(Icons.Default.Close, contentDescription = "Clear")
            }
          }
        },
        singleLine = true,
        shape = RoundedCornerShape(10.dp),
        modifier = Modifier
          .fillMaxWidth()
          .padding(horizontal = 16.dp, vertical = 4.dp),
        colors = OutlinedTextFieldDefaults.colors(
          unfocusedContainerColor = MaterialTheme.colorScheme.surface,
          focusedContainerColor = MaterialTheme.colorScheme.surface
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
            label = { Text("Only Overdue") },
            leadingIcon = if (filterOnlyOverdue) {
              { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp)) }
            } else null
          )
        }
        item {
          FilterChip(
            selected = filterOnlyPartial,
            onClick = { filterOnlyPartial = !filterOnlyPartial },
            label = { Text("Partially Paid") },
            leadingIcon = if (filterOnlyPartial) {
              { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp)) }
            } else null
          )
        }
        item {
          FilterChip(
            selected = !sortByOldest,
            onClick = { sortByOldest = !sortByOldest },
            label = { Text(if (sortByOldest) "Sort: Oldest First" else "Sort: Highest Due") }
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
            Icon(
              Icons.Default.CheckCircleOutline,
              contentDescription = null,
              tint = StatusPaid,
              modifier = Modifier.size(60.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text("All Caught Up!", fontWeight = FontWeight.Bold, fontSize = 18.sp)
            Text(
              "No pending tuition fees found matching your criteria.",
              color = MaterialTheme.colorScheme.onSurfaceVariant,
              fontSize = 13.sp
            )
          }
        }
      } else {
        LazyColumn(
          modifier = Modifier.fillMaxSize(),
          contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 80.dp),
          verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
          items(filteredRecords, key = { it.id }) { rec ->
            val isOverdue = rec.status == FeeStatus.OVERDUE || DateUtils.isOverdue(rec.dueDate)
            val studentObj = students.find { it.id == rec.studentId }

            Card(
              modifier = Modifier.fillMaxWidth(),
              shape = RoundedCornerShape(14.dp),
              colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
              border = androidx.compose.foundation.BorderStroke(1.dp, BorderWarmGray),
              elevation = CardDefaults.cardElevation(defaultElevation = 0.5.dp)
            ) {
              Column(modifier = Modifier.padding(14.dp)) {
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
                      color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                      text = "${DateUtils.formatDisplayPeriod(rec.feePeriod)} • Due: ${DateUtils.formatDisplayDate(rec.dueDate)}",
                      fontSize = 12.sp,
                      color = if (isOverdue) StatusOverdue else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    if (studentObj != null) {
                      Text(
                        text = "${studentObj.studentClass} • Parent: ${studentObj.parentPhone}",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                      )
                    }
                  }

                  FeeStatusBadge(status = if (isOverdue && rec.status != FeeStatus.PARTIALLY_PAID) FeeStatus.OVERDUE else rec.status)
                }

                Spacer(modifier = Modifier.height(10.dp))
                HorizontalDivider()
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
                        text = "Already Paid: ${FormatUtils.formatCurrency(rec.paidAmount, profile.currencySymbol)} of ${FormatUtils.formatCurrency(rec.netFee, profile.currencySymbol)}",
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                      )
                    }
                  }

                  Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    OutlinedButton(
                      onClick = { onNavigateToStudentDetail(rec.studentId) },
                      shape = RoundedCornerShape(8.dp),
                      contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                      Text("Profile", fontSize = 11.sp)
                    }

                    Button(
                      onClick = { onNavigateToCollectFee(rec.studentId) },
                      shape = RoundedCornerShape(8.dp),
                      colors = ButtonDefaults.buttonColors(containerColor = BrandBluePrimary),
                      contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                    ) {
                      Icon(Icons.Default.Payment, contentDescription = null, modifier = Modifier.size(14.dp))
                      Spacer(modifier = Modifier.width(4.dp))
                      Text("Collect Fee", fontSize = 11.sp, fontWeight = FontWeight.Bold)
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

package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.TuitionProfile
import com.example.ui.components.ConfirmDialog
import com.example.ui.theme.StatusPaid
import com.example.ui.viewmodel.TuitionViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
  viewModel: TuitionViewModel
) {
  val profile by viewModel.tuitionProfile.collectAsState()
  val isFirestoreConnected by viewModel.isFirestoreConnected.collectAsState()

  var tuitionName by remember(profile) { mutableStateOf(profile.tuitionName) }
  var teacherName by remember(profile) { mutableStateOf(profile.teacherName) }
  var phone by remember(profile) { mutableStateOf(profile.phone) }
  var address by remember(profile) { mutableStateOf(profile.address) }
  var upiId by remember(profile) { mutableStateOf(profile.upiId) }
  var defaultMonthlyFeeStr by remember(profile) { mutableStateOf(profile.defaultMonthlyFee.toInt().toString()) }
  var defaultDueDayStr by remember(profile) { mutableStateOf(profile.defaultDueDay.toString()) }
  var currencySymbol by remember(profile) { mutableStateOf(profile.currencySymbol) }
  var receiptFooter by remember(profile) { mutableStateOf(profile.receiptFooterNote) }

  var showResetDialog by remember { mutableStateOf(false) }
  var showClearDialog by remember { mutableStateOf(false) }

  val scrollState = rememberScrollState()

  Scaffold(
    topBar = {
      TopAppBar(
        title = { Text("Tuition Profile & Settings", fontWeight = FontWeight.Bold) },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
      )
    }
  ) { innerPadding ->
    Column(
      modifier = Modifier
        .fillMaxSize()
        .padding(innerPadding)
        .background(MaterialTheme.colorScheme.background)
        .verticalScroll(scrollState)
        .padding(16.dp),
      verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
      // Database & Sync Status
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Row(
          modifier = Modifier
            .fillMaxWidth()
            .padding(14.dp),
          verticalAlignment = Alignment.CenterVertically,
          horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
          Icon(
            Icons.Default.CloudDone,
            contentDescription = null,
            tint = StatusPaid,
            modifier = Modifier.size(28.dp)
          )
          Column {
            Text(
              text = "Firebase Firestore Database",
              fontWeight = FontWeight.Bold,
              fontSize = 14.sp
            )
            Text(
              text = if (isFirestoreConnected) "Connected with Local Persistent Cache" else "Offline Local Cache Operational",
              fontSize = 12.sp,
              color = MaterialTheme.colorScheme.onSurfaceVariant
            )
          }
        }
      }

      // Tuition Academy Profile
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("Tuition & Teacher Identity", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = MaterialTheme.colorScheme.primary)

          OutlinedTextField(
            value = tuitionName,
            onValueChange = { tuitionName = it },
            label = { Text("Tuition / Coaching Name *") },
            leadingIcon = { Icon(Icons.Default.School, contentDescription = null) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
          )

          OutlinedTextField(
            value = teacherName,
            onValueChange = { teacherName = it },
            label = { Text("Teacher / Tutor Name *") },
            leadingIcon = { Icon(Icons.Default.Person, contentDescription = null) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
          )

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = phone,
              onValueChange = { phone = it },
              label = { Text("Contact Phone") },
              leadingIcon = { Icon(Icons.Default.Phone, contentDescription = null) },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )

            OutlinedTextField(
              value = upiId,
              onValueChange = { upiId = it },
              label = { Text("UPI ID") },
              leadingIcon = { Icon(Icons.Default.QrCode, contentDescription = null) },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
          }

          OutlinedTextField(
            value = address,
            onValueChange = { address = it },
            label = { Text("Tuition Center Address") },
            leadingIcon = { Icon(Icons.Default.Place, contentDescription = null) },
            modifier = Modifier.fillMaxWidth()
          )
        }
      }

      // Fee & Receipt Defaults
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("Fee & Receipt Settings", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = MaterialTheme.colorScheme.primary)

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = defaultMonthlyFeeStr,
              onValueChange = { defaultMonthlyFeeStr = it },
              label = { Text("Default Monthly Fee") },
              leadingIcon = { Icon(Icons.Default.AttachMoney, contentDescription = null) },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )

            OutlinedTextField(
              value = defaultDueDayStr,
              onValueChange = { defaultDueDayStr = it },
              label = { Text("Default Due Day") },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
          }

          OutlinedTextField(
            value = receiptFooter,
            onValueChange = { receiptFooter = it },
            label = { Text("Receipt Footer Note") },
            minLines = 2,
            modifier = Modifier.fillMaxWidth()
          )
        }
      }

      // Save Profile Button
      Button(
        onClick = {
          val fee = defaultMonthlyFeeStr.toDoubleOrNull() ?: 1500.0
          val dueDay = defaultDueDayStr.toIntOrNull()?.coerceIn(1, 31) ?: 10
          val newProfile = TuitionProfile(
            tuitionName = tuitionName.trim(),
            teacherName = teacherName.trim(),
            phone = phone.trim(),
            address = address.trim(),
            upiId = upiId.trim(),
            defaultMonthlyFee = fee,
            defaultDueDay = dueDay,
            currencySymbol = currencySymbol.trim(),
            receiptFooterNote = receiptFooter.trim()
          )
          viewModel.updateTuitionProfile(newProfile)
        },
        modifier = Modifier
          .fillMaxWidth()
          .height(48.dp),
        shape = RoundedCornerShape(10.dp)
      ) {
        Icon(Icons.Default.Save, contentDescription = null)
        Spacer(modifier = Modifier.width(8.dp))
        Text("Save Settings & Profile", fontWeight = FontWeight.Bold)
      }

      // Data Management Tools
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
          Text("Data & Ledger Controls", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = MaterialTheme.colorScheme.primary)
          Text(
            "Use these controls to reset demo students or clear local transaction records.",
            fontSize = 12.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant
          )

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(
              onClick = { showResetDialog = true },
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(8.dp)
            ) {
              Text("Reload Demo Data", fontSize = 12.sp)
            }

            Button(
              onClick = { showClearDialog = true },
              modifier = Modifier.weight(1f),
              colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
              shape = RoundedCornerShape(8.dp)
            ) {
              Text("Clear All Data", fontSize = 12.sp)
            }
          }
        }
      }
    }
  }

  if (showResetDialog) {
    ConfirmDialog(
      title = "Reload Sample Data?",
      message = "This will restore the realistic demonstration students and fee records. Current changes will be overwritten.",
      confirmButtonText = "Reload Sample",
      onConfirm = { viewModel.resetToSampleData() },
      onDismiss = { showResetDialog = false }
    )
  }

  if (showClearDialog) {
    ConfirmDialog(
      title = "Clear All Ledger Records?",
      message = "This will wipe all students, fee records, and payment receipts from your device. This cannot be undone.",
      confirmButtonText = "Clear Everything",
      isDestructive = true,
      onConfirm = { viewModel.clearAllData() },
      onDismiss = { showClearDialog = false }
    )
  }
}

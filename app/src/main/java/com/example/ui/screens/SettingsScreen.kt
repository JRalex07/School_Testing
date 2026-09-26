package com.example.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
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
import com.example.ui.theme.*
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
  var currencySymbol by remember(profile) { mutableStateOf(if (profile.currencySymbol.isBlank() || profile.currencySymbol == "$") "₹" else profile.currencySymbol) }
  var receiptFooter by remember(profile) { mutableStateOf(profile.receiptFooterNote) }

  var showClearDialog by remember { mutableStateOf(false) }
  var savedSuccess by remember { mutableStateOf(false) }

  val scrollState = rememberScrollState()

  Scaffold(
    topBar = {
      TopAppBar(
        title = {
          Text(
            "Tuition Profile & Settings",
            fontWeight = FontWeight.Bold,
            fontSize = 18.sp,
            color = TextInkPrimary
          )
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = CardSurfaceWhite)
      )
    },
    bottomBar = {
      Surface(
        color = CardSurfaceWhite,
        shadowElevation = 8.dp,
        border = BorderStroke(1.dp, BorderWarmGray),
        modifier = Modifier
          .fillMaxWidth()
          .navigationBarsPadding()
          .imePadding()
      ) {
        Box(
          modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
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
                currencySymbol = currencySymbol.ifBlank { "₹" }.trim(),
                receiptFooterNote = receiptFooter.trim()
              )
              viewModel.updateTuitionProfile(newProfile)
              savedSuccess = true
            },
            modifier = Modifier
              .fillMaxWidth()
              .height(52.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DeepTealPrimary),
            shape = RoundedCornerShape(14.dp)
          ) {
            Icon(Icons.Default.Save, contentDescription = null, modifier = Modifier.size(20.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text("Save Profile & Settings", fontWeight = FontWeight.Bold, fontSize = 15.sp)
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
      if (savedSuccess) {
        Card(
          colors = CardDefaults.cardColors(containerColor = StatusPaidContainer),
          shape = RoundedCornerShape(12.dp),
          border = BorderStroke(1.dp, StatusPaid.copy(alpha = 0.3f))
        ) {
          Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
          ) {
            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = StatusPaid, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text(
              text = "Profile and INR currency settings updated successfully!",
              color = StatusOnPaidContainer,
              style = MaterialTheme.typography.bodySmall,
              fontWeight = FontWeight.Medium
            )
          }
        }
      }

      // Database & Sync Status
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Row(
          modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
          verticalAlignment = Alignment.CenterVertically,
          horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
          Box(
            modifier = Modifier
              .size(40.dp)
              .background(StatusPaidContainer, RoundedCornerShape(12.dp)),
            contentAlignment = Alignment.Center
          ) {
            Icon(
              Icons.Default.CloudDone,
              contentDescription = null,
              tint = StatusPaid,
              modifier = Modifier.size(22.dp)
            )
          }
          Column {
            Text(
              text = "Firebase Firestore Database",
              fontWeight = FontWeight.Bold,
              fontSize = 14.sp,
              color = TextInkPrimary
            )
            Text(
              text = if (isFirestoreConnected) "Connected with Real-time Cloud Sync" else "Offline Cache Active",
              fontSize = 12.sp,
              color = TextSecondaryMuted
            )
          }
        }
      }

      // Tuition Academy Profile
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("Tuition & Teacher Identity", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = DeepTealPrimary)

          OutlinedTextField(
            value = tuitionName,
            onValueChange = { tuitionName = it },
            label = { Text("Tuition / Academy Name *") },
            leadingIcon = { Icon(Icons.Default.School, contentDescription = null, tint = DeepTealPrimary) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )

          OutlinedTextField(
            value = teacherName,
            onValueChange = { teacherName = it },
            label = { Text("Teacher / Tutor Name *") },
            leadingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = DeepTealPrimary) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = phone,
              onValueChange = { phone = it },
              label = { Text("Contact Phone") },
              leadingIcon = { Icon(Icons.Default.Phone, contentDescription = null, tint = TextSecondaryMuted) },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
              value = upiId,
              onValueChange = { upiId = it },
              label = { Text("UPI ID") },
              leadingIcon = { Icon(Icons.Default.QrCode, contentDescription = null, tint = TextSecondaryMuted) },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )
          }

          OutlinedTextField(
            value = address,
            onValueChange = { address = it },
            label = { Text("Tuition Center Address") },
            leadingIcon = { Icon(Icons.Default.Place, contentDescription = null, tint = TextSecondaryMuted) },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )
        }
      }

      // Fee & Currency Defaults (INR ₹)
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("Fee & Currency Settings (INR ₹)", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = DeepTealPrimary)

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = defaultMonthlyFeeStr,
              onValueChange = { defaultMonthlyFeeStr = it },
              label = { Text("Default Monthly Fee (₹)") },
              leadingIcon = { Icon(Icons.Default.CurrencyRupee, contentDescription = null, tint = DeepTealPrimary) },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
              value = defaultDueDayStr,
              onValueChange = { defaultDueDayStr = it },
              label = { Text("Default Due Day") },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )
          }

          // Currency selection
          OutlinedTextField(
            value = currencySymbol,
            onValueChange = { currencySymbol = it },
            label = { Text("Currency Symbol (Default: ₹ INR)") },
            leadingIcon = { Icon(Icons.Default.CurrencyRupee, contentDescription = null, tint = DeepTealPrimary) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )

          OutlinedTextField(
            value = receiptFooter,
            onValueChange = { receiptFooter = it },
            label = { Text("Receipt Footer Note") },
            minLines = 2,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )
        }
      }

      // Data Management Tools
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
          Text("Data & Ledger Controls", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = StatusOverdue)
          Text(
            "Use this control to wipe all local transaction and student records if you wish to reset your ledger.",
            fontSize = 12.sp,
            color = TextSecondaryMuted
          )

          Button(
            onClick = { showClearDialog = true },
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = StatusOverdue),
            shape = RoundedCornerShape(12.dp)
          ) {
            Text("Clear All Local Data", fontSize = 13.sp, fontWeight = FontWeight.Bold)
          }
        }
      }

      Spacer(modifier = Modifier.height(24.dp))
    }
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

package com.example.ui.screens

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.ContactsContract
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.example.data.model.DiscountType
import com.example.data.model.FeeCycle
import com.example.data.model.Student
import com.example.data.model.StudentStatus
import com.example.ui.theme.*
import com.example.ui.viewmodel.TuitionViewModel
import com.example.util.DateUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditStudentScreen(
  viewModel: TuitionViewModel,
  studentId: String?,
  onNavigateBack: () -> Unit
) {
  val context = LocalContext.current
  val students by viewModel.students.collectAsState()
  val existingStudent = remember(studentId, students) {
    if (studentId != null) students.find { it.id == studentId } else null
  }

  val isEditing = existingStudent != null

  var fullName by remember { mutableStateOf(existingStudent?.fullName ?: "") }
  var fatherName by remember { mutableStateOf(existingStudent?.fatherName ?: "") }
  var motherName by remember { mutableStateOf(existingStudent?.motherName ?: "") }
  // Single contact option: parentPhone only
  var parentPhone by remember { mutableStateOf(existingStudent?.parentContact ?: "") }
  var address by remember { mutableStateOf(existingStudent?.address ?: "") }
  var joiningDate by remember { mutableStateOf(existingStudent?.joiningDate ?: DateUtils.currentDateString()) }
  var studentStatus by remember { mutableStateOf(existingStudent?.status ?: StudentStatus.ACTIVE) }
  var notes by remember { mutableStateOf(existingStudent?.notes ?: "") }

  // Tuition info (INR ₹)
  var monthlyFeeStr by remember { mutableStateOf(existingStudent?.monthlyFee?.toInt()?.toString() ?: "1500") }
  var feeCycle by remember { mutableStateOf(existingStudent?.feeCycle ?: FeeCycle.MONTHLY) }
  var discountStr by remember { mutableStateOf(existingStudent?.discount?.toInt()?.toString() ?: "0") }
  var discountType by remember { mutableStateOf(existingStudent?.discountType ?: DiscountType.NONE) }
  var preferredPaymentDayStr by remember { mutableStateOf(existingStudent?.preferredPaymentDay?.toString() ?: "10") }
  var advanceBalanceStr by remember { mutableStateOf(existingStudent?.advanceBalance?.toInt()?.toString() ?: "0") }

  // Academic info
  var studentClass by remember { mutableStateOf(existingStudent?.studentClass ?: "Class 10") }
  var section by remember { mutableStateOf(existingStudent?.section ?: "") }
  var schoolName by remember { mutableStateOf(existingStudent?.schoolName ?: "") }
  var subjectsStr by remember { mutableStateOf(existingStudent?.subjects?.joinToString(", ") ?: "Mathematics, Science") }
  var batch by remember { mutableStateOf(existingStudent?.batch ?: "Evening Batch") }
  var tuitionTiming by remember { mutableStateOf(existingStudent?.tuitionTiming ?: "5:00 PM - 7:00 PM") }

  var errorMessage by remember { mutableStateOf<String?>(null) }
  var contactFeedbackMessage by remember { mutableStateOf<String?>(null) }
  val scrollState = rememberScrollState()

  // Native Device Contact Picker Launcher
  val contactPickerLauncher = rememberLauncherForActivityResult(
    contract = ActivityResultContracts.StartActivityForResult()
  ) { result ->
    if (result.resultCode == Activity.RESULT_OK) {
      val contactUri = result.data?.data
      if (contactUri != null) {
        val projection = arrayOf(
          ContactsContract.CommonDataKinds.Phone.NUMBER,
          ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME
        )
        try {
          context.contentResolver.query(contactUri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
              val numberIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
              val nameIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)

              if (numberIndex != -1) {
                val rawNumber = cursor.getString(numberIndex) ?: ""
                val cleanNumber = rawNumber.replace(" ", "").replace("-", "").replace("(", "").replace(")", "")
                parentPhone = cleanNumber
                contactFeedbackMessage = "Parent contact imported from phone book"
              }
              if (nameIndex != -1) {
                val contactName = cursor.getString(nameIndex) ?: ""
                if (fatherName.isBlank() && contactName.isNotBlank()) {
                  fatherName = contactName
                }
              }
            }
          }
        } catch (e: Exception) {
          contactFeedbackMessage = "Unable to read contact: ${e.localizedMessage}"
        }
      }
    }
  }

  // Permission Launcher for READ_CONTACTS
  val permissionLauncher = rememberLauncherForActivityResult(
    contract = ActivityResultContracts.RequestPermission()
  ) { isGranted ->
    val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
    contactPickerLauncher.launch(intent)
  }

  fun launchContactPicker() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED) {
        val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
        contactPickerLauncher.launch(intent)
      } else {
        permissionLauncher.launch(Manifest.permission.READ_CONTACTS)
      }
    } else {
      val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
      contactPickerLauncher.launch(intent)
    }
  }

  Scaffold(
    topBar = {
      TopAppBar(
        title = {
          Text(
            if (isEditing) "Edit Student Profile" else "Add New Student",
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
              if (fullName.isBlank()) {
                errorMessage = "Student full name is required."
                return@Button
              }
              val monthlyFee = monthlyFeeStr.toDoubleOrNull()
              if (monthlyFee == null || monthlyFee <= 0) {
                errorMessage = "Please enter a valid monthly fee in INR (₹)."
                return@Button
              }
              if (parentPhone.isBlank()) {
                errorMessage = "Parent contact number is required for fee tracking."
                return@Button
              }

              val discount = discountStr.toDoubleOrNull() ?: 0.0
              val preferredDay = preferredPaymentDayStr.toIntOrNull()?.coerceIn(1, 31) ?: 10
              val advanceBalance = advanceBalanceStr.toDoubleOrNull() ?: 0.0
              val subjectsList = subjectsStr.split(",").map { it.trim() }.filter { it.isNotBlank() }

              val studentToSave = (existingStudent ?: Student()).copy(
                name = fullName.trim(),
                parentContact = parentPhone.trim(),
                phoneNumber = parentPhone.trim(), // Single parent contact throughout
                monthlyFeeAmount = monthlyFee,
                fatherName = fatherName.trim(),
                motherName = motherName.trim(),
                address = address.trim(),
                joiningDate = joiningDate.trim(),
                status = studentStatus,
                notes = notes.trim(),
                feeCycle = feeCycle,
                discount = discount,
                discountType = discountType,
                preferredPaymentDay = preferredDay,
                advanceBalance = advanceBalance,
                studentClass = studentClass.trim(),
                section = section.trim(),
                schoolName = schoolName.trim(),
                subjects = subjectsList,
                batch = batch.trim(),
                tuitionTiming = tuitionTiming.trim()
              )

              viewModel.saveStudent(studentToSave) {
                onNavigateBack()
              }
            },
            modifier = Modifier
              .fillMaxWidth()
              .height(52.dp),
            colors = ButtonDefaults.buttonColors(containerColor = DeepTealPrimary),
            shape = RoundedCornerShape(14.dp)
          ) {
            Icon(Icons.Default.Save, contentDescription = null, modifier = Modifier.size(20.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text(if (isEditing) "Update Student" else "Save Student Record", fontWeight = FontWeight.Bold, fontSize = 15.sp)
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
      if (errorMessage != null) {
        Card(
          colors = CardDefaults.cardColors(containerColor = StatusOverdueContainer),
          shape = RoundedCornerShape(12.dp),
          border = BorderStroke(1.dp, StatusOverdue.copy(alpha = 0.3f))
        ) {
          Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.ErrorOutline, contentDescription = null, tint = StatusOverdue, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text(
              text = errorMessage ?: "",
              color = StatusOnOverdueContainer,
              style = MaterialTheme.typography.bodySmall,
              fontWeight = FontWeight.Medium
            )
          }
        }
      }

      if (contactFeedbackMessage != null) {
        Card(
          colors = CardDefaults.cardColors(containerColor = StatusPaidContainer),
          shape = RoundedCornerShape(12.dp),
          border = BorderStroke(1.dp, StatusPaid.copy(alpha = 0.3f))
        ) {
          Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = StatusPaid, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text(
              text = contactFeedbackMessage ?: "",
              color = StatusOnPaidContainer,
              style = MaterialTheme.typography.bodySmall,
              fontWeight = FontWeight.Medium
            )
          }
        }
      }

      // Section 1: Basic Information & Single Parent Contact
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("Basic Information", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = DeepTealPrimary)

          OutlinedTextField(
            value = fullName,
            onValueChange = { fullName = it },
            label = { Text("Student Full Name *") },
            leadingIcon = { Icon(Icons.Default.Person, contentDescription = null, tint = DeepTealPrimary) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )

          // Single Parent/Guardian Contact with Device Picker
          Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            OutlinedTextField(
              value = parentPhone,
              onValueChange = { parentPhone = it },
              label = { Text("Parent / Guardian Phone *") },
              placeholder = { Text("+91 9876543210") },
              leadingIcon = { Icon(Icons.Default.ContactPhone, contentDescription = null, tint = DeepTealPrimary) },
              trailingIcon = {
                IconButton(onClick = { launchContactPicker() }) {
                  Icon(
                    imageVector = Icons.Default.Contacts,
                    contentDescription = "Pick Contact from Phone",
                    tint = DeepTealPrimary
                  )
                }
              },
              singleLine = true,
              modifier = Modifier.fillMaxWidth(),
              shape = RoundedCornerShape(12.dp)
            )

            // Direct Contact Picker Assistant Button
            OutlinedButton(
              onClick = { launchContactPicker() },
              modifier = Modifier.fillMaxWidth(),
              shape = RoundedCornerShape(10.dp),
              border = BorderStroke(1.dp, DeepTealPrimary.copy(alpha = 0.5f)),
              colors = ButtonDefaults.outlinedButtonColors(contentColor = DeepTealPrimary),
              contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
            ) {
              Icon(Icons.Default.Contacts, contentDescription = null, modifier = Modifier.size(16.dp))
              Spacer(modifier = Modifier.width(6.dp))
              Text("Select Parent from Phone Contacts", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
            }
          }

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = fatherName,
              onValueChange = { fatherName = it },
              label = { Text("Father's Name") },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )
            OutlinedTextField(
              value = motherName,
              onValueChange = { motherName = it },
              label = { Text("Mother's Name") },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )
          }

          OutlinedTextField(
            value = address,
            onValueChange = { address = it },
            label = { Text("Residential Address") },
            leadingIcon = { Icon(Icons.Default.Home, contentDescription = null, tint = TextSecondaryMuted) },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )

          OutlinedTextField(
            value = joiningDate,
            onValueChange = { joiningDate = it },
            label = { Text("Joining Date (YYYY-MM-DD)") },
            leadingIcon = { Icon(Icons.Default.CalendarToday, contentDescription = null, tint = TextSecondaryMuted) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )
        }
      }

      // Section 2: Tuition Fee Structure in INR (₹)
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("Tuition & Fee Structure (INR ₹)", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = DeepTealPrimary)

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = monthlyFeeStr,
              onValueChange = { monthlyFeeStr = it },
              label = { Text("Monthly Fee (₹) *") },
              leadingIcon = { Icon(Icons.Default.CurrencyRupee, contentDescription = null, tint = DeepTealPrimary) },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
              value = preferredPaymentDayStr,
              onValueChange = { preferredPaymentDayStr = it },
              label = { Text("Due Day (1-31)") },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )
          }

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = discountStr,
              onValueChange = { discountStr = it },
              label = { Text("Discount (₹)") },
              leadingIcon = { Icon(Icons.Default.CurrencyRupee, contentDescription = null, tint = TextSecondaryMuted) },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )

            Column(modifier = Modifier.weight(1f)) {
              Text("Discount Type", style = MaterialTheme.typography.labelSmall, color = TextSecondaryMuted)
              Row {
                DiscountType.values().forEach { dt ->
                  FilterChip(
                    selected = discountType == dt,
                    onClick = { discountType = dt },
                    label = { Text(dt.label, fontSize = 11.sp) },
                    shape = RoundedCornerShape(50),
                    modifier = Modifier.padding(end = 4.dp)
                  )
                }
              }
            }
          }

          OutlinedTextField(
            value = advanceBalanceStr,
            onValueChange = { advanceBalanceStr = it },
            label = { Text("Initial Advance Prepaid Balance (₹)") },
            leadingIcon = { Icon(Icons.Default.CurrencyRupee, contentDescription = null, tint = StatusAdvance) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )
        }
      }

      // Section 3: Academic Details
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = CardSurfaceWhite),
        border = BorderStroke(1.dp, BorderWarmGray),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("Academic Information", fontWeight = FontWeight.Bold, fontSize = 15.sp, color = DeepTealPrimary)

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = studentClass,
              onValueChange = { studentClass = it },
              label = { Text("Class / Standard *") },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )
            OutlinedTextField(
              value = section,
              onValueChange = { section = it },
              label = { Text("Section") },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )
          }

          OutlinedTextField(
            value = schoolName,
            onValueChange = { schoolName = it },
            label = { Text("School Name (Optional)") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )

          OutlinedTextField(
            value = subjectsStr,
            onValueChange = { subjectsStr = it },
            label = { Text("Subjects (comma separated)") },
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = batch,
              onValueChange = { batch = it },
              label = { Text("Batch") },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )
            OutlinedTextField(
              value = tuitionTiming,
              onValueChange = { tuitionTiming = it },
              label = { Text("Tuition Timing") },
              singleLine = true,
              modifier = Modifier.weight(1f),
              shape = RoundedCornerShape(12.dp)
            )
          }

          OutlinedTextField(
            value = notes,
            onValueChange = { notes = it },
            label = { Text("Special Notes / Remarks") },
            minLines = 2,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp)
          )
        }
      }

      Spacer(modifier = Modifier.height(24.dp))
    }
  }
}

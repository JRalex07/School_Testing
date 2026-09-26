package com.example.ui.screens

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
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.DiscountType
import com.example.data.model.FeeCycle
import com.example.data.model.Student
import com.example.data.model.StudentStatus
import com.example.ui.viewmodel.TuitionViewModel
import com.example.util.DateUtils

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditStudentScreen(
  viewModel: TuitionViewModel,
  studentId: String?,
  onNavigateBack: () -> Unit
) {
  val students by viewModel.students.collectAsState()
  val existingStudent = remember(studentId, students) {
    if (studentId != null) students.find { it.id == studentId } else null
  }

  val isEditing = existingStudent != null

  var fullName by remember { mutableStateOf(existingStudent?.fullName ?: "") }
  var fatherName by remember { mutableStateOf(existingStudent?.fatherName ?: "") }
  var motherName by remember { mutableStateOf(existingStudent?.motherName ?: "") }
  var phoneNumber by remember { mutableStateOf(existingStudent?.phoneNumber ?: "") }
  var parentPhone by remember { mutableStateOf(existingStudent?.parentPhone ?: "") }
  var address by remember { mutableStateOf(existingStudent?.address ?: "") }
  var joiningDate by remember { mutableStateOf(existingStudent?.joiningDate ?: DateUtils.currentDateString()) }
  var studentStatus by remember { mutableStateOf(existingStudent?.status ?: StudentStatus.ACTIVE) }
  var notes by remember { mutableStateOf(existingStudent?.notes ?: "") }

  // Tuition info
  var monthlyFeeStr by remember { mutableStateOf(existingStudent?.monthlyFee?.toString() ?: "1500") }
  var feeCycle by remember { mutableStateOf(existingStudent?.feeCycle ?: FeeCycle.MONTHLY) }
  var discountStr by remember { mutableStateOf(existingStudent?.discount?.toString() ?: "0") }
  var discountType by remember { mutableStateOf(existingStudent?.discountType ?: DiscountType.NONE) }
  var preferredPaymentDayStr by remember { mutableStateOf(existingStudent?.preferredPaymentDay?.toString() ?: "10") }
  var advanceBalanceStr by remember { mutableStateOf(existingStudent?.advanceBalance?.toString() ?: "0") }

  // Academic info
  var studentClass by remember { mutableStateOf(existingStudent?.studentClass ?: "Class 10") }
  var section by remember { mutableStateOf(existingStudent?.section ?: "") }
  var schoolName by remember { mutableStateOf(existingStudent?.schoolName ?: "") }
  var subjectsStr by remember { mutableStateOf(existingStudent?.subjects?.joinToString(", ") ?: "Mathematics, Science") }
  var batch by remember { mutableStateOf(existingStudent?.batch ?: "Evening Batch (5 PM)") }
  var tuitionTiming by remember { mutableStateOf(existingStudent?.tuitionTiming ?: "5:00 PM - 6:30 PM") }

  var errorMessage by remember { mutableStateOf<String?>(null) }
  val scrollState = rememberScrollState()

  Scaffold(
    topBar = {
      TopAppBar(
        title = { Text(if (isEditing) "Edit Student Profile" else "Add New Student", fontWeight = FontWeight.Bold) },
        navigationIcon = {
          IconButton(onClick = onNavigateBack) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
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
        .background(MaterialTheme.colorScheme.background)
        .verticalScroll(scrollState)
        .padding(16.dp),
      verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
      if (errorMessage != null) {
        Card(
          colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
          shape = RoundedCornerShape(8.dp)
        ) {
          Text(
            text = errorMessage ?: "",
            color = MaterialTheme.colorScheme.onErrorContainer,
            modifier = Modifier.padding(12.dp),
            style = MaterialTheme.typography.bodySmall
          )
        }
      }

      // Section: Basic Information
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("Basic Information", fontWeight = FontWeight.Bold, fontSize = 16.sp, color = MaterialTheme.colorScheme.primary)

          OutlinedTextField(
            value = fullName,
            onValueChange = { fullName = it },
            label = { Text("Student Full Name *") },
            leadingIcon = { Icon(Icons.Default.Person, contentDescription = null) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
          )

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = fatherName,
              onValueChange = { fatherName = it },
              label = { Text("Father's Name") },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
            OutlinedTextField(
              value = motherName,
              onValueChange = { motherName = it },
              label = { Text("Mother's Name") },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
          }

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = phoneNumber,
              onValueChange = { phoneNumber = it },
              label = { Text("Student Phone") },
              leadingIcon = { Icon(Icons.Default.Phone, contentDescription = null) },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
            OutlinedTextField(
              value = parentPhone,
              onValueChange = { parentPhone = it },
              label = { Text("Parent/Guardian Phone *") },
              leadingIcon = { Icon(Icons.Default.ContactPhone, contentDescription = null) },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
          }

          OutlinedTextField(
            value = address,
            onValueChange = { address = it },
            label = { Text("Residential Address") },
            leadingIcon = { Icon(Icons.Default.Home, contentDescription = null) },
            modifier = Modifier.fillMaxWidth()
          )

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = joiningDate,
              onValueChange = { joiningDate = it },
              label = { Text("Joining Date (YYYY-MM-DD)") },
              leadingIcon = { Icon(Icons.Default.CalendarToday, contentDescription = null) },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
          }
        }
      }

      // Section: Tuition Fee Configuration
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("Tuition & Fee Structure", fontWeight = FontWeight.Bold, fontSize = 16.sp, color = MaterialTheme.colorScheme.primary)

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = monthlyFeeStr,
              onValueChange = { monthlyFeeStr = it },
              label = { Text("Monthly Fee (₹) *") },
              leadingIcon = { Icon(Icons.Default.AttachMoney, contentDescription = null) },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )

            OutlinedTextField(
              value = preferredPaymentDayStr,
              onValueChange = { preferredPaymentDayStr = it },
              label = { Text("Due Day (1-31)") },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
          }

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = discountStr,
              onValueChange = { discountStr = it },
              label = { Text("Discount Amount") },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )

            Column(modifier = Modifier.weight(1f)) {
              Text("Discount Type", style = MaterialTheme.typography.labelSmall)
              Row {
                DiscountType.values().forEach { dt ->
                  FilterChip(
                    selected = discountType == dt,
                    onClick = { discountType = dt },
                    label = { Text(dt.label, fontSize = 11.sp) },
                    modifier = Modifier.padding(end = 4.dp)
                  )
                }
              }
            }
          }

          OutlinedTextField(
            value = advanceBalanceStr,
            onValueChange = { advanceBalanceStr = it },
            label = { Text("Initial Advance Balance (₹)") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
          )
        }
      }

      // Section: Academic Details
      Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
      ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
          Text("Academic Information", fontWeight = FontWeight.Bold, fontSize = 16.sp, color = MaterialTheme.colorScheme.primary)

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = studentClass,
              onValueChange = { studentClass = it },
              label = { Text("Class / Standard *") },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
            OutlinedTextField(
              value = section,
              onValueChange = { section = it },
              label = { Text("Section") },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
          }

          OutlinedTextField(
            value = schoolName,
            onValueChange = { schoolName = it },
            label = { Text("School Name (Optional)") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth()
          )

          OutlinedTextField(
            value = subjectsStr,
            onValueChange = { subjectsStr = it },
            label = { Text("Subjects (comma separated)") },
            modifier = Modifier.fillMaxWidth()
          )

          Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
              value = batch,
              onValueChange = { batch = it },
              label = { Text("Batch") },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
            OutlinedTextField(
              value = tuitionTiming,
              onValueChange = { tuitionTiming = it },
              label = { Text("Tuition Timing") },
              singleLine = true,
              modifier = Modifier.weight(1f)
            )
          }

          OutlinedTextField(
            value = notes,
            onValueChange = { notes = it },
            label = { Text("Special Notes / Reminders") },
            minLines = 2,
            modifier = Modifier.fillMaxWidth()
          )
        }
      }

      // Submit Button
      Button(
        onClick = {
          if (fullName.isBlank()) {
            errorMessage = "Student full name is required."
            return@Button
          }
          val monthlyFee = monthlyFeeStr.toDoubleOrNull()
          if (monthlyFee == null || monthlyFee <= 0) {
            errorMessage = "Please enter a valid monthly fee."
            return@Button
          }
          val discount = discountStr.toDoubleOrNull() ?: 0.0
          val preferredDay = preferredPaymentDayStr.toIntOrNull()?.coerceIn(1, 31) ?: 10
          val advanceBalance = advanceBalanceStr.toDoubleOrNull() ?: 0.0
          val subjectsList = subjectsStr.split(",").map { it.trim() }.filter { it.isNotBlank() }

          val studentToSave = (existingStudent ?: Student()).copy(
            name = fullName.trim(),
            parentContact = parentPhone.trim(),
            monthlyFeeAmount = monthlyFee,
            fatherName = fatherName.trim(),
            motherName = motherName.trim(),
            phoneNumber = phoneNumber.trim(),
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
          .height(50.dp),
        shape = RoundedCornerShape(10.dp)
      ) {
        Icon(Icons.Default.Save, contentDescription = null)
        Spacer(modifier = Modifier.width(8.dp))
        Text(if (isEditing) "Update Student" else "Save Student Record", fontWeight = FontWeight.Bold)
      }
    }
  }
}

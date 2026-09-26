package com.example.ui.components

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.example.data.model.Payment
import com.example.data.model.TuitionProfile
import com.example.ui.theme.*
import com.example.util.DateUtils
import com.example.util.FormatUtils
import com.example.util.ReceiptPrinter

@Composable
fun ReceiptDialog(
  payment: Payment,
  profile: TuitionProfile,
  onDismiss: () -> Unit
) {
  val context = LocalContext.current
  val scrollState = rememberScrollState()

  Dialog(
    onDismissRequest = onDismiss,
    properties = DialogProperties(usePlatformDefaultWidth = false)
  ) {
    Surface(
      modifier = Modifier
        .fillMaxWidth(0.92f)
        .padding(16.dp),
      shape = RoundedCornerShape(22.dp),
      color = CardSurfaceWhite,
      shadowElevation = 8.dp,
      border = BorderStroke(1.dp, BorderWarmGray)
    ) {
      Column(
        modifier = Modifier
          .fillMaxWidth()
          .padding(20.dp)
          .verticalScroll(scrollState)
      ) {
        // Top action bar
        Row(
          modifier = Modifier.fillMaxWidth(),
          horizontalArrangement = Arrangement.SpaceBetween,
          verticalAlignment = Alignment.CenterVertically
        ) {
          Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Receipt, contentDescription = null, tint = DeepTealPrimary)
            Spacer(modifier = Modifier.width(8.dp))
            Text(
              text = "Official Tuition Receipt",
              style = MaterialTheme.typography.titleMedium,
              fontWeight = FontWeight.Bold,
              color = TextInkPrimary
            )
          }
          IconButton(onClick = onDismiss) {
            Icon(Icons.Default.Close, contentDescription = "Close", tint = TextSecondaryMuted)
          }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Receipt Document Body
        Column(
          modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, BorderWarmGray, RoundedCornerShape(16.dp))
            .background(WarmIvoryBackground, RoundedCornerShape(16.dp))
            .padding(16.dp),
          horizontalAlignment = Alignment.CenterHorizontally
        ) {
          Text(
            text = profile.tuitionName.ifBlank { "Tutor Ledger" },
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = DeepTealPrimary,
            textAlign = TextAlign.Center
          )
          Text(
            text = "${profile.teacherName} • ${profile.phone}",
            style = MaterialTheme.typography.bodySmall,
            color = TextSecondaryMuted
          )
          if (profile.address.isNotBlank()) {
            Text(
              text = profile.address,
              style = MaterialTheme.typography.bodySmall,
              color = TextSecondaryMuted,
              textAlign = TextAlign.Center
            )
          }

          Spacer(modifier = Modifier.height(8.dp))
          PaymentStatusBadge(status = payment.status)
          Spacer(modifier = Modifier.height(12.dp))

          HorizontalDivider(color = BorderWarmGray.copy(alpha = 0.7f))
          Spacer(modifier = Modifier.height(10.dp))

          // Meta info
          ReceiptRow(label = "Receipt No", value = payment.receiptNumber, isBold = true)
          ReceiptRow(label = "Date", value = DateUtils.formatDisplayDate(payment.paymentDate))
          ReceiptRow(label = "Student", value = payment.studentName, isBold = true)
          ReceiptRow(label = "Student ID", value = payment.studentId)
          ReceiptRow(label = "Class", value = payment.studentClass)

          Spacer(modifier = Modifier.height(8.dp))
          HorizontalDivider(color = BorderWarmGray.copy(alpha = 0.7f))
          Spacer(modifier = Modifier.height(8.dp))

          val periods = if (payment.allocatedFeePeriods.isEmpty()) "General Arrears / Advance"
          else payment.allocatedFeePeriods.joinToString(", ") { DateUtils.formatShortPeriod(it) }
          ReceiptRow(label = "Fee Period(s)", value = periods)
          ReceiptRow(label = "Payment Mode", value = payment.paymentMethod.label)
          if (payment.transactionReference.isNotBlank()) {
            ReceiptRow(label = "Reference / UTR", value = payment.transactionReference)
          }
          if (payment.notes.isNotBlank()) {
            ReceiptRow(label = "Notes", value = payment.notes)
          }

          Spacer(modifier = Modifier.height(14.dp))

          // Amount in INR (₹)
          Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = DeepTealContainer),
            shape = RoundedCornerShape(12.dp),
            border = BorderStroke(1.dp, DeepTealPrimary.copy(alpha = 0.2f))
          ) {
            Column(
              modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
              horizontalAlignment = Alignment.CenterHorizontally
            ) {
              Text(
                text = "TOTAL AMOUNT RECEIVED (INR)",
                style = MaterialTheme.typography.labelSmall,
                color = DeepTealOnContainer,
                fontWeight = FontWeight.Bold,
                letterSpacing = 0.5.sp
              )
              Spacer(modifier = Modifier.height(2.dp))
              Text(
                text = FormatUtils.formatCurrency(payment.amount, profile.currencySymbol),
                fontSize = 24.sp,
                fontWeight = FontWeight.ExtraBold,
                color = DeepTealPrimary
              )
              Text(
                text = FormatUtils.numberToWords(payment.amount),
                style = MaterialTheme.typography.bodySmall,
                color = DeepTealOnContainer.copy(alpha = 0.85f),
                textAlign = TextAlign.Center,
                fontSize = 11.sp
              )
            }
          }

          Spacer(modifier = Modifier.height(12.dp))
          Text(
            text = profile.receiptFooterNote.ifBlank { "Acknowledged with thanks." },
            style = MaterialTheme.typography.bodySmall,
            color = TextSecondaryMuted,
            textAlign = TextAlign.Center,
            fontSize = 11.sp
          )
        }

        Spacer(modifier = Modifier.height(18.dp))

        // Action Buttons: Print, WhatsApp & Share
        Row(
          modifier = Modifier.fillMaxWidth(),
          horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
          OutlinedButton(
            onClick = {
              ReceiptPrinter.printReceipt(context, payment, profile)
            },
            modifier = Modifier.weight(1f),
            shape = RoundedCornerShape(12.dp),
            border = BorderStroke(1.dp, BorderWarmGray),
            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 8.dp)
          ) {
            Icon(Icons.Default.Print, contentDescription = null, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(4.dp))
            Text("PDF / Print", fontSize = 12.sp)
          }

          Button(
            onClick = {
              FormatUtils.shareReceipt(context, payment, profile)
            },
            modifier = Modifier.weight(1f),
            colors = ButtonDefaults.buttonColors(containerColor = DeepTealPrimary),
            shape = RoundedCornerShape(12.dp),
            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 8.dp)
          ) {
            Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(4.dp))
            Text("Share Text", fontSize = 12.sp, fontWeight = FontWeight.Bold)
          }
        }
      }
    }
  }
}

@Composable
private fun ReceiptRow(label: String, value: String, isBold: Boolean = false) {
  Row(
    modifier = Modifier
      .fillMaxWidth()
      .padding(vertical = 3.dp),
    horizontalArrangement = Arrangement.SpaceBetween
  ) {
    Text(
      text = label,
      style = MaterialTheme.typography.bodySmall,
      color = TextSecondaryMuted
    )
    Text(
      text = value,
      style = MaterialTheme.typography.bodySmall,
      fontWeight = if (isBold) FontWeight.Bold else FontWeight.Normal,
      color = TextInkPrimary
    )
  }
}

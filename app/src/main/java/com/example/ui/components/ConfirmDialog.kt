package com.example.ui.components

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.ui.theme.*

@Composable
fun ConfirmDialog(
  title: String,
  message: String,
  confirmButtonText: String = "Confirm",
  dismissButtonText: String = "Cancel",
  icon: ImageVector? = null,
  isDestructive: Boolean = false,
  onConfirm: () -> Unit,
  onDismiss: () -> Unit
) {
  AlertDialog(
    onDismissRequest = onDismiss,
    shape = RoundedCornerShape(20.dp),
    containerColor = CardSurfaceWhite,
    icon = if (icon != null) {
      { Icon(imageVector = icon, contentDescription = null, tint = if (isDestructive) StatusOverdue else DeepTealPrimary) }
    } else null,
    title = {
      Text(
        text = title,
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.Bold,
        color = TextInkPrimary
      )
    },
    text = {
      Text(
        text = message,
        style = MaterialTheme.typography.bodyMedium,
        color = TextSecondaryMuted
      )
    },
    confirmButton = {
      Button(
        onClick = {
          onConfirm()
          onDismiss()
        },
        shape = RoundedCornerShape(10.dp),
        colors = if (isDestructive) {
          ButtonDefaults.buttonColors(
            containerColor = StatusOverdue,
            contentColor = androidx.compose.ui.graphics.Color.White
          )
        } else {
          ButtonDefaults.buttonColors(
            containerColor = DeepTealPrimary,
            contentColor = androidx.compose.ui.graphics.Color.White
          )
        }
      ) {
        Text(confirmButtonText, fontWeight = FontWeight.Bold)
      }
    },
    dismissButton = {
      OutlinedButton(
        onClick = onDismiss,
        shape = RoundedCornerShape(10.dp)
      ) {
        Text(dismissButtonText, color = TextInkPrimary)
      }
    }
  )
}


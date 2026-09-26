# Tuition Fee Manager 📱

[![Build & Release APK](https://github.com/JRalex07/TutorFee/actions/workflows/release-apk.yml/badge.svg)](https://github.com/JRalex07/TutorFee/actions/workflows/release-apk.yml)
[![Latest Release](https://img.shields.io/github/v/release/JRalex07/TutorFee?color=008080&label=Release)](https://github.com/JRalex07/TutorFee/releases/latest)
[![Download APK](https://img.shields.io/badge/Download-Release%20APK-brightgreen?logo=android&logoColor=white)](https://github.com/JRalex07/TutorFee/releases/latest/download/app-release.apk)
[![Platform](https://img.shields.io/badge/Platform-Android%207.0%2B%20(API%2024%2B)-blue.svg)](https://developer.android.com)

A modern, fast, and secure student tuition fee collection and ledger management application built for private tutors, coaching centers, and educational mentors. Built 100% with **Kotlin**, **Jetpack Compose (Material 3)**, **Room SQLite Database** for instant offline access, and **Firebase Firestore** for real-time cloud backup.

---

## ✨ Features

- **📊 Smart Dashboard & Analytics**: Real-time snapshot of monthly collections, overdue dues, pending amounts, active students, and collection progress.
- **👨‍🎓 Student Management**: Complete student profiles with parent contacts, class, subjects, batches, preferred due dates, custom monthly fees, and concessions.
- **💳 Fee Collection & Partial Payments**: Collect fees via Cash, UPI, Bank Transfer, or Cheque. Automatic handling of partial dues, advance balance carryover, and waivers.
- **🧾 Instant Digital Receipts**: Generate clean itemized receipts with unique receipt numbers, amount in words (Indian Rupees), and 1-tap WhatsApp sharing directly to parents.
- **⏳ Pending & Overdue Tracker**: Dedicated ledger showing students with overdue arrears, upcoming due dates, and quick payment actions.
- **📈 Detailed Reports**: Financial summaries, monthly trends, payment methods breakdown, and exportable audit logs.
- **☁️ Cloud Backup & Offline First**: Works 100% offline using local Room SQLite and automatically syncs with Firebase Firestore when online.
- **🎨 Premium Material 3 UI**: Clean deep-teal theme with full dark mode support, fluid micro-animations, and responsive layouts.

---

## 🛠️ Technology Stack

- **UI Framework**: [Jetpack Compose](https://developer.android.com/jetpack/compose) with Material 3 components
- **Language**: Kotlin 2.2+
- **Architecture**: MVVM (Model-View-ViewModel) + Repository Pattern
- **Local Persistence**: [Android Room Database](https://developer.android.com/training/data-storage/room) (SQLite)
- **Cloud Backend**: [Firebase Firestore](https://firebase.google.com/docs/firestore) with persistent offline caching
- **CI/CD**: GitHub Actions automated pipeline building release & debug APKs

---

## ⚙️ Building From Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/JRalex07/TutorFee.git
   cd TutorFee
   ```

2. **Open in Android Studio** (Ladybug / Meerkat or newer recommended).

3. **Build Debug APK**:
   ```bash
   ./gradlew assembleDebug
   ```

4. **Run Unit Tests**:
   ```bash
   ./gradlew test
   ```

---

## 📥 Download Release APK

Get the latest production-ready Android APK directly to your phone:

<div align="center">
  <br />
  <a href="https://github.com/JRalex07/TutorFee/releases/latest/download/app-release.apk">
    <img src="https://img.shields.io/badge/Direct_Download-Release_APK_(Latest)-00796B?style=for-the-badge&logo=android&logoColor=white" height="50" alt="Download Release APK" />
  </a>
  <br /><br />
</div>

- **Direct Download Link (Latest Release)**:
  [🔗 Download app-release.apk](https://github.com/JRalex07/TutorFee/releases/latest/download/app-release.apk)
- **Alternative Mirror**:
  [🔗 Download TuitionFeeManager-Release.apk](https://github.com/JRalex07/TutorFee/releases/latest/download/TuitionFeeManager-Release.apk)

### 📲 How to Install:
1. Tap the **Download Release APK** button above on your Android phone.
2. Once the download finishes, open the downloaded `.apk` file.
3. If prompted by your browser or file manager, enable **"Allow from this source"** in your phone's Settings.
4. Tap **Install** and launch **Tuition Fee Manager**!

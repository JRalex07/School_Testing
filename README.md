# MPS School Management System

[![Build Android APK](https://github.com/JRalex07/School_Testing/actions/workflows/build-apk.yml/badge.svg)](https://github.com/JRalex07/School_Testing/actions/workflows/build-apk.yml)
[![Download Direct APK](https://img.shields.io/badge/Download_APK-app--release.apk-2ea44f?style=for-the-badge&logo=android&logoColor=white)](https://github.com/JRalex07/School_Testing/releases/latest/download/app-release.apk)

👉 **[Click Here to Download app-release.apk](https://github.com/JRalex07/School_Testing/releases/latest/download/app-release.apk)** *(Direct `.apk` file download — no zip extraction required)*

Production Flutter/Dart client for **MPS School Management System** integrated with Firebase.

---

## 1. Project Identification

- **School Name**: MPS
- **Frontend Framework**: Flutter / Dart (SDK: `^3.13.4`)
- **Backend Infrastructure**: Firebase
- **Firebase Project ID**: `tutorfee-83839`
- **Application Package / Bundle ID**: `com.mps.myapplication`
- **Direct APK Download**: [https://github.com/JRalex07/School_Testing/releases/latest/download/app-release.apk](https://github.com/JRalex07/School_Testing/releases/latest/download/app-release.apk)
- **GitHub Repository**: [https://github.com/JRalex07/School_Testing.git](https://github.com/JRalex07/School_Testing.git)
- **CI/CD Actions**: [https://github.com/JRalex07/School_Testing/actions](https://github.com/JRalex07/School_Testing/actions)

---

## 2. Technology Stack & Registered Platforms

- **Flutter / Dart**: Core mobile & web user interface with responsive layouts (Mobile, Tablet, Desktop, Web).
- **Firebase Authentication**: Credential handling and custom claim role assignment.
- **Cloud Firestore**: Authoritative database protected by role- and assignment-based Firestore Security Rules.
- **Firebase Storage**: Controlled file upload paths for school notices and documents.
- **Firebase Emulator Suite**: Local testing harness for Auth, Firestore, and Storage rules.

### Registered Firebase Applications (`tutorfee-83839`)

| Platform | Display Name | Package Name / Bundle ID | App ID |
|---|---|---|---|
| **Android** | `MPS Android` | `com.mps.myapplication` | `1:406689542862:android:56c8d620f4e9ba6a60569f` |
| **iOS** | `MPS iOS` | `com.mps.myapplication` | `1:406689542862:ios:3f6a3b1db3c9d8f360569f` |
| **Web** | `MPS Web App` | `mps-school-management` | `1:406689542862:web:d8b0f482ad7cb72660569f` |

---

## 3. Status of Features

| Feature / Module | Status | Description |
|---|---|---|
| **Role-Based Authentication** | Implemented | Roles: Principal, Teacher, Parent. Server-authoritative tokens & Firestore profile claims. |
| **Teacher Class & Subject Authorization** | Implemented | Strict assignment-based access control. Direct ID-based bypass blocked server-side. |
| **Attendance Management** | Implemented | Daily register marking with audit traceability (who, when, status). |
| **Compact Claymorphism UI** | Implemented | Soft rounded surfaces, dual subtle drop/highlight shadows, tactile controls, restrained padding. |
| **Responsive Component System** | Implemented | Centralized breakpoints (`compactMobile`, `mobile`, `tablet`, `desktop`, `wideDesktop`), adaptive `ResponsiveGrid`, bounded `ResponsivePageContainer`. |
| **Bilingual Localization** | Implemented | Real-time English & Hindi localization without hardcoded strings. |
| **Manual / Offline Payment Recording** | Implemented | Cash, Cheque, Bank Transfer recording with receipt generation & reversals. |
| **Online Payment Gateway** | Disabled / Not Included | Online payment gateways are removed at this stage. |
| **Marks Entry & Publishing** | Implemented | Domain models, subject-level security rules, and tests implemented. |
| **Homework & Learning Materials** | Implemented | Firestore & Storage rules configured with controlled storage paths. |

---

## 4. User Roles & Access Boundaries

### 4.1 Principal (Administrator)
- Full administrative access over all school operations.
- Manages all students, teachers, classes, sections, subjects, and assignments.
- Authority to record and reverse fee payments, publish exam results, and inspect immutable audit logs.

### 4.2 Teacher
- Access is strictly derived from explicit `teacherAssignments` documents (`teacherId`, `academicYearId`, `classId`, `sectionId`, `subjectId`).
- **Class / Section Boundaries**: A teacher assigned to Class 6A can view and manage students only in Class 6A. Access to Class 6B or any other class is strictly **DENIED** at the Firestore rules level.
- **Subject Boundaries**: A teacher assigned to Mathematics in Class 6A cannot enter or modify English marks.
- **No Direct ID Bypass**: Knowing a student's document ID or path does not grant access.
- **No Role Self-Modification**: Teachers cannot modify user roles or grant themselves administrative privileges.
- **No Fee Write Access**: Teachers cannot create or alter financial records.

### 4.3 Parent
- Restricted strictly to linked biological children via `parentUserIds`.
- Read-only access to child attendance, published marks, fee statements, and official receipts.

---

## 5. Payment System Architecture (Manual / Offline)

> [!IMPORTANT]
> **Online payment gateways are disabled at this stage.**
> The active application uses the `ManualPaymentProvider` under the pluggable `PaymentProvider` abstraction.

Supported payment operations:
- Cash payment recording at office counter
- Cheque payment recording with cheque reference numbers
- Bank transfer / demand draft recording
- Automatic official receipt generation (`MPS-RCPT-...`)
- Audit-compliant reversals requiring an explicit reason and manager ID

---

## 6. Responsive Claymorphism Design System

The UI uses a compact, information-dense Claymorphism design language:

- **Centralized Breakpoints**:
  - Compact Mobile: `< 360px`
  - Mobile: `360px – 599px`
  - Tablet: `600px – 1023px`
  - Desktop: `1024px – 1439px`
  - Wide Desktop: `>= 1440px`
- **Reusable Components**:
  - `AppCard`: Dual-shadow claymorphic depth with `minWidth`, `maxWidth`, `minHeight`, `maxHeight` boundaries.
  - `AppStatCard`: Compact metric card (`~96dp` height) with tinted icon and status badge.
  - `ResponsiveGrid`: LayoutBuilder-based auto-reflowing grid avoiding card stretching or clipping.
  - `ResponsivePageContainer`: Bounds content to `1200px` max-width with responsive horizontal gutters.
  - `AppButton`: Compact 40dp height with accessible touch targets.
  - `AppTextField`: Dense 10dp vertical padding bounded to `580px` max-width.
  - `AppDialog`: Bounded to `460px` max-width.

---

## 7. Local Development & Testing

### 7.1 Prerequisites
- Flutter SDK `^3.13.4`
- Dart SDK `^3.13.4`
- Java JDK 17 (for Android APK compilation)

### 7.2 Dependency Installation
```bash
flutter pub get
```

### 7.3 Static Code Analysis
Run static analysis to verify zero errors and compliance with linter rules:
```bash
flutter analyze
```

### 7.4 Running Automated Tests
Run unit, widget, access control, and responsive component tests:
```bash
flutter test
```

Test suite includes:
- `test/teacher_security_test.dart`: Complete 10-test matrix covering teacher boundaries, subject granularity, ID bypass prevention, and role restrictions.
- `test/domain_test.dart`: Model immutability, audit logging, and `ManualPaymentProvider` verification.
- `test/responsive_component_test.dart`: Multi-viewport responsive layout adaptation, grid reflow, page container boundaries, and stat card tests.
- `test/widget_test.dart`: UI rendering, role switching, dark mode, and Hindi localization.

---

## 8. Android Release APK Build (Local)

To compile the release APK locally:
```bash
flutter build apk --release
```

The compiled APK will be generated at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

Or execute the PowerShell build helper:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/build_apk.ps1
```

---

## 9. GitHub Actions CI/CD Workflow

The repository includes an automated CI/CD workflow at [`.github/workflows/build-apk.yml`](https://github.com/JRalex07/School_Testing/blob/main/.github/workflows/build-apk.yml).

### 9.1 Triggers
- Automatic on `push` and `pull_request` to `main` and `master` branches.
- Manual trigger via `workflow_dispatch`.

### 9.2 Build Pipeline Steps
1. Checkout repository (`actions/checkout@v4`).
2. Set up Java JDK 17 (`actions/setup-java@v4`).
3. Set up Flutter stable (`subosito/flutter-action@v2`).
4. Resolve dependencies (`flutter pub get`).
5. Run static code analysis (`flutter analyze`).
6. Run full test suite (`flutter test`).
7. Build Android Release APK (`flutter build apk --release`).
8. Generate build summary in `$GITHUB_STEP_SUMMARY`.
9. Upload release artifact (`actions/upload-artifact@v4`).
10. Publish pure `.apk` binary asset to GitHub Releases (`softprops/action-gh-release@v2`).

---

## 10. Download Release APK (Direct .apk & Artifacts)

### 10.1 Direct APK Download (No Zip File)

> [!TIP]
> To download the raw **`.apk` file directly without extracting any `.zip` archive**, click the direct release link below:

[![Direct APK Download](https://img.shields.io/badge/Download_APK-app--release.apk-2ea44f?style=for-the-badge&logo=android&logoColor=white)](https://github.com/JRalex07/School_Testing/releases/latest/download/app-release.apk)

- **Direct Download Link**: [**`app-release.apk` (Direct Download)**](https://github.com/JRalex07/School_Testing/releases/latest/download/app-release.apk)
- **Latest Release Page**: [GitHub Releases](https://github.com/JRalex07/School_Testing/releases/tag/latest)

Clicking the link above prompts your browser to save `app-release.apk` directly to your downloads.

### 10.2 APK Specifications

| Property | Value |
|---|---|
| **App Name** | MPS School Management System |
| **Package Name** | `com.mps.myapplication` |
| **Binary Filename** | `app-release.apk` |
| **Direct URL** | `https://github.com/JRalex07/School_Testing/releases/latest/download/app-release.apk` |
| **Target Platforms** | Android (Universal: `arm64-v8a`, `armeabi-v7a`, `x86_64`) |
| **Min SDK** | Android 21 (Lollipop 5.0+) |
| **Target SDK** | Android 34 (UpsideDownCake) |
| **Firebase Project** | `tutorfee-83839` |
| **Workflow File** | [`.github/workflows/build-apk.yml`](https://github.com/JRalex07/School_Testing/blob/main/.github/workflows/build-apk.yml) |

### 10.3 Alternative: Download via GitHub Actions Artifacts

If you prefer inspecting individual CI build runs:
1. Open [GitHub Actions Runs](https://github.com/JRalex07/School_Testing/actions/workflows/build-apk.yml).
2. Select the latest completed run with a green checkmark (`✔ Build Android APK`).
3. Scroll to the **Artifacts** section at the bottom.
4. Click **`mps-school-management-apk`** (GitHub Actions packages this as a zip container).
5. For pure unzipped `.apk` files, use the **[Direct APK Download Link](https://github.com/JRalex07/School_Testing/releases/latest/download/app-release.apk)** in Section 10.1 above.

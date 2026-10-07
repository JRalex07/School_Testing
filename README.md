# MPS School Management System

Flutter/Dart client for **MPS School Management System** integrated with Firebase.

---

## 1. Project Identification

- **School Name**: MPS
- **Frontend Framework**: Flutter / Dart (SDK: `^3.13.4`)
- **Backend Infrastructure**: Firebase
- **Firebase Project ID**: `tutorfee-83839`
- **GitHub Repository**: [https://github.com/JRalex07/School_Testing.git](https://github.com/JRalex07/School_Testing.git)

---

## 2. Technology Stack

- **Flutter / Dart**: Core mobile & web user interface with responsive layouts (Mobile, Tablet, Desktop)
- **Firebase Authentication**: Credential handling and custom claim role assignment
- **Cloud Firestore**: Authoritative database protected by role- and assignment-based Firestore Security Rules
- **Firebase Storage**: Controlled file upload paths for school notices and documents
- **Firebase Cloud Messaging (FCM)**: Push notification infrastructure (Planned)
- **Firebase Emulator Suite**: Local testing harness for Auth, Firestore, and Storage rules

---

## 3. Status of Features

| Feature / Module | Status | Description |
|---|---|---|
| **Role-Based Authentication** | Implemented | Roles: Principal, Teacher, Parent. Verified via server-authoritative tokens. |
| **Teacher Class & Subject Authorization** | Implemented | Strict assignment-based access control. ID-based bypass blocked. |
| **Attendance Management** | Implemented | Daily register marking with audit traceability (who, when, status). |
| **Design System & UI Tokens** | Implemented | Material 3 themes, 8-point spacing, accessible typography & contrast. |
| **Bilingual Localization** | Implemented | Real-time English & Hindi localization without hardcoded strings. |
| **Manual / Offline Payment Recording** | Implemented | Cash, Cheque, Bank Transfer recording with receipt generation & reversals. |
| **Online Payment Gateway** | Disabled / Not Included | Online payment gateways are removed at this stage. |
| **Marks Entry & Publishing** | Partially implemented | Domain models, subject-level security rules, and tests implemented. |
| **Homework & Learning Materials** | Partially implemented | Firestore & Storage rules configured; UI flow planned. |
| **Push Notifications (FCM)** | Planned | Planned for future release. |

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

## 5. Payment System Architecture

> [!IMPORTANT]
> **Online payment gateways are currently disabled and not included.**
> The active application uses the `ManualPaymentProvider` under the pluggable `PaymentProvider` abstraction.

Supported payment operations:
- Cash payment recording at office counter
- Cheque payment recording with cheque reference numbers
- Bank transfer / demand draft recording
- Automatic official receipt generation (`MPS-RCPT-...`)
- Audit-compliant reversals requiring an explicit reason and manager ID

Online payment gateways can be integrated in future phases via the `PaymentProvider` interface without altering underlying fee schemas.

---

## 6. Production Data Safety

- Production environments strictly **do not contain demo or seed data**.
- No placeholder or fake student/teacher records are seeded into Firebase project `tutorfee-83839`.
- All development and security test seeds are strictly isolated to automated test suites (`test/`).

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
Run unit, widget, and access control tests:
```bash
flutter test
```
Test suite includes:
- `test/teacher_security_test.dart`: Complete 10-test matrix covering teacher boundaries, subject granularity, ID bypass prevention, and role restrictions.
- `test/domain_test.dart`: Model immutability, audit logging, and `ManualPaymentProvider` verification.
- `test/widget_test.dart`: UI rendering, role switching, dark mode, and Hindi localization.

---

## 8. Android Release APK Build

To build the release APK locally:
```bash
flutter build apk --release
```

The compiled APK will be generated at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

Alternatively, use the PowerShell helper script:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/build_apk.ps1
```

---

## 9. GitHub Actions CI/CD Workflow

The repository includes a production-quality workflow at [`.github/workflows/build-apk.yml`](file:///d:/my_project_files/schooltesting/.github/workflows/build-apk.yml).

### 9.1 Triggers
- Automatic triggers on `push` and `pull_request` to `main` and `master` branches.
- Manual trigger via `workflow_dispatch`.

### 9.2 Permissions
Configured with minimal least-privilege permissions:
```yaml
permissions:
  contents: read
```

### 9.3 Downloading the APK Artifact
1. Go to your repository on GitHub: `https://github.com/JRalex07/School_Testing`
2. Click on the **Actions** tab.
3. Select the latest run of **Build Android APK**.
4. Scroll down to the **Artifacts** section at the bottom of the summary page.
5. Click **mps-school-management-apk** to download the generated `.apk` file.

# MPS School Management System — Antigravity Workspace Rules

## 1. Project Identity

Project:
MPS School Management System

Frontend:
Flutter/Dart

Backend:
Firebase

Firebase Project:
`tutorfee-83839`

Primary services:
Firebase Auth, Firestore, Storage, Cloud Functions, FCM, App Check, Hosting, Analytics/Crashlytics where applicable.

---

# 2. Core Engineering Rules

## ALWAYS

- Read existing code before modifying it.
- Reuse working code where practical.
- Follow the existing architectural pattern unless there is a documented reason to change it.
- Keep business logic out of widgets.
- Keep Firebase access behind repositories/services/providers where the existing architecture supports that pattern.
- Use strongly typed Dart models.
- Validate all input.
- Handle loading, empty, success and error states.
- Handle network failure and offline conditions gracefully.
- Use transactions/batched writes where atomicity is required.
- Add tests for critical business logic.
- Run `flutter analyze`.
- Run relevant unit/widget/integration tests.
- Run Firebase Emulator tests for Auth/Firestore/Storage rules where applicable.
- Update README/documentation whenever architecture or setup changes.
- Record important architectural decisions.
- Maintain a migration/rollback strategy before changing production data.

---

# 3. Firebase Rules

## NEVER

- Never trust a role supplied by the Flutter client.
- Never use UI visibility as authorization.
- Never store admin credentials in Flutter.
- Never store Firebase Admin SDK credentials in the repository.
- Never commit API secrets or private keys.
- Never bypass Firestore Security Rules for convenience.
- Never give parents unrestricted student collection access.
- Never allow a teacher to query or manage students outside their assigned class/section/subject.
- Never allow clients to directly modify privileged fields such as roles, fee totals, payment verification state, result publication state or audit metadata.
- Never delete production data without an approved backup/recovery strategy.
- Never write business-critical authorization logic only in Dart.

---

# 4. Authentication

Use Firebase Authentication for credential handling.

Supported authentication may include:

- Email/password
- Phone OTP
- Controlled account discovery using admission/staff identifiers

Do NOT implement custom password hashing.
Do NOT store passwords in Firestore.
Use Firebase custom claims for authoritative roles where appropriate.
Keep Firestore user profiles minimal and non-authoritative for privilege escalation.
Implement safe logout and account-wide session revocation for security-sensitive account actions.
Never expose whether an arbitrary admission number, email or phone belongs to an account.

---

# 5. Authorization

The minimum role model is:

- parent
- teacher
- principal

Optional roles may include:

- vicePrincipal
- accountant
- feeClerk
- officeStaff

Every protected operation must have a server-side authorization rule.

Parent access:
Only linked children.

Teacher access:
Strictly limited to assigned classes, sections, and subjects via authoritative `teacherAssignments`.

Principal access:
Full school administration.

---

# 6. Firestore Rules

Firestore rules must:

- validate authenticated user state
- validate role/custom claims
- validate parent-student relationship
- validate explicit teacher assignment (class, section, subject)
- restrict privileged writes
- prevent unauthorized field changes
- prevent users changing their own role
- prevent clients fabricating audit metadata
- validate immutable identifiers
- restrict deletes

---

# 7. Firestore Data Design

Prefer normalized top-level entities.

Avoid:

- enormous parent documents
- unbounded arrays
- deeply nested documents that are difficult to query
- duplicated mutable financial truth
- duplicated role authority

Use IDs and references for relationships.
Use subcollections when they represent naturally scoped high-volume data.
Create indexes based on actual query patterns.

---

# 8. Financial Rules (Offline / Manual Payment Provider)

Fees and payments are financially sensitive.

Online payment gateways are currently disabled. The active system operates on manual / offline payment recording (`ManualPaymentProvider`).

Payment records must preserve:

- payment identifiers
- fee record reference
- amount
- currency
- payment method (Cash, Cheque, Bank Transfer, Demand Draft)
- reference number (Cheque No. / Bank Ref / Receipt No.)
- status
- timestamps
- receipt reference
- audit information (recordedBy, reversedBy, reversalReason)

Do not silently overwrite financial records.
Corrections and reversals require explicit audit information and reason.

---

# 9. Results and Attendance

Marks and attendance are sensitive academic records.

Teachers may edit only records for their assigned class, section, and subject.
Class teacher permissions are handled separately from subject teacher permissions.
Published results must not be silently changed.
Attendance changes must preserve who changed the value and when.

---

# 10. Storage Rules

All uploaded files must have controlled paths:

`school/{schoolId}/students/{studentId}/...`
`school/{schoolId}/notices/{noticeId}/...`
`school/{schoolId}/homework/{classId}/{subjectId}/...`
`school/{schoolId}/receipts/{receiptId}/...`

---

# 11. Audit Logging

Audit at minimum:

- role changes
- teacher assignment changes
- student transfers
- attendance corrections
- marks changes
- result publication
- fee creation
- manual payment recording
- payment correction/reversal
- account activation/deactivation

Audit records are append-only and cannot be modified or deleted.

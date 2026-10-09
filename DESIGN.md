# MPS School Management System — Design System & UI Specification
# Tactile Academic System (Professional Claymorphism)

Derived directly from Stitch Project `projects/6002049475132200951` ("MPS School Management UI System").

---

## 1. Design Philosophy: Tactile Academic System

The **Tactile Academic System** blends high-density institutional data clarity with playful, touchable physical computing metaphors (**Professional Claymorphism**):
1. **Institutional Trust & Restraint**: Carmine Magenta (`#E11D48`) and Deep Magenta (`#B80035`) paired with soft porcelain backgrounds (`#F8F9FF`) convey seriousness and authority without sterile rigidity.
2. **Tactile Dimensionality**: Soft dual-shadow claymorphism — a warm diffuse key shadow (`rgba(225, 29, 72, 0.08)`) combined with a crisp top rim specular light (`rgba(255, 255, 255, 0.95)`).
3. **Full Pill Semantics**: All interactive triggers, status indicators, and buttons utilize full pill radii (`radiusPill: 999.0`), producing approachable, soft-touch physical buttons.
4. **Adaptive Multi-Role Bento Grids**: Parent, Teacher, and Administrator dashboards employ responsive 3-pod and 4-pod bento cards with micro-accent containers.

---

## 2. Color Palette & Semantic Tokens

| Token Name | Light Mode Value | Dark Mode Value | Usage |
|---|---|---|---|
| `primary` | `#E11D48` (Carmine Magenta) | `#FB7185` (Rose 400) | Brand primary, action highlights, primary pills |
| `primaryDeep` | `#B80035` | `#FDA4AF` | Concentric crest rims, high-contrast badges |
| `surface` | `#F8F9FF` (Porcelain Blush) | `#0F172A` (Slate 900) | Scaffold & canvas background |
| `surfaceContainerLowest` | `#FFFFFF` | `#1E293B` | Clay cards, elevated pedestals |
| `surfaceContainerHigh` | `#EEF2F6` | `#334155` | Sunken wells, segmented toggle tracks |
| `secondaryFixed` | `#FFE4E6` (Soft Rose) | `#3F1D2C` | Pill badges, accent highlights |
| `clayShadow` | `rgba(225, 29, 72, 0.08)` | `rgba(0, 0, 0, 0.40)` | Warm key drop shadow |
| `clayBorder` | `rgba(225, 29, 72, 0.12)` | `rgba(255, 255, 255, 0.08)` | Molded clay perimeter boundary |
| `success` | `#16A34A` | `#22C55E` | Present status, cleared dues, active sessions |
| `successContainer` | `#DCFCE7` | `#14532D` | Present badge background |
| `error` | `#DC2626` | `#EF4444` | Absent mark, payment due, form errors |
| `errorContainer` | `#FEE2E2` | `#7F1D1D` | Absent badge background |

---

## 3. Radii & Claymorphic Elevation

- **Pill Radius** (`AppRadius.radiusPill`): `999.0` (all buttons, tags, chips, status badges)
- **Card Radius** (`AppRadius.card`): `18.0` (tactile metric pods, bento cards, student roster tiles)
- **Pedestal Radius** (`AppRadius.radiusXl`): `24.0` (hero cards, authentication crest wells)

### Level 1 Dual-Shadow Claymorphism (Cards & Pods)
```dart
BoxDecoration(
  color: AppColors.surfaceContainerLowest,
  borderRadius: BorderRadius.circular(AppRadius.card),
  border: Border.all(color: AppColors.clayBorder),
  boxShadow: [
    BoxShadow(
      color: AppColors.clayShadow,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.white.withAlpha(240),
      blurRadius: 1,
      offset: Offset(0, -1),
    ),
  ],
)
```

---

## 4. Screen Specifications

### 4.1 Parent Login & OTP (`login_screen.dart`)
- **Concentric Crest Pedestal**: Triple-layered carmine circle with gold shield icon and floating verified green badge.
- **Sunken Input Well**: `+91` Indian flag prefix well with sculpted border and 10-digit numeric constraint.
- **6-Digit Clay OTP Segment**: Individual tactile boxes with automatic focus-hop and verified checkmark.
- **256-Bit SSL Reassurance Card**: Security indicator with padlock confirming zero unauthorized data exposure.

### 4.2 Parent Dashboard (`_buildParentDashboard`)
- **Student Profile Pedestal**: Gradient avatar with student initials, bold name, roll number pill, and child switcher dropdown for multi-kid families.
- **3-Pod Bento Grid**:
  - Attendance Rate (`% Present`, days attended pill)
  - Fee Total Due (`₹ balance`, settled badge)
  - Academic Standing (`Grade A+`, Term 1 Verified)
- **Operational Shortcuts**: Pay Dues, Leave Slip, Timetable, Report Card.
- **Academic Bulletin Banner**: Debating finals and event notices.
- **Fee Settlement Card**: Breakdown of tuition, receipt number, and manual payment trigger.

### 4.3 Teacher Attendance Management (`_buildTeacherDashboard`)
- **Active Session Banner**: Status indicator, academic year tag, and assigned class/section title.
- **4-Pod Real-Time Bento Strip**:
  - `TOTAL`: Total students enrolled in assigned section.
  - `PRESENT`: Active count marked present.
  - `ABSENT`: Active count marked absent.
  - `RATE`: Instant percentage calculation.
- **Tactile P/A Segmented Toggle**: Dual pill buttons `[ P ]` (green) and `[ A ]` (crimson) with micro-shadow feedback on touch.
- **Bulk Action**: `Mark All Present` one-tap shortcut.

### 4.4 Administrator Executive Desk (`_buildPrincipalDashboard`)
- **Executive Header**: Health status badge, AY 26-27 tag, and Quick Action buttons (`Staff Directory`, `Add Student`, `Assign Faculty`).
- **4-Pod Institutional Bento Grid**:
  - Enrolled Students
  - Faculty Assignments
  - Total Fee Collections (Audited Offline Ledger)
  - Pending Collections (Recovery Active)
- **Zero-Trust Security Notice**: Server-side role validation summary.
- **Authoritative Architecture Ledger**: Firestore non-repudiation rules and audit trails.

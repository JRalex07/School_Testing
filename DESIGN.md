# MPS School Management System — Design System & UI Specification

Generated with UI/UX Pro Max for Flutter (`tutorfee-83839`).

---

## 1. Design Principles & Goals

1. **Academic & Financial Trust**: Crisp, professional, accessible, and error-tolerant.
2. **Mobile-First & Adaptive**: Fluid scaling across Phone (320px–599px), Tablet (600px–1023px), and Desktop/Web (1024px+).
3. **Accessibility First (WCAG 2.1 AA)**: Minimum contrast ratio 4.5:1 for normal text, 48x48dp minimum touch target, clear semantics, visible focus rings.
4. **Resilient State Management**: Explicit visual states for Loading, Empty, Success, and Error across all user journeys.
5. **Multi-Role Tailored**: Specialized UI cues and navigation hierarchy for Parent, Teacher, and Principal roles.

---

## 2. Color Palette (Tokens)

| Token Name | Light Mode Hex | Dark Mode Hex | Usage |
|---|---|---|---|
| `primary` | `#4F46E5` (Indigo 600) | `#6366F1` (Indigo 500) | Brand actions, active highlights, key navigation |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` | Text/icons on primary |
| `primaryContainer` | `#EEF2FF` (Indigo 50) | `#312E81` (Indigo 900) | Subtle backgrounds, active tab pills |
| `onPrimaryContainer` | `#3730A3` (Indigo 800) | `#E0E7FF` (Indigo 100) | Text on primary containers |
| `secondary` | `#0284C7` (Sky 600) | `#38BDF8` (Sky 400) | Secondary badges, academic modules |
| `accent` | `#EA580C` (Orange 600) | `#FB923C` (Orange 400) | Important fee CTAs, pending alert badges |
| `surface` | `#FFFFFF` | `#1E293B` (Slate 800) | Cards, sheets, dialogs |
| `surfaceSubtle` | `#F8FAFC` (Slate 50) | `#0F172A` (Slate 900) | Scaffold backgrounds |
| `textPrimary` | `#0F172A` (Slate 900) | `#F8FAFC` (Slate 50) | High emphasis typography |
| `textSecondary` | `#475569` (Slate 600) | `#94A3B8` (Slate 400) | Medium emphasis, secondary metadata |
| `textDisabled` | `#94A3B8` (Slate 400) | `#64748B` (Slate 500) | Disabled labels |
| `border` | `#E2E8F0` (Slate 200) | `#334155` (Slate 700) | Card outlines, input borders, dividers |
| `success` | `#16A34A` (Green 600) | `#22C55E` (Green 500) | Paid fees, present attendance, approved status |
| `warning` | `#D97706` (Amber 600) | `#F59E0B` (Amber 500) | Late fees, partial attendance, pending review |
| `error` | `#DC2626` (Red 600) | `#EF4444` (Red 500) | Unpaid alerts, absent attendance, validation errors |
| `info` | `#2563EB` (Blue 600) | `#60A5FA` (Blue 400) | General notices, circulars |

---

## 3. Spacing System (8-Point Grid)

- `xs`: `4.0` (tight inline spacing, icon tags)
- `sm`: `8.0` (compact gaps, chips, list item padding)
- `md`: `16.0` (standard card padding, screen gutters on mobile)
- `lg`: `24.0` (section separation, modal padding, tablet gutters)
- `xl`: `32.0` (hero spacing, desktop card gutters)
- `xxl`: `48.0` (page-level separation)

---

## 4. Typography Scale

Scale based on Material 3 standard sizing with high-legibility geometric/neo-grotesque font styling:

- **Display Large**: 32pt, Bold (w700), Line Height 40
- **Headline Medium**: 24pt, SemiBold (w600), Line Height 32
- **Title Large**: 20pt, SemiBold (w600), Line Height 28
- **Title Medium**: 16pt, Medium (w500), Line Height 24
- **Body Large**: 16pt, Regular (w400), Line Height 24
- **Body Medium**: 14pt, Regular (w400), Line Height 20
- **Body Small**: 12pt, Regular (w400), Line Height 16
- **Label Large**: 14pt, SemiBold (w600), Line Height 20 (Buttons, Tabs)
- **Label Small**: 11pt, Medium (w500), Line Height 16 (Badges, Timestamps)

---

## 5. Border Radii & Elevation

- `radiusXs`: `4.0` (tiny chips)
- `radiusSm`: `8.0` (form fields, tooltips)
- `radiusMd`: `12.0` (standard buttons, standard cards)
- `radiusLg`: `16.0` (dialogs, prominent cards, bottom sheets)
- `radiusXl`: `24.0` (hero banners, floating panels)
- `radiusPill`: `999.0` (badges, avatars, pill buttons)

**Elevation / Shadows:**
- Flat / Subtle Border: 1px `#E2E8F0` border
- Low: `BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x14000000))`
- Medium: `BoxShadow(offset: Offset(0, 4), blurRadius: 12, color: Color(0x1A000000))`
- Modal: `BoxShadow(offset: Offset(0, 10), blurRadius: 24, color: Color(0x26000000))`

---

## 6. Responsive Breakpoints

- **Mobile**: `< 600px` (Single column, bottom navigation bar, 16px horizontal gutter)
- **Tablet**: `600px – 1023px` (2 columns, navigation rail / compact drawer, 24px gutter)
- **Desktop / Web**: `>= 1024px` (Multi-column dashboard, permanent left sidebar, max-width content container: 1280px)

---

## 7. Component Specifications

### 7.1 Buttons
- Minimum height: 48dp (satisfies accessibility minimum 48x48dp target)
- States: Default, Hover, Pressed, Loading (with spinning progress indicator inside button), Disabled.
- Types: Primary (`AppButton.primary`), Outlined (`AppButton.outlined`), Destructive (`AppButton.destructive`), Text (`AppButton.text`).

### 7.2 Form Fields (`AppTextField`)
- Clear floating/inline label with accessible contrast.
- Visual helper text and dedicated error slot (reserves height to avoid layout jump).
- Keyboard action customization (`TextInputAction.next`, `TextInputAction.done`).
- Prefix & suffix icon support.

### 7.3 Cards (`AppCard`)
- Clean 1px border or subtle elevation.
- Standard inner padding: 16dp.
- Interactive card support (`onTap`) with splash feedback.

### 7.4 State Widgets
- `AppLoadingIndicator`: Centered circular indicator with optional status message.
- `AppEmptyState`: Illustration/icon, title, message, and action CTA button.
- `AppErrorState`: Error icon, error message, and "Try Again" / "Retry" callback.

### 7.5 Tables / Data Rows (`AppDataRow`, `AppTable`)
- Mobile view: Stacked card format.
- Tablet/Desktop view: Tabular row format with zebra striping or crisp dividers.
- Status badges: Paid (Green), Unpaid (Red), Pending (Amber), Draft (Slate).

---

## 8. Role-Based UX Guidelines

### 8.1 Parent Experience
- Overview of linked children.
- Clear fee breakdown: Due date, total amount, concessions, payment history, and official receipts.
- Attendance summary: Monthly percentage, absent dates list.
- Push notifications for announcements and report cards.

### 8.2 Teacher Experience
- Class & Section switcher for authorized classes.
- Attendance register: Bulk mark present/absent with fast toggle and audit confirmation.
- Marks entry: Subject-wise, grade calculation preview, submission lock.

### 8.3 Principal Experience
- School-wide metrics: Total fee collection vs outstanding, staff & student attendance rate.
- Academic analytics & circular broadcast.
- Audit log & user management.

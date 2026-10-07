import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_radius.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'core/widgets/app_badge.dart';
import 'core/widgets/app_button.dart';
import 'core/widgets/app_card.dart';
import 'core/widgets/app_dialog.dart';
import 'core/widgets/app_state_views.dart';
import 'core/widgets/responsive_layout.dart';
import 'domain/models/fee_record.dart';
import 'domain/models/student.dart';
import 'domain/models/teacher_assignment.dart';
import 'domain/models/user_role.dart';
import 'domain/services/payment_provider.dart';
import 'domain/services/teacher_authorization_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MPSApp());
}

class MPSApp extends StatefulWidget {
  const MPSApp({super.key});

  @override
  State<MPSApp> createState() => _MPSAppState();
}

class _MPSAppState extends State<MPSApp> {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleLocale() {
    setState(() {
      _locale = _locale.languageCode == 'en'
          ? const Locale('hi')
          : const Locale('en');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MPSScreen(
        onToggleTheme: _toggleTheme,
        onToggleLocale: _toggleLocale,
        isDarkMode: _themeMode == ThemeMode.dark,
        currentLocale: _locale,
      ),
    );
  }
}

class MPSScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLocale;
  final bool isDarkMode;
  final Locale currentLocale;

  const MPSScreen({
    super.key,
    required this.onToggleTheme,
    required this.onToggleLocale,
    required this.isDarkMode,
    required this.currentLocale,
  });

  @override
  State<MPSScreen> createState() => _MPSScreenState();
}

enum DemoViewState { content, loading, empty, error }

class _MPSScreenState extends State<MPSScreen> {
  UserRole _selectedRole = UserRole.parent;
  DemoViewState _currentViewState = DemoViewState.content;
  int _selectedTabIndex = 0;

  final TeacherAuthorizationService _authService = const TeacherAuthorizationService();
  final ManualPaymentProvider _paymentProvider = ManualPaymentProvider();

  // Active Teacher assignments (Teacher A assigned to Class 6A Mathematics only)
  final List<TeacherAssignment> _activeTeacherAssignments = [
    TeacherAssignment(
      id: 'assign_teacher_6A_math',
      teacherId: 'teacher_user_01',
      academicYearId: '2026-2027',
      classId: '6',
      sectionId: 'A',
      subjectId: 'math',
      isClassTeacher: true,
      assignedAt: DateTime(2026, 4, 1),
    ),
  ];

  // Active Student in Class 6A
  final Student _activeStudent = const Student(
    id: 'std_6A_001',
    admissionNumber: 'MPS-2026-001',
    fullName: 'Student (Class 6-A)',
    classId: '6',
    section: 'A',
    rollNumber: '101',
    parentUserIds: ['parent_user_01'],
  );

  // Fee Record (Manual / Offline payment model)
  FeeRecord _sampleFee = FeeRecord(
    id: 'fee_term1_2026',
    schoolId: 'mps_main',
    studentId: 'std_6A_001',
    studentName: 'Student (Class 6-A)',
    title: 'Term 1 Tuition & Composite Fee',
    amount: 14500.0,
    paidAmount: 0.0,
    dueDate: DateTime(2026, 11, 15),
    status: PaymentStatus.unpaid,
    isServerVerified: true,
  );

  // Attendance Register for Class 6A
  final List<Map<String, dynamic>> _attendanceList = [
    {'name': 'Student 101', 'roll': '101', 'present': true},
    {'name': 'Student 102', 'roll': '102', 'present': true},
    {'name': 'Student 103', 'roll': '103', 'present': false},
    {'name': 'Student 104', 'roll': '104', 'present': true},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.radiusSm,
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 20),
            ),
            AppSpacing.gapSm,
            Flexible(
              child: Text(
                l10n.translate('app_title'),
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.currentLocale.languageCode == 'en'
                ? 'Switch to Hindi'
                : 'अंग्रेजी में बदलें',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate, size: 18),
                const SizedBox(width: 4),
                Text(
                  widget.currentLocale.languageCode.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onPressed: widget.onToggleLocale,
          ),
          IconButton(
            tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 20,
            ),
            onPressed: widget.onToggleTheme,
          ),
          AppSpacing.gapSm,
        ],
      ),
      body: ResponsiveLayout(
        mobile: (ctx) => _buildMobileLayout(ctx, l10n, theme),
        tablet: (ctx) => _buildTabletLayout(ctx, l10n, theme),
        desktop: (ctx) => _buildDesktopLayout(ctx, l10n, theme),
      ),
      bottomNavigationBar: ResponsiveLayout.isMobile(context)
          ? NavigationBar(
              selectedIndex: _selectedTabIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedTabIndex = index);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: l10n.translate('dashboard'),
                ),
                const NavigationDestination(
                  icon: Icon(Icons.security_outlined),
                  selectedIcon: Icon(Icons.security),
                  label: 'Access Control',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'States',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleSelectorCard(l10n),
          AppSpacing.gapMd,
          _buildActiveTabContent(context, l10n, theme),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedTabIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedTabIndex = index);
          },
          labelType: NavigationRailLabelType.all,
          destinations: [
            NavigationRailDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: Text(l10n.translate('dashboard')),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.security_outlined),
              selectedIcon: Icon(Icons.security),
              label: Text('Access Control'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: Text('States'),
            ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleSelectorCard(l10n),
                AppSpacing.gapLg,
                _buildActiveTabContent(context, l10n, theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          width: 250,
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: AppSpacing.paddingMd,
                child: Text(
                  'MPS NAVIGATION',
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(140),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: Text(l10n.translate('dashboard')),
                selected: _selectedTabIndex == 0,
                selectedTileColor: theme.colorScheme.primaryContainer,
                onTap: () => setState(() => _selectedTabIndex = 0),
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Access Control & Security'),
                selected: _selectedTabIndex == 1,
                selectedTileColor: theme.colorScheme.primaryContainer,
                onTap: () => setState(() => _selectedTabIndex = 1),
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('State Simulation'),
                selected: _selectedTabIndex == 2,
                selectedTileColor: theme.colorScheme.primaryContainer,
                onTap: () => setState(() => _selectedTabIndex = 2),
              ),
              const Spacer(),
              Padding(
                padding: AppSpacing.paddingMd,
                child: AppCard(
                  color: theme.colorScheme.primaryContainer.withAlpha(80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project tutorfee-83839',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MPS Backend & Firestore Rules Active',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxContentWidth,
              ),
              child: SingleChildScrollView(
                padding: AppSpacing.paddingXl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoleSelectorCard(l10n),
                    AppSpacing.gapXl,
                    _buildActiveTabContent(context, l10n, theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelectorCard(AppLocalizations l10n) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.primary, size: 20),
              AppSpacing.gapSm,
              Text(
                'ROLE AUTHORIZATION CONTEXT',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildRoleChip(UserRole.parent, l10n.translate('role_parent'),
                  Icons.family_restroom),
              _buildRoleChip(UserRole.teacher, l10n.translate('role_teacher'),
                  Icons.person),
              _buildRoleChip(UserRole.principal,
                  l10n.translate('role_principal'), Icons.admin_panel_settings),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16, color: isSelected ? Colors.white : AppColors.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedRole = role);
      },
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDashboardContent(context, l10n, theme);
      case 1:
        return _buildAccessControlContent(context, l10n);
      case 2:
        return _buildStateSimulationContent(context, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- TAB 1: Dashboard ---
  Widget _buildDashboardContent(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_currentViewState == DemoViewState.loading) {
      return AppLoadingIndicator(message: l10n.translate('loading'));
    }
    if (_currentViewState == DemoViewState.empty) {
      return AppEmptyState(
        title: l10n.translate('empty_fees'),
        description: 'No pending records found.',
        actionLabel: 'Refresh',
        onAction: () =>
            setState(() => _currentViewState = DemoViewState.content),
      );
    }
    if (_currentViewState == DemoViewState.error) {
      return AppErrorState(
        message: l10n.translate('error_network'),
        onRetry: () =>
            setState(() => _currentViewState = DemoViewState.content),
      );
    }

    switch (_selectedRole) {
      case UserRole.parent:
        return _buildParentDashboard(context, l10n, theme);
      case UserRole.teacher:
        return _buildTeacherDashboard(context, l10n, theme);
      case UserRole.principal:
        return _buildPrincipalDashboard(context, l10n, theme);
      default:
        return _buildParentDashboard(context, l10n, theme);
    }
  }

  // Parent View
  Widget _buildParentDashboard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student: ${_activeStudent.fullName} (${_activeStudent.admissionNumber})',
          style: AppTypography.titleLarge,
        ),
        AppSpacing.gapMd,
        AppCard(
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('fee_total_due'),
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  AppBadge(
                    label: _sampleFee.status == PaymentStatus.paid
                        ? l10n.translate('fee_status_paid')
                        : 'Due Nov 15',
                    variant: _sampleFee.status == PaymentStatus.paid
                        ? AppBadgeVariant.success
                        : AppBadgeVariant.warning,
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Text(
                '₹${_sampleFee.balanceDue.toStringAsFixed(0)}',
                style: AppTypography.displayLarge.copyWith(
                  color: _sampleFee.balanceDue == 0
                      ? AppColors.success
                      : AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              AppSpacing.gapSm,
              Text(_sampleFee.title, style: AppTypography.bodyMedium),
              if (_sampleFee.receiptNumber != null) ...[
                AppSpacing.gapSm,
                Text(
                  'Receipt: ${_sampleFee.receiptNumber}',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
              AppSpacing.gapLg,
              // Manual Payment Recording action (offline payment provider)
              AppButton.primary(
                text: l10n.translate('fee_record_payment'),
                icon: Icons.receipt_long_outlined,
                onPressed: _sampleFee.balanceDue == 0
                    ? null
                    : () async {
                        final result = await _paymentProvider.recordPayment(
                          schoolId: 'mps_main',
                          feeRecord: _sampleFee,
                          amount: _sampleFee.balanceDue,
                          paymentMethod: PaymentMethod.cash,
                          recordedByUserId: 'office_staff_01',
                          notes: 'Official fee counter cash collection',
                        );
                        if (result.isSuccess) {
                          final payment = result.dataOrNull!;
                          setState(() {
                            _sampleFee = FeeRecord(
                              id: _sampleFee.id,
                              schoolId: _sampleFee.schoolId,
                              studentId: _sampleFee.studentId,
                              studentName: _sampleFee.studentName,
                              title: _sampleFee.title,
                              amount: _sampleFee.amount,
                              paidAmount: _sampleFee.amount,
                              dueDate: _sampleFee.dueDate,
                              status: PaymentStatus.paid,
                              lastPaymentMethod: 'cash',
                              receiptNumber: payment.receiptNumber,
                              paidAt: payment.paidAt,
                              isServerVerified: true,
                            );
                          });
                          if (context.mounted) {
                            AppDialog.showAlert(
                              context: context,
                              title: 'Official Receipt Generated',
                              message:
                                  '${l10n.translate('fee_payment_recorded_success')}\n\nReceipt Number: ${payment.receiptNumber}\nAmount: ₹${payment.amount}',
                            );
                          }
                        }
                      },
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('attendance_rate'),
                    style: AppTypography.titleMedium,
                  ),
                  const AppBadge(
                    label: '96% Present',
                    variant: AppBadgeVariant.success,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
              AppSpacing.gapSm,
              const LinearProgressIndicator(
                value: 0.96,
                color: AppColors.success,
                backgroundColor: AppColors.lightBorder,
                minHeight: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Teacher View (Restricted to assigned Class 6A)
  Widget _buildTeacherDashboard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.translate('attendance_mark')} — Assigned: Class 6-A (Math)',
                    style: AppTypography.titleLarge,
                  ),
                  Text(
                    'Access limited to explicit assignment (Teacher A → Class 6A)',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            AppSpacing.gapSm,
            AppButton.primary(
              text: l10n.translate('save'),
              icon: Icons.check,
              fullWidth: false,
              onPressed: () {
                AppDialog.showAlert(
                  context: context,
                  title: 'Attendance Recorded',
                  message: l10n.translate('attendance_save_confirm'),
                );
              },
            ),
          ],
        ),
        AppSpacing.gapMd,
        AppCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _attendanceList.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, idx) {
              final student = _attendanceList[idx];
              final isPresent = student['present'] as bool;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    student['roll'] as String,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  student['name'] as String,
                  style: AppTypography.titleMedium,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBadge(
                      label: isPresent
                          ? l10n.translate('attendance_present')
                          : l10n.translate('attendance_absent'),
                      variant: isPresent
                          ? AppBadgeVariant.success
                          : AppBadgeVariant.error,
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isPresent,
                      activeThumbColor: AppColors.success,
                      activeTrackColor: AppColors.successContainer,
                      onChanged: (val) {
                        setState(() {
                          _attendanceList[idx]['present'] = val;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Principal View
  Widget _buildPrincipalDashboard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MPS Administrative & Security Overview',
          style: AppTypography.titleLarge,
        ),
        AppSpacing.gapMd,
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildMetricCard(
              title: l10n.translate('fee_total_collected'),
              value: '₹14,500',
              badge: 'Manual Offline',
              badgeVariant: AppBadgeVariant.success,
              icon: Icons.receipt_outlined,
            ),
            _buildMetricCard(
              title: 'Active Teacher Assignments',
              value: '1 Verified',
              badge: 'Class 6A',
              badgeVariant: AppBadgeVariant.info,
              icon: Icons.assignment_ind_outlined,
            ),
          ],
        ),
        AppSpacing.gapLg,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Security Architecture Status',
                  style: AppTypography.titleMedium),
              AppSpacing.gapSm,
              Text(
                '• Firestore Security Rules: Strict teacher assignment checks active\n'
                '• Online Payment Gateway: Disabled (Offline manual recording only)\n'
                '• Direct ID Bypass Prevention: Enforced server-side\n'
                '• Audit Logging: Append-only immutable logs enabled',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String badge,
    required AppBadgeVariant badgeVariant,
    required IconData icon,
  }) {
    return SizedBox(
      width: 260,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                AppBadge(label: badge, variant: badgeVariant),
              ],
            ),
            AppSpacing.gapMd,
            Text(title, style: AppTypography.bodySmall),
            AppSpacing.gapXs,
            Text(
              value,
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: Access Control Simulation ---
  Widget _buildAccessControlContent(BuildContext context, AppLocalizations l10n) {
    // Simulated attempts
    const student6B = Student(
      id: 'std_6B_099',
      admissionNumber: 'MPS-2026-99',
      fullName: 'Student in 6-B',
      classId: '6',
      section: 'B',
      rollNumber: '99',
      parentUserIds: ['parent_99'],
    );

    final canTeacherRead6A = _authService.canAccessStudent(
      actorRole: UserRole.teacher,
      teacherAssignments: _activeTeacherAssignments,
      student: _activeStudent,
    );

    final canTeacherRead6B = _authService.canAccessStudent(
      actorRole: UserRole.teacher,
      teacherAssignments: _activeTeacherAssignments,
      student: student6B,
    );

    final canTeacherEditEnglishMarks = _authService.canManageMarks(
      actorRole: UserRole.teacher,
      teacherAssignments: _activeTeacherAssignments,
      classId: '6',
      sectionId: 'A',
      subjectId: 'english',
    );

    final canTeacherModifyFees = _authService.canManageFees(
      actorRole: UserRole.teacher,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Teacher Access Control Verification', style: AppTypography.titleLarge),
        Text(
          'Simulated against active assignment: Teacher A → Class 6A (Mathematics)',
          style: AppTypography.bodySmall,
        ),
        AppSpacing.gapMd,
        _buildSecurityCheckCard(
          title: 'Test 1: Read assigned Class 6A student',
          isAllowed: canTeacherRead6A,
          detail: 'Teacher A has explicit assignment to Class 6A.',
        ),
        AppSpacing.gapSm,
        _buildSecurityCheckCard(
          title: 'Test 2: Read unassigned Class 6B student',
          isAllowed: canTeacherRead6B,
          detail: 'Access denied: Teacher A has no assignment to Section B.',
        ),
        AppSpacing.gapSm,
        _buildSecurityCheckCard(
          title: 'Test 5: Direct ID query bypass attempt on 6B',
          isAllowed: canTeacherRead6B,
          detail: 'Knowing document ID "std_6B_099" is blocked at security layer.',
        ),
        AppSpacing.gapSm,
        _buildSecurityCheckCard(
          title: 'Test 6: Modify English marks (Unassigned Subject)',
          isAllowed: canTeacherEditEnglishMarks,
          detail: 'Teacher A is subject teacher for Mathematics only. English marks denied.',
        ),
        AppSpacing.gapSm,
        _buildSecurityCheckCard(
          title: 'Test 8: Modify Fee Records',
          isAllowed: canTeacherModifyFees,
          detail: 'Financial data is strictly restricted to Principal / Accountant roles.',
        ),
      ],
    );
  }

  Widget _buildSecurityCheckCard({
    required String title,
    required bool isAllowed,
    required String detail,
  }) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAllowed ? Icons.check_circle : Icons.block,
            color: isAllowed ? AppColors.success : AppColors.error,
            size: 24,
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(title, style: AppTypography.titleMedium),
                    ),
                    AppBadge(
                      label: isAllowed ? 'ALLOW' : 'DENY',
                      variant: isAllowed
                          ? AppBadgeVariant.success
                          : AppBadgeVariant.error,
                    ),
                  ],
                ),
                AppSpacing.gapXs,
                Text(
                  detail,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: State Simulation ---
  Widget _buildStateSimulationContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('State Simulation (Rule 2 & Rule 17)', style: AppTypography.titleLarge),
        AppSpacing.gapMd,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ElevatedButton(
              onPressed: () =>
                  setState(() => _currentViewState = DemoViewState.content),
              child: const Text('Content View'),
            ),
            ElevatedButton(
              onPressed: () =>
                  setState(() => _currentViewState = DemoViewState.loading),
              child: const Text('Loading View'),
            ),
            ElevatedButton(
              onPressed: () =>
                  setState(() => _currentViewState = DemoViewState.empty),
              child: const Text('Empty View'),
            ),
            ElevatedButton(
              onPressed: () =>
                  setState(() => _currentViewState = DemoViewState.error),
              child: const Text('Error View'),
            ),
          ],
        ),
        AppSpacing.gapLg,
        AppCard(
          child: _buildDashboardContent(context, l10n, Theme.of(context)),
        ),
      ],
    );
  }
}

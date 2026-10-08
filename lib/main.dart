import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/cache/cache_manager.dart';
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
import 'core/widgets/app_stat_card.dart';
import 'core/widgets/app_text_field.dart';
import 'core/widgets/responsive_layout.dart';
import 'data/repositories/firebase_attendance_repository.dart';
import 'data/repositories/firebase_fee_repository.dart';
import 'data/repositories/firebase_student_repository.dart';
import 'data/repositories/firebase_teacher_assignment_repository.dart';
import 'domain/models/attendance_record.dart';
import 'domain/models/fee_record.dart';
import 'domain/models/student.dart';
import 'domain/models/teacher_assignment.dart';
import 'domain/models/user_role.dart';
import 'domain/repositories/attendance_repository.dart';
import 'domain/repositories/fee_repository.dart';
import 'domain/repositories/student_repository.dart';
import 'domain/repositories/teacher_assignment_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Configure Firestore offline persistence (Rule 7)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('[MPS Startup] Firebase initialization warning: $e');
  }
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
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
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

class _MPSScreenState extends State<MPSScreen> {
  UserRole _selectedRole = UserRole.parent;
  int _selectedNavIndex = 0;

  // Authoritative Repositories with Scoped Caching
  final StudentRepository _studentRepository = FirebaseStudentRepository();
  final AttendanceRepository _attendanceRepository =
      FirebaseAttendanceRepository();
  final FeeRepository _feeRepository = FirebaseFeeRepository();
  final TeacherAssignmentRepository _assignmentRepository =
      FirebaseTeacherAssignmentRepository();

  // Active School ID
  static const String _schoolId = 'mps_main';
  static const String _defaultParentId = 'parent_user_01';
  static const String _defaultTeacherId = 'teacher_user_01';

  // --- Parent State ---
  List<Student> _parentStudents = [];
  Student? _selectedStudent;
  List<FeeRecord> _studentFees = [];
  List<AttendanceRecord> _studentAttendanceRecords = [];
  bool _isLoadingParent = false;
  String? _parentError;

  // --- Teacher State ---
  List<TeacherAssignment> _teacherAssignments = [];
  TeacherAssignment? _selectedAssignment;
  List<Student> _classStudents = [];
  Map<String, bool> _attendanceMap = {}; // studentId -> isPresent
  bool _isLoadingTeacher = false;
  bool _isSavingAttendance = false;
  String? _teacherError;

  // --- Principal State ---
  int? _totalStudentsCount;
  int? _activeTeacherAssignmentsCount;
  Map<String, double>? _schoolFeeMetrics;
  bool _isLoadingPrincipal = false;
  String? _principalError;

  @override
  void initState() {
    super.initState();
    _loadDataForRole(_selectedRole);
  }

  void _onRoleChanged(UserRole newRole) {
    setState(() => _selectedRole = newRole);
    _loadDataForRole(newRole);
  }

  Future<void> _loadDataForRole(UserRole role) async {
    switch (role) {
      case UserRole.parent:
        await _loadParentData();
        break;
      case UserRole.teacher:
        await _loadTeacherData();
        break;
      case UserRole.principal:
        await _loadPrincipalData();
        break;
      default:
        await _loadParentData();
    }
  }

  // ==========================================
  // REAL FIRESTORE DATA LOADERS
  // ==========================================

  Future<void> _loadParentData({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingParent = true;
      _parentError = null;
    });

    if (forceRefresh) {
      CacheManager().invalidateTag('parent_$_defaultParentId');
    }

    try {
      final studentsResult = await _studentRepository.getStudentsForParent(
        _defaultParentId,
      );

      if (studentsResult.isFailure) {
        setState(() {
          _parentError = studentsResult.errorOrNull?.message;
          _isLoadingParent = false;
        });
        return;
      }

      final students = studentsResult.dataOrNull ?? [];
      _parentStudents = students;

      if (students.isNotEmpty) {
        _selectedStudent =
            _selectedStudent != null &&
                students.any((s) => s.id == _selectedStudent!.id)
            ? _selectedStudent
            : students.first;

        await _loadStudentFinancialsAndAttendance(_selectedStudent!.id);
      } else {
        _selectedStudent = null;
        _studentFees = [];
        _studentAttendanceRecords = [];
      }
    } catch (e) {
      _parentError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoadingParent = false);
      }
    }
  }

  Future<void> _loadStudentFinancialsAndAttendance(String studentId) async {
    final feesResult = await _feeRepository.getFeesForStudent(studentId);
    final attResult = await _attendanceRepository.getStudentAttendance(
      studentId,
    );

    if (mounted) {
      setState(() {
        _studentFees = feesResult.dataOrNull ?? [];
        _studentAttendanceRecords = attResult.dataOrNull ?? [];
      });
    }
  }

  Future<void> _loadTeacherData({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingTeacher = true;
      _teacherError = null;
    });

    if (forceRefresh) {
      CacheManager().invalidateTag('teacher_$_defaultTeacherId');
    }

    try {
      final assignResult = await _assignmentRepository.getTeacherAssignments(
        _defaultTeacherId,
      );

      if (assignResult.isFailure) {
        setState(() {
          _teacherError = assignResult.errorOrNull?.message;
          _isLoadingTeacher = false;
        });
        return;
      }

      final assignments = assignResult.dataOrNull ?? [];
      _teacherAssignments = assignments;

      if (assignments.isNotEmpty) {
        _selectedAssignment =
            _selectedAssignment != null &&
                assignments.any((a) => a.id == _selectedAssignment!.id)
            ? _selectedAssignment
            : assignments.first;

        await _loadAssignedClassStudents(_selectedAssignment!);
      } else {
        _selectedAssignment = null;
        _classStudents = [];
        _attendanceMap.clear();
      }
    } catch (e) {
      _teacherError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoadingTeacher = false);
      }
    }
  }

  Future<void> _loadAssignedClassStudents(TeacherAssignment assignment) async {
    final studentsResult = await _studentRepository.getStudentsByClass(
      classId: assignment.classId,
      section: assignment.sectionId,
    );

    final students = studentsResult.dataOrNull ?? [];
    final today = DateTime.now();

    final attResult = await _attendanceRepository.getClassAttendance(
      classId: assignment.classId,
      section: assignment.sectionId,
      date: today,
    );

    final existingRecords = attResult.dataOrNull ?? [];
    final map = <String, bool>{};

    for (final s in students) {
      final record = existingRecords.firstWhere(
        (r) => r.studentId == s.id,
        orElse: () => AttendanceRecord(
          id: '',
          studentId: s.id,
          studentName: s.fullName,
          classId: s.classId,
          section: s.section,
          date: today,
          status: AttendanceStatus.present,
          markedByUserId: _defaultTeacherId,
          markedAt: today,
        ),
      );
      map[s.id] = record.isPresent;
    }

    if (mounted) {
      setState(() {
        _classStudents = students;
        _attendanceMap = map;
      });
    }
  }

  Future<void> _loadPrincipalData({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingPrincipal = true;
      _principalError = null;
    });

    if (forceRefresh) {
      CacheManager().invalidateTag('school_$_schoolId');
      CacheManager().invalidate('students:count:active');
      CacheManager().invalidate('assignments:count:2026-2027');
    }

    try {
      final stdCountRes = await _studentRepository.getTotalStudentCount();
      final assignCountRes = await _assignmentRepository
          .getActiveAssignmentCount('2026-2027');
      final feeMetricsRes = await _feeRepository.getSchoolFeeMetrics(_schoolId);

      if (mounted) {
        setState(() {
          _totalStudentsCount = stdCountRes.dataOrNull ?? 0;
          _activeTeacherAssignmentsCount = assignCountRes.dataOrNull ?? 0;
          _schoolFeeMetrics = feeMetricsRes.dataOrNull;
          _isLoadingPrincipal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _principalError = e.toString();
          _isLoadingPrincipal = false;
        });
      }
    }
  }

  // ==========================================
  // REAL FIRESTORE CRUD ACTIONS
  // ==========================================

  void _showAddStudentDialog({String? prefillClass, String? prefillSec}) {
    final nameCtrl = TextEditingController();
    final admCtrl = TextEditingController(
      text:
          'MPS-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
    final classCtrl = TextEditingController(text: prefillClass ?? '6');
    final secCtrl = TextEditingController(text: prefillSec ?? 'A');
    final rollCtrl = TextEditingController(text: '101');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enroll New Student in MPS'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Full Name', controller: nameCtrl),
              AppSpacing.gapSm,
              AppTextField(label: 'Admission Number', controller: admCtrl),
              AppSpacing.gapSm,
              Row(
                children: [
                  Expanded(
                    child: AppTextField(label: 'Class', controller: classCtrl),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(label: 'Section', controller: secCtrl),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(label: 'Roll No', controller: rollCtrl),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);

              final newStudent = Student(
                id: '',
                admissionNumber: admCtrl.text.trim(),
                fullName: nameCtrl.text.trim(),
                classId: classCtrl.text.trim(),
                section: secCtrl.text.trim().toUpperCase(),
                rollNumber: rollCtrl.text.trim(),
                parentUserIds: [_defaultParentId],
                isActive: true,
              );

              final result = await _studentRepository.createStudent(newStudent);
              if (result.isSuccess && mounted) {
                AppDialog.showAlert(
                  context: context,
                  title: 'Student Enrolled',
                  message:
                      '${newStudent.fullName} enrolled into Class ${newStudent.classId}-${newStudent.section}.',
                );
                _loadDataForRole(_selectedRole);
              }
            },
            child: const Text('Enroll Student'),
          ),
        ],
      ),
    );
  }

  void _showCreateAssignmentDialog() {
    final classCtrl = TextEditingController(text: '6');
    final secCtrl = TextEditingController(text: 'A');
    final subjectCtrl = TextEditingController(text: 'Mathematics');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Class to Teacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Class', controller: classCtrl),
            AppSpacing.gapSm,
            AppTextField(label: 'Section', controller: secCtrl),
            AppSpacing.gapSm,
            AppTextField(label: 'Subject', controller: subjectCtrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final assignment = TeacherAssignment(
                id: '',
                teacherId: _defaultTeacherId,
                academicYearId: '2026-2027',
                classId: classCtrl.text.trim(),
                sectionId: secCtrl.text.trim().toUpperCase(),
                subjectId: subjectCtrl.text.trim(),
                isClassTeacher: true,
                assignedAt: DateTime.now(),
              );

              final result = await _assignmentRepository.assignTeacher(
                assignment,
              );
              if (result.isSuccess && mounted) {
                AppDialog.showAlert(
                  context: context,
                  title: 'Assignment Created',
                  message:
                      'Teacher assigned to Class ${assignment.classId}-${assignment.sectionId} (${assignment.subjectId}).',
                );
                _loadTeacherData();
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showCreateFeeDialog(Student student) {
    final titleCtrl = TextEditingController(text: 'Term 1 Tuition Fee');
    final amountCtrl = TextEditingController(text: '12000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign Fee: ${student.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Fee Title', controller: titleCtrl),
            AppSpacing.gapSm,
            AppTextField(
              label: 'Amount (₹)',
              controller: amountCtrl,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amount <= 0) return;
              Navigator.pop(ctx);

              final fee = FeeRecord(
                id: '',
                schoolId: _schoolId,
                studentId: student.id,
                studentName: student.fullName,
                title: titleCtrl.text.trim(),
                amount: amount,
                paidAmount: 0.0,
                dueDate: DateTime.now().add(const Duration(days: 30)),
                status: PaymentStatus.unpaid,
                auditCreatedBy: 'admin_principal',
                auditCreatedAt: DateTime.now(),
              );

              final doc = FirebaseFirestore.instance.collection('fees').doc();
              await doc.set(fee.toMap());
              CacheManager().invalidate(CacheKeys.studentFees(student.id));
              CacheManager().invalidateTag('school_$_schoolId');

              if (mounted) {
                AppDialog.showAlert(
                  context: context,
                  title: 'Fee Assigned',
                  message: 'Fee record created for ₹$amount.',
                );
                _loadStudentFinancialsAndAttendance(student.id);
              }
            },
            child: const Text('Create Fee'),
          ),
        ],
      ),
    );
  }

  Future<void> _recordManualPayment(FeeRecord fee) async {
    final result = await _feeRepository.recordOfflinePayment(
      schoolId: _schoolId,
      feeRecord: fee,
      amount: fee.balanceDue,
      paymentMethod: PaymentMethod.cash,
      referenceNumber:
          'CASH-CNTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      recordedByUserId: 'fee_counter_01',
      notes: 'Fee counter cash receipt settlement',
    );

    if (result.isSuccess && mounted) {
      final payment = result.dataOrNull!;
      AppDialog.showAlert(
        context: context,
        title: 'Official Payment Recorded',
        message:
            'Payment recorded in Firestore.\n\nReceipt Number: ${payment.receiptNumber}\nAmount Paid: ₹${payment.amount}',
      );
      if (_selectedStudent != null) {
        _loadStudentFinancialsAndAttendance(_selectedStudent!.id);
      }
    } else if (mounted) {
      AppDialog.showAlert(
        context: context,
        title: 'Payment Failed',
        message: result.errorOrNull?.message ?? 'Could not record payment.',
      );
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedAssignment == null || _classStudents.isEmpty) return;

    setState(() => _isSavingAttendance = true);

    final today = DateTime.now();
    final records = _classStudents.map((s) {
      final isPresent = _attendanceMap[s.id] ?? true;
      return AttendanceRecord(
        id: '',
        studentId: s.id,
        studentName: s.fullName,
        classId: _selectedAssignment!.classId,
        section: _selectedAssignment!.sectionId,
        date: today,
        status: isPresent ? AttendanceStatus.present : AttendanceStatus.absent,
        markedByUserId: _defaultTeacherId,
        markedAt: today,
      );
    }).toList();

    final result = await _attendanceRepository.saveAttendance(
      records: records,
      teacherUserId: _defaultTeacherId,
    );

    if (mounted) {
      setState(() => _isSavingAttendance = false);
      if (result.isSuccess) {
        AppDialog.showAlert(
          context: context,
          title: 'Attendance Saved',
          message:
              'Recorded attendance for ${_classStudents.length} students in Class ${_selectedAssignment!.classId}-${_selectedAssignment!.sectionId}.',
        );
      } else {
        AppDialog.showAlert(
          context: context,
          title: 'Error Saving Attendance',
          message: result.errorOrNull?.message ?? 'Failed to write attendance.',
        );
      }
    }
  }

  // ==========================================
  // UI BUILDERS
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: ResponsiveLayout(
        mobile: (ctx) => _buildUnifiedBody(ctx, l10n, theme),
        tablet: (ctx) => Row(
          children: [
            _buildNavigationRail(l10n),
            const VerticalDivider(width: 1),
            Expanded(child: _buildUnifiedBody(ctx, l10n, theme)),
          ],
        ),
        desktop: (ctx) => Row(
          children: [
            _buildDesktopSidebar(l10n, theme),
            const VerticalDivider(width: 1),
            Expanded(child: _buildUnifiedBody(ctx, l10n, theme)),
          ],
        ),
      ),
      bottomNavigationBar: ResponsiveLayout.isMobile(context)
          ? NavigationBar(
              selectedIndex: _selectedNavIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _selectedNavIndex = idx),
              height: 60,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined, size: 20),
                  selectedIcon: const Icon(Icons.dashboard, size: 20),
                  label: l10n.translate('dashboard'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.how_to_reg_outlined, size: 20),
                  selectedIcon: const Icon(Icons.how_to_reg, size: 20),
                  label: l10n.translate('attendance'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                  selectedIcon: const Icon(Icons.receipt_long, size: 20),
                  label: l10n.translate('fees'),
                ),
              ],
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      titleSpacing: 16,
      toolbarHeight: 52,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.radiusSm,
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              l10n.translate('app_title'),
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh Firestore Data',
          icon: const Icon(Icons.refresh, size: 18),
          onPressed: () => _loadDataForRole(_selectedRole),
        ),
        IconButton(
          tooltip: widget.currentLocale.languageCode == 'en'
              ? 'Switch to Hindi'
              : 'अंग्रेजी में बदलें',
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate, size: 16),
              const SizedBox(width: 4),
              Text(
                widget.currentLocale.languageCode.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
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
            size: 18,
          ),
          onPressed: widget.onToggleTheme,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildUnifiedBody(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return RefreshIndicator(
      onRefresh: () => _loadDataForRole(_selectedRole),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ResponsivePageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoleSelectorCard(l10n),
              AppSpacing.gapMd,
              _buildRoleDashboard(context, l10n, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectorCard(AppLocalizations l10n) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            'ROLE:',
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildRoleChip(
                  UserRole.parent,
                  l10n.translate('role_parent'),
                  Icons.family_restroom,
                ),
                _buildRoleChip(
                  UserRole.teacher,
                  l10n.translate('role_teacher'),
                  Icons.person,
                ),
                _buildRoleChip(
                  UserRole.principal,
                  l10n.translate('role_principal'),
                  Icons.admin_panel_settings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      selected: isSelected,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : null,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        if (selected) _onRoleChanged(role);
      },
    );
  }

  Widget _buildRoleDashboard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
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

  // ==========================================
  // REAL PARENT VIEW
  // ==========================================
  Widget _buildParentDashboard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isLoadingParent) {
      return const AppLoadingIndicator(
        message: 'Loading verified student records...',
      );
    }

    if (_parentError != null) {
      return AppErrorState(
        title: 'Unable to Load Student Records',
        message: _parentError!,
        onRetry: () => _loadParentData(forceRefresh: true),
      );
    }

    if (_parentStudents.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          icon: Icons.person_off_outlined,
          title: 'No Linked Children Found',
          description: 'No enrolled students are currently linked to this parent account in Firestore.',
          actionLabel: 'Enroll First Student',
          onAction: () => _showAddStudentDialog(),
        ),
      );
    }

    final student = _selectedStudent ?? _parentStudents.first;
    final totalAttendance = _studentAttendanceRecords.length;
    final presentCount = _studentAttendanceRecords
        .where((r) => r.isPresent)
        .length;
    final attendanceRate = totalAttendance > 0
        ? ((presentCount / totalAttendance) * 100).toStringAsFixed(0)
        : null;

    final primaryFee = _studentFees.isNotEmpty ? _studentFees.first : null;

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
                    'Student: ${student.fullName} (${student.admissionNumber})',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Class ${student.classId}-${student.section} • Roll No: ${student.rollNumber}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),
            AppButton.outlined(
              text: 'Add Child',
              icon: Icons.add,
              isCompact: true,
              fullWidth: false,
              onPressed: () => _showAddStudentDialog(),
            ),
          ],
        ),
        AppSpacing.gapMd,
        ResponsiveGrid(
          targetItemWidth: 260.0,
          children: [
            AppStatCard(
              title: l10n.translate('attendance_rate'),
              value: attendanceRate != null
                  ? '$attendanceRate% Present'
                  : 'No records',
              icon: Icons.check_circle_outline,
              badge: totalAttendance > 0
                  ? '$presentCount / $totalAttendance Days'
                  : 'Unrecorded',
              badgeVariant: totalAttendance > 0
                  ? AppBadgeVariant.success
                  : AppBadgeVariant.info,
            ),
            AppStatCard(
              title: l10n.translate('fee_total_due'),
              value: primaryFee != null
                  ? '₹${primaryFee.balanceDue.toStringAsFixed(0)}'
                  : '₹0',
              icon: Icons.account_balance_wallet_outlined,
              badge: primaryFee != null
                  ? (primaryFee.balanceDue == 0 ? 'Settled' : 'Due')
                  : 'No Fees Assigned',
              badgeVariant: (primaryFee == null || primaryFee.balanceDue == 0)
                  ? AppBadgeVariant.success
                  : AppBadgeVariant.warning,
            ),
          ],
        ),
        AppSpacing.gapMd,
        if (primaryFee == null)
          AppCard(
            child: AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Fee Records Found',
              description:
                  'No pending fee assignments exist for ${student.fullName}.',
              actionLabel: 'Assign Fee Record',
              onAction: () => _showCreateFeeDialog(student),
            ),
          )
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.translate('fee_breakdown'),
                      style: AppTypography.titleMedium,
                    ),
                    AppBadge(
                      label: primaryFee.status == PaymentStatus.paid
                          ? l10n.translate('fee_status_paid')
                          : (primaryFee.status == PaymentStatus.partiallyPaid
                                ? 'Partially Paid'
                                : 'Unpaid'),
                      variant: primaryFee.status == PaymentStatus.paid
                          ? AppBadgeVariant.success
                          : (primaryFee.status == PaymentStatus.partiallyPaid
                                ? AppBadgeVariant.info
                                : AppBadgeVariant.error),
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                Text(
                  primaryFee.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assigned: ₹${primaryFee.amount.toStringAsFixed(0)} • Paid: ₹${primaryFee.paidAmount.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall,
                ),
                if (primaryFee.receiptNumber != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: Text(
                      'Official Receipt: ${primaryFee.receiptNumber}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSuccessContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                AppSpacing.gapMd,
                AppButton.primary(
                  text: l10n.translate('fee_record_payment'),
                  icon: Icons.receipt_long_outlined,
                  isCompact: true,
                  fullWidth: false,
                  onPressed: primaryFee.balanceDue == 0
                      ? null
                      : () => _recordManualPayment(primaryFee),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  // REAL TEACHER VIEW
  // ==========================================
  Widget _buildTeacherDashboard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isLoadingTeacher) {
      return const AppLoadingIndicator(
        message: 'Loading teacher class assignments...',
      );
    }

    if (_teacherError != null) {
      return AppErrorState(
        title: 'Unable to Load Teacher Assignments',
        message: _teacherError!,
        onRetry: () => _loadTeacherData(forceRefresh: true),
      );
    }

    if (_teacherAssignments.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          icon: Icons.assignment_late_outlined,
          title: 'No Active Class Assignments',
          description: 'You are not currently assigned to any class or subject in Firestore.',
          actionLabel: 'Create Assignment',
          onAction: () => _showCreateAssignmentDialog(),
        ),
      );
    }

    final assignment = _selectedAssignment ?? _teacherAssignments.first;

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
                    '${l10n.translate('attendance_mark')} — Assigned: Class ${assignment.classId}-${assignment.sectionId}',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Subject: ${assignment.subjectId ?? 'Class Teacher'} • Academic Year: ${assignment.academicYearId}',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),
            if (_classStudents.isNotEmpty)
              AppButton.primary(
                text: _isSavingAttendance
                    ? 'Saving...'
                    : l10n.translate('save'),
                icon: Icons.check,
                isCompact: true,
                fullWidth: false,
                onPressed: _isSavingAttendance ? null : _saveAttendance,
              ),
          ],
        ),
        AppSpacing.gapMd,
        if (_classStudents.isEmpty)
          AppCard(
            child: AppEmptyState(
              icon: Icons.group_off_outlined,
              title: 'No Students in Class',
              description:
                  'No active students found in Class ${assignment.classId}-${assignment.sectionId}.',
              actionLabel: 'Enroll Student in Class',
              onAction: () => _showAddStudentDialog(
                prefillClass: assignment.classId,
                prefillSec: assignment.sectionId,
              ),
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _classStudents.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final student = _classStudents[idx];
                final isPresent = _attendanceMap[student.id] ?? true;

                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 0,
                  ),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      student.rollNumber,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  title: Text(
                    student.fullName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Adm: ${student.admissionNumber}',
                    style: AppTypography.labelSmall.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(140),
                      fontSize: 10,
                    ),
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
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() {
                            _attendanceMap[student.id] = val;
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

  // ==========================================
  // REAL PRINCIPAL VIEW
  // ==========================================
  Widget _buildPrincipalDashboard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isLoadingPrincipal) {
      return const AppLoadingIndicator(
        message: 'Calculating aggregate school metrics...',
      );
    }

    if (_principalError != null) {
      return AppErrorState(
        title: 'Unable to Load Administrative Metrics',
        message: _principalError!,
        onRetry: () => _loadPrincipalData(forceRefresh: true),
      );
    }

    final totalCollected = _schoolFeeMetrics?['totalCollected'] ?? 0.0;
    final pendingBalance = _schoolFeeMetrics?['pendingBalance'] ?? 0.0;
    final totalStudents = _totalStudentsCount ?? 0;
    final totalAssignments = _activeTeacherAssignmentsCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MPS Administrative & Security Overview',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Authoritative Firestore academic and financial metrics',
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                AppButton.outlined(
                  text: 'Add Student',
                  icon: Icons.person_add,
                  isCompact: true,
                  fullWidth: false,
                  onPressed: () => _showAddStudentDialog(),
                ),
                AppButton.outlined(
                  text: 'Assign Teacher',
                  icon: Icons.assignment_ind,
                  isCompact: true,
                  fullWidth: false,
                  onPressed: () => _showCreateAssignmentDialog(),
                ),
              ],
            ),
          ],
        ),
        AppSpacing.gapMd,
        ResponsiveGrid(
          targetItemWidth: 240.0,
          children: [
            AppStatCard(
              title: l10n.translate('fee_total_collected'),
              value: '₹${totalCollected.toStringAsFixed(0)}',
              badge: pendingBalance > 0
                  ? '₹${pendingBalance.toStringAsFixed(0)} Due'
                  : 'All Cleared',
              badgeVariant: pendingBalance > 0
                  ? AppBadgeVariant.warning
                  : AppBadgeVariant.success,
              icon: Icons.receipt_outlined,
            ),
            AppStatCard(
              title: 'Enrolled Students',
              value: '$totalStudents Enrolled',
              badge: totalStudents > 0 ? 'Active' : 'Empty Database',
              badgeVariant: totalStudents > 0
                  ? AppBadgeVariant.success
                  : AppBadgeVariant.info,
              icon: Icons.people_outline,
            ),
            AppStatCard(
              title: 'Teacher Assignments',
              value: '$totalAssignments Verified',
              badge: 'Academic Year 26-27',
              badgeVariant: AppBadgeVariant.info,
              icon: Icons.assignment_ind_outlined,
            ),
          ],
        ),
        AppSpacing.gapMd,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Authoritative Data Architecture',
                style: AppTypography.titleMedium,
              ),
              AppSpacing.gapSm,
              Text(
                '• Firestore is the single authoritative source of truth\n'
                '• Scoped CacheManager prevents redundant reads with TTL eviction\n'
                '• Offline Persistence enabled via Firebase Firestore SDK\n'
                '• Strict Teacher Assignment boundaries enforced on attendance and marks\n'
                '• Manual Payment Provider preserves full financial audit trail',
                style: AppTypography.bodySmall.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRail(AppLocalizations l10n) {
    return NavigationRail(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (idx) => setState(() => _selectedNavIndex = idx),
      labelType: NavigationRailLabelType.selected,
      minWidth: 56,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.dashboard_outlined, size: 20),
          selectedIcon: const Icon(Icons.dashboard, size: 20),
          label: Text(l10n.translate('dashboard')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.how_to_reg_outlined, size: 20),
          selectedIcon: const Icon(Icons.how_to_reg, size: 20),
          label: Text(l10n.translate('attendance')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.receipt_long_outlined, size: 20),
          selectedIcon: const Icon(Icons.receipt_long, size: 20),
          label: Text(l10n.translate('fees')),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar(AppLocalizations l10n, ThemeData theme) {
    return SizedBox(
      width: 220,
      child: Material(
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MPS Portal',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.dashboard, size: 18),
              title: Text(
                l10n.translate('dashboard'),
                style: AppTypography.bodyMedium,
              ),
              selected: _selectedNavIndex == 0,
              onTap: () => setState(() => _selectedNavIndex = 0),
            ),
            ListTile(
              leading: const Icon(Icons.how_to_reg, size: 18),
              title: Text(
                l10n.translate('attendance'),
                style: AppTypography.bodyMedium,
              ),
              selected: _selectedNavIndex == 1,
              onTap: () => setState(() => _selectedNavIndex = 1),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, size: 18),
              title: Text(
                l10n.translate('fees'),
                style: AppTypography.bodyMedium,
              ),
              selected: _selectedNavIndex == 2,
              onTap: () => setState(() => _selectedNavIndex = 2),
            ),
          ],
        ),
      ),
    );
  }
}

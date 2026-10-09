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
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firebase_fee_repository.dart';
import 'data/repositories/firebase_student_repository.dart';
import 'data/repositories/firebase_teacher_assignment_repository.dart';
import 'domain/models/attendance_record.dart';
import 'domain/models/fee_record.dart';
import 'domain/models/student.dart';
import 'domain/models/teacher_assignment.dart';
import 'domain/models/user_profile.dart';
import 'domain/models/user_role.dart';
import 'domain/repositories/attendance_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/fee_repository.dart';
import 'domain/repositories/student_repository.dart';
import 'domain/repositories/teacher_assignment_repository.dart';
import 'firebase_options.dart';
import 'presentation/admin/staff_provisioning_screen.dart';
import 'presentation/auth/login_screen.dart';

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
  final AuthRepository? authRepository;
  final StudentRepository? studentRepository;
  final AttendanceRepository? attendanceRepository;
  final FeeRepository? feeRepository;
  final TeacherAssignmentRepository? assignmentRepository;
  final UserProfile? initialProfile;

  const MPSApp({
    super.key,
    this.authRepository,
    this.studentRepository,
    this.attendanceRepository,
    this.feeRepository,
    this.assignmentRepository,
    this.initialProfile,
  });

  @override
  State<MPSApp> createState() => _MPSAppState();
}

class _MPSAppState extends State<MPSApp> {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();

  UserProfile? _currentUserProfile;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _currentUserProfile = widget.initialProfile;
      _isCheckingAuth = false;
    } else {
      _checkInitialAuthState();
    }
  }

  Future<void> _checkInitialAuthState() async {
    try {
      final profileResult = await _authRepository.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentUserProfile = profileResult.dataOrNull;
          _isCheckingAuth = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }
  }

  void _onLoginSuccess(UserProfile profile) {
    setState(() {
      _currentUserProfile = profile;
    });
  }

  Future<void> _onSignOut() async {
    await _authRepository.signOut();
    if (mounted) {
      setState(() {
        _currentUserProfile = null;
      });
    }
  }

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
      home: _isCheckingAuth
          ? const Scaffold(
              body: Center(
                child: AppLoadingIndicator(
                  message: 'Checking authentication session...',
                ),
              ),
            )
          : _currentUserProfile == null
          ? LoginScreen(
              authRepository: _authRepository,
              onLoginSuccess: _onLoginSuccess,
              onToggleTheme: _toggleTheme,
              onToggleLocale: _toggleLocale,
              isDarkMode: _themeMode == ThemeMode.dark,
              currentLocale: _locale,
            )
          : MPSScreen(
              userProfile: _currentUserProfile!,
              authRepository: _authRepository,
              onSignOut: _onSignOut,
              onToggleTheme: _toggleTheme,
              onToggleLocale: _toggleLocale,
              isDarkMode: _themeMode == ThemeMode.dark,
              currentLocale: _locale,
              studentRepository: widget.studentRepository,
              attendanceRepository: widget.attendanceRepository,
              feeRepository: widget.feeRepository,
              assignmentRepository: widget.assignmentRepository,
            ),
    );
  }
}

class MPSScreen extends StatefulWidget {
  final UserProfile userProfile;
  final AuthRepository authRepository;
  final Future<void> Function() onSignOut;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLocale;
  final bool isDarkMode;
  final Locale currentLocale;
  final StudentRepository? studentRepository;
  final AttendanceRepository? attendanceRepository;
  final FeeRepository? feeRepository;
  final TeacherAssignmentRepository? assignmentRepository;

  const MPSScreen({
    super.key,
    required this.userProfile,
    required this.authRepository,
    required this.onSignOut,
    required this.onToggleTheme,
    required this.onToggleLocale,
    required this.isDarkMode,
    required this.currentLocale,
    this.studentRepository,
    this.attendanceRepository,
    this.feeRepository,
    this.assignmentRepository,
  });

  @override
  State<MPSScreen> createState() => _MPSScreenState();
}

class _MPSScreenState extends State<MPSScreen> {
  late UserRole _selectedRole = widget.userProfile.role;
  int _selectedNavIndex = 0;

  // Authoritative Repositories with Scoped Caching
  late final StudentRepository _studentRepository =
      widget.studentRepository ?? FirebaseStudentRepository();
  late final AttendanceRepository _attendanceRepository =
      widget.attendanceRepository ?? FirebaseAttendanceRepository();
  late final FeeRepository _feeRepository =
      widget.feeRepository ?? FirebaseFeeRepository();
  late final TeacherAssignmentRepository _assignmentRepository =
      widget.assignmentRepository ?? FirebaseTeacherAssignmentRepository();

  // Active School ID
  static const String _schoolId = 'mps_main';

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
  List<Student> _allStudents = [];
  List<TeacherAssignment> _allAssignments = [];
  List<FeeRecord> _allSchoolFees = [];
  bool _isLoadingPrincipal = false;
  String? _principalError;

  @override
  void initState() {
    super.initState();
    _loadDataForRole(_selectedRole);
  }

  void _onRoleChanged(UserRole newRole) {
    if (!widget.userProfile.role.isPrincipal) {
      // Non-principal users cannot change roles (Rule 5 & 15)
      return;
    }
    setState(() {
      _selectedRole = newRole;
      _selectedNavIndex = 0; // Reset navigation index on role switch
    });
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

    final parentId = widget.userProfile.uid;

    if (forceRefresh) {
      CacheManager().invalidateTag('parent_$parentId');
    }

    try {
      final studentsResult = await _studentRepository.getStudentsForParent(
        parentId,
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

    final teacherId = widget.userProfile.uid.isNotEmpty
        ? widget.userProfile.uid
        : widget.userProfile.phoneNumber;

    if (forceRefresh) {
      CacheManager().invalidateTag('teacher_$teacherId');
    }

    try {
      // Query assignments strictly bound to authenticated teacher (Rule 5)
      var assignResult = await _assignmentRepository.getTeacherAssignments(
        teacherId,
      );

      // If no assignments by UID, try phone number
      if ((assignResult.dataOrNull ?? []).isEmpty &&
          widget.userProfile.phoneNumber.isNotEmpty) {
        assignResult = await _assignmentRepository.getTeacherAssignments(
          widget.userProfile.phoneNumber,
        );
      }

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
          markedByUserId: widget.userProfile.uid,
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

      // Fetch directory records for Principal tabs
      final allStudentsSnap = await FirebaseFirestore.instance
          .collection('students')
          .where('isActive', isEqualTo: true)
          .get();
      final allStudents = allStudentsSnap.docs
          .map((d) => Student.fromMap(d.data(), d.id))
          .toList();

      final allAssignSnap = await FirebaseFirestore.instance
          .collection('teacherAssignments')
          .where('isActive', isEqualTo: true)
          .get();
      final allAssignments = allAssignSnap.docs
          .map((d) => TeacherAssignment.fromMap(d.data(), d.id))
          .toList();

      final allFeesSnap = await FirebaseFirestore.instance
          .collection('fees')
          .limit(50)
          .get();
      final allFees = allFeesSnap.docs
          .map((d) => FeeRecord.fromMap(d.data(), d.id))
          .toList();

      if (mounted) {
        setState(() {
          _totalStudentsCount = stdCountRes.dataOrNull ?? 0;
          _activeTeacherAssignmentsCount = assignCountRes.dataOrNull ?? 0;
          _schoolFeeMetrics = feeMetricsRes.dataOrNull;
          _allStudents = allStudents;
          _allAssignments = allAssignments;
          _allSchoolFees = allFees;
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
                parentUserIds: [widget.userProfile.uid],
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
                teacherId: widget.userProfile.uid,
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
                auditCreatedBy: widget.userProfile.uid,
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
      recordedByUserId: widget.userProfile.uid,
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
        markedByUserId: widget.userProfile.uid,
        markedAt: today,
      );
    }).toList();

    final result = await _attendanceRepository.saveAttendance(
      records: records,
      teacherUserId: widget.userProfile.uid,
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

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out of MPS'),
        content: const Text(
          'Are you sure you want to sign out? Your session and private cache will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSignOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
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
              selectedIndex: _safeNavIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _selectedNavIndex = idx),
              height: 60,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: _getDestinations(l10n),
            )
          : null,
    );
  }

  int get _destinationsCount {
    switch (_selectedRole) {
      case UserRole.parent:
        return 3;
      case UserRole.teacher:
        return 3;
      case UserRole.principal:
        return 4;
      default:
        return 3;
    }
  }

  int get _safeNavIndex {
    final count = _destinationsCount;
    return (_selectedNavIndex >= 0 && _selectedNavIndex < count)
        ? _selectedNavIndex
        : 0;
  }

  List<NavigationDestination> _getDestinations(AppLocalizations l10n) {
    switch (_selectedRole) {
      case UserRole.parent:
        return [
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
        ];
      case UserRole.teacher:
        return [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, size: 20),
            selectedIcon: Icon(Icons.dashboard, size: 20),
            label: 'Class Desk',
          ),
          NavigationDestination(
            icon: const Icon(Icons.how_to_reg_outlined, size: 20),
            selectedIcon: const Icon(Icons.how_to_reg, size: 20),
            label: l10n.translate('attendance'),
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_alt_outlined, size: 20),
            selectedIcon: Icon(Icons.people_alt, size: 20),
            label: 'Class Roster',
          ),
        ];
      case UserRole.principal:
        return [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, size: 20),
            selectedIcon: Icon(Icons.dashboard, size: 20),
            label: 'Overview',
          ),
          const NavigationDestination(
            icon: Icon(Icons.school_outlined, size: 20),
            selectedIcon: Icon(Icons.school, size: 20),
            label: 'Students',
          ),
          const NavigationDestination(
            icon: Icon(Icons.badge_outlined, size: 20),
            selectedIcon: Icon(Icons.badge, size: 20),
            label: 'Faculty',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
            selectedIcon: const Icon(Icons.account_balance_wallet, size: 20),
            label: l10n.translate('fees'),
          ),
        ];
      default:
        return [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined, size: 20),
            selectedIcon: const Icon(Icons.dashboard, size: 20),
            label: l10n.translate('dashboard'),
          ),
        ];
    }
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    String roleBadgeText;
    Color roleBadgeBg;
    Color roleBadgeFg;

    switch (_selectedRole) {
      case UserRole.parent:
        roleBadgeText = 'Parent';
        roleBadgeBg = AppColors.primaryFixed;
        roleBadgeFg = AppColors.onPrimaryFixedVariant;
        break;
      case UserRole.teacher:
        roleBadgeText = 'Teacher';
        roleBadgeBg = AppColors.surfaceContainerLow;
        roleBadgeFg = AppColors.lightTextPrimary;
        break;
      case UserRole.principal:
        roleBadgeText = 'Admin';
        roleBadgeBg = AppColors.primary;
        roleBadgeFg = Colors.white;
        break;
      default:
        roleBadgeText = _selectedRole.value;
        roleBadgeBg = AppColors.primaryFixed;
        roleBadgeFg = AppColors.onPrimaryFixedVariant;
    }

    return AppBar(
      titleSpacing: 10,
      toolbarHeight: 56,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.clayBorder),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(1, 1),
                  blurRadius: 4,
                  color: AppColors.clayShadow,
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/mps_app_icon.png',
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) =>
                  const Icon(Icons.school, color: AppColors.primary, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'MPS Portal',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: roleBadgeBg,
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Text(
                        roleBadgeText,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: roleBadgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.userProfile.fullName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface
                        .withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => _loadDataForRole(_selectedRole),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          tooltip: 'Settings & Profile',
          onSelected: (value) {
            switch (value) {
              case 'theme':
                widget.onToggleTheme();
                break;
              case 'locale':
                widget.onToggleLocale();
                break;
              case 'notifications':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No unread notifications at this time.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                break;
              case 'logout':
                _confirmSignOut();
                break;
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'info',
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userProfile.fullName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${widget.userProfile.phoneNumber} • ${roleBadgeText.toUpperCase()}',
                    style: AppTypography.labelSmall.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'theme',
              child: Row(
                children: [
                  Icon(
                    widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(widget.isDarkMode ? 'Light Mode' : 'Dark Mode'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'locale',
              child: Row(
                children: [
                  const Icon(Icons.translate, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    widget.currentLocale.languageCode == 'en'
                        ? 'Switch to हिंदी'
                        : 'Switch to English',
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'notifications',
              child: const Row(
                children: [
                  Icon(Icons.notifications_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Notifications'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: const Row(
                children: [
                  Icon(Icons.logout, size: 18, color: AppColors.error),
                  SizedBox(width: 10),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
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
              if (widget.userProfile.role.isPrincipal) ...[
                _buildRoleSelectorCard(l10n),
                AppSpacing.gapMd,
              ],
              _buildActiveTabContent(context, l10n, theme),
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
          const Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'ADMIN VIEW:',
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
                  UserRole.principal,
                  l10n.translate('role_principal'),
                  Icons.admin_panel_settings,
                ),
                _buildRoleChip(
                  UserRole.teacher,
                  l10n.translate('role_teacher'),
                  Icons.person,
                ),
                _buildRoleChip(
                  UserRole.parent,
                  l10n.translate('role_parent'),
                  Icons.family_restroom,
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

  Widget _buildActiveTabContent(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final navIdx = _safeNavIndex;
    switch (_selectedRole) {
      case UserRole.parent:
        switch (navIdx) {
          case 1:
            return _buildParentAttendanceTab(context, l10n, theme);
          case 2:
            return _buildParentFeesTab(context, l10n, theme);
          case 0:
          default:
            return _buildParentDashboard(context, l10n, theme);
        }
      case UserRole.teacher:
        switch (navIdx) {
          case 1:
            return _buildTeacherAttendanceTab(context, l10n, theme);
          case 2:
            return _buildTeacherRosterTab(context, l10n, theme);
          case 0:
          default:
            return _buildTeacherDashboard(context, l10n, theme);
        }
      case UserRole.principal:
        switch (navIdx) {
          case 1:
            return _buildPrincipalStudentsTab(context, l10n, theme);
          case 2:
            return _buildPrincipalFacultyTab(context, l10n, theme);
          case 3:
            return _buildPrincipalFinanceTab(context, l10n, theme);
          case 0:
          default:
            return _buildPrincipalDashboard(context, l10n, theme);
        }
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
        // Tactile Header Student Selector Card
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(70),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        student.fullName.isNotEmpty
                            ? student.fullName[0].toUpperCase()
                            : 'S',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                student.fullName,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed,
                                borderRadius: AppRadius.radiusPill,
                              ),
                              child: Text(
                                'ROLL #${student.rollNumber}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryDeep,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Class ${student.classId}-${student.section} • Adm: ${student.admissionNumber}',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(150),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_parentStudents.length > 1)
                    PopupMenuButton<Student>(
                      tooltip: 'Switch Child',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swap_horiz, size: 20),
                      ),
                      onSelected: (child) {
                        setState(() => _selectedStudent = child);
                        _loadStudentFinancialsAndAttendance(child.id);
                      },
                      itemBuilder: (ctx) => _parentStudents
                          .map(
                            (child) => PopupMenuItem(
                              value: child,
                              child: Text(child.fullName),
                            ),
                          )
                          .toList(),
                    ),
                  if (widget.userProfile.role.isPrincipal) ...[
                    const SizedBox(width: 6),
                    AppButton.outlined(
                      text: 'Add Child',
                      icon: Icons.add,
                      isCompact: true,
                      fullWidth: false,
                      onPressed: () => _showAddStudentDialog(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,

        // Stitch Bento Quick Metric Pods (Attendance, Due, Academic Standing)
        ResponsiveGrid(
          targetItemWidth: 220.0,
          children: [
            AppStatCard(
              title: l10n.translate('attendance_rate'),
              value: attendanceRate != null ? '$attendanceRate%' : 'No records',
              icon: Icons.calendar_today_rounded,
              badge: totalAttendance > 0
                  ? '$presentCount of $totalAttendance Days'
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
              icon: Icons.account_balance_wallet_rounded,
              badge: primaryFee != null
                  ? (primaryFee.balanceDue == 0
                        ? 'Fully Cleared'
                        : 'Payment Due')
                  : 'No Fees Assigned',
              badgeVariant: (primaryFee == null || primaryFee.balanceDue == 0)
                  ? AppBadgeVariant.success
                  : AppBadgeVariant.warning,
            ),
            AppStatCard(
              title: 'Academic Standing',
              value: 'Grade A+',
              icon: Icons.workspace_premium_rounded,
              badge: 'Term 1 Verified',
              badgeVariant: AppBadgeVariant.info,
            ),
          ],
        ),
        AppSpacing.gapMd,

        // Quick Action Tactile Strip
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Operations',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.gapSm,
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.payment_rounded,
                      label: 'Pay Fees',
                      color: AppColors.primary,
                      onTap: () {
                        if (primaryFee != null && primaryFee.balanceDue > 0) {
                          _recordManualPayment(primaryFee);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No outstanding balance for this student!',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.event_note_rounded,
                      label: 'Leave Slip',
                      color: const Color(0xFF2563EB),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Digital leave application submitted to class teacher.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.schedule_rounded,
                      label: 'Timetable',
                      color: const Color(0xFF0D9488),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Viewing timetable for Class ${student.classId}-${student.section}.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.assessment_rounded,
                      label: 'Report Card',
                      color: const Color(0xFF7C3AED),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Term report card signed by Principal.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,

        // Stitch Academic Notice Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondaryFixed,
                AppColors.surfaceContainerLowest,
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.clayBorder.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inter-House Debate Finals',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tomorrow at 10:30 AM in Main Auditorium • Parents Cordially Invited',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,

        // Fee Summary / Ledger Breakdown
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
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assigned: ₹${primaryFee.amount.toStringAsFixed(0)} • Paid: ₹${primaryFee.paidAmount.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall,
                ),
                if (primaryFee.receiptNumber != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: AppRadius.radiusPill,
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

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentAttendanceTab(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isLoadingParent) {
      return const AppLoadingIndicator(message: 'Loading attendance log...');
    }
    if (_parentStudents.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          icon: Icons.person_off_outlined,
          title: 'No Linked Children Found',
          description: 'No enrolled students linked to this account.',
        ),
      );
    }

    final student = _selectedStudent ?? _parentStudents.first;
    final totalAttendance = _studentAttendanceRecords.length;
    final presentCount = _studentAttendanceRecords
        .where((r) => r.isPresent)
        .length;
    final absentCount = totalAttendance - presentCount;
    final attendanceRate = totalAttendance > 0
        ? ((presentCount / totalAttendance) * 100).toStringAsFixed(0)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_parentStudents.length > 1) ...[
          _buildChildPickerBar(),
          AppSpacing.gapMd,
        ],
        Row(
          children: [
            Expanded(
              child: _buildAttendancePod(
                label: 'RATE',
                value: '$attendanceRate%',
                icon: Icons.pie_chart_rounded,
                color: AppColors.primary,
                bgColor: AppColors.secondaryFixed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'PRESENT',
                value: '$presentCount',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                bgColor: AppColors.successContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'ABSENT',
                value: '$absentCount',
                icon: Icons.cancel_rounded,
                color: AppColors.error,
                bgColor: AppColors.errorContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'TOTAL DAYS',
                value: '$totalAttendance',
                icon: Icons.calendar_month_rounded,
                color: theme.colorScheme.onSurface,
                bgColor: AppColors.surfaceContainerHigh,
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,
        Text(
          'Daily Attendance Records (${student.fullName})',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        AppSpacing.gapSm,
        if (_studentAttendanceRecords.isEmpty)
          AppCard(
            child: AppEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No Attendance Recorded Yet',
              description:
                  'Official attendance records for ${student.fullName} will appear here once marked by the class teacher.',
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _studentAttendanceRecords.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final record = _studentAttendanceRecords[idx];
              final dateStr =
                  '${record.date.day.toString().padLeft(2, '0')}/${record.date.month.toString().padLeft(2, '0')}/${record.date.year}';
              return AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: record.isPresent
                            ? AppColors.successContainer
                            : AppColors.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        record.isPresent ? Icons.check : Icons.close,
                        color: record.isPresent
                            ? AppColors.success
                            : AppColors.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (record.remark != null &&
                              record.remark!.isNotEmpty)
                            Text(
                              record.remark!,
                              style: AppTypography.labelSmall.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  150,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    AppBadge(
                      label: record.isPresent ? 'Present' : 'Absent',
                      variant: record.isPresent
                          ? AppBadgeVariant.success
                          : AppBadgeVariant.error,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildParentFeesTab(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isLoadingParent) {
      return const AppLoadingIndicator(message: 'Loading fee statement...');
    }
    if (_parentStudents.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          icon: Icons.person_off_outlined,
          title: 'No Linked Children Found',
          description: 'No enrolled students linked to this account.',
        ),
      );
    }

    final student = _selectedStudent ?? _parentStudents.first;
    double totalBilled = 0;
    double totalPaid = 0;
    for (final f in _studentFees) {
      totalBilled += f.amount;
      totalPaid += f.paidAmount;
    }
    final balanceDue = totalBilled - totalPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_parentStudents.length > 1) ...[
          _buildChildPickerBar(),
          AppSpacing.gapMd,
        ],
        Row(
          children: [
            Expanded(
              child: _buildAttendancePod(
                label: 'TOTAL BILLED',
                value: '₹${totalBilled.toStringAsFixed(0)}',
                icon: Icons.receipt_rounded,
                color: theme.colorScheme.onSurface,
                bgColor: AppColors.surfaceContainerHigh,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'TOTAL PAID',
                value: '₹${totalPaid.toStringAsFixed(0)}',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                bgColor: AppColors.successContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'BALANCE DUE',
                value: '₹${balanceDue.toStringAsFixed(0)}',
                icon: Icons.pending_actions_rounded,
                color: balanceDue > 0 ? AppColors.error : AppColors.success,
                bgColor: balanceDue > 0
                    ? AppColors.errorContainer
                    : AppColors.successContainer,
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondaryFixed,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.primary.withAlpha(50)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Per MPS financial policy, all fee settlements must be completed in person at the school fee counter. Online gateway payments are disabled.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        Text(
          'Fee Invoices & Statements (${student.fullName})',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        AppSpacing.gapSm,
        if (_studentFees.isEmpty)
          AppCard(
            child: AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Fee Records Found',
              description:
                  'No active fee assignments exist for ${student.fullName}.',
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _studentFees.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final fee = _studentFees[idx];
              final isPaid = fee.status == PaymentStatus.paid;
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            fee.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AppBadge(
                          label: isPaid
                              ? 'Paid'
                              : (fee.status == PaymentStatus.partiallyPaid
                                    ? 'Partially Paid'
                                    : 'Unpaid'),
                          variant: isPaid
                              ? AppBadgeVariant.success
                              : (fee.status == PaymentStatus.partiallyPaid
                                    ? AppBadgeVariant.info
                                    : AppBadgeVariant.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Assigned: ₹${fee.amount.toStringAsFixed(0)}',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Paid: ₹${fee.paidAmount.toStringAsFixed(0)}',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Due: ₹${fee.balanceDue.toStringAsFixed(0)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: fee.balanceDue > 0
                                ? AppColors.error
                                : AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (fee.receiptNumber != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          borderRadius: AppRadius.radiusPill,
                        ),
                        child: Text(
                          'Official Receipt: ${fee.receiptNumber}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSuccessContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildChildPickerBar() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.people_alt_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            'Child:',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: _parentStudents.map((child) {
                final isSelected = (_selectedStudent?.id ?? '') == child.id;
                return ChoiceChip(
                  label: Text(child.fullName),
                  selected: isSelected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedStudent = child);
                      _loadStudentFinancialsAndAttendance(child.id);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // REAL TEACHER VIEW
  // ==========================================
  Widget _buildTeacherClassHeader(
    TeacherAssignment assignment,
    ThemeData theme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SESSION ACTIVE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSuccessContainer,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      'AY ${assignment.academicYearId}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              if (_teacherAssignments.length > 1)
                PopupMenuButton<TeacherAssignment>(
                  tooltip: 'Switch Assigned Class',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Class ${assignment.classId}-${assignment.sectionId}',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                  onSelected: (asgn) {
                    setState(() {
                      _selectedAssignment = asgn;
                      _loadTeacherData();
                    });
                  },
                  itemBuilder: (ctx) => _teacherAssignments
                      .map(
                        (a) => PopupMenuItem(
                          value: a,
                          child: Text(
                            'Class ${a.classId}-${a.sectionId} (${a.subjectId ?? "Class Teacher"})',
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            'Class ${assignment.classId} • Section ${assignment.sectionId}',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Subject: ${assignment.subjectId ?? 'Class Teacher'} • Academic Year ${assignment.academicYearId}',
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

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
          actionLabel: 'Refresh Assignments',
          onAction: () => _loadTeacherData(forceRefresh: true),
        ),
      );
    }

    final assignment = _selectedAssignment ?? _teacherAssignments.first;
    final totalInClass = _classStudents.length;
    final presentCount = _classStudents
        .where((s) => (_attendanceMap[s.id] ?? true))
        .length;
    final absentCount = totalInClass - presentCount;
    final attendancePct = totalInClass > 0
        ? ((presentCount / totalInClass) * 100).toStringAsFixed(0)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeacherClassHeader(assignment, theme),
        AppSpacing.gapMd,

        // 4-Pod Attendance Bento Metrics Strip
        Row(
          children: [
            Expanded(
              child: _buildAttendancePod(
                label: 'TOTAL',
                value: '$totalInClass',
                icon: Icons.groups_rounded,
                color: theme.colorScheme.onSurface,
                bgColor: AppColors.surfaceContainerHigh,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'PRESENT',
                value: '$presentCount',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                bgColor: AppColors.successContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'ABSENT',
                value: '$absentCount',
                icon: Icons.cancel_rounded,
                color: AppColors.error,
                bgColor: AppColors.errorContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'RATE',
                value: '$attendancePct%',
                icon: Icons.pie_chart_rounded,
                color: AppColors.primary,
                bgColor: AppColors.secondaryFixed,
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,

        // Teacher Fast Navigation Actions
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedNavIndex = 1),
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.primary.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: const Icon(
                          Icons.fact_check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Take Attendance',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Open roll call & mark P/A for today',
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedNavIndex = 2),
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.clayBorder.withAlpha(50),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryFixed,
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: const Icon(
                          Icons.group_rounded,
                          color: AppColors.primaryDeep,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Class Roster',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View all $totalInClass students in this section',
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,

        // Security / Scope Notice
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.clayBorder.withAlpha(40)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Per MPS Zero-Trust Policy, you have access only to Class ${assignment.classId}-${assignment.sectionId}. Financials and other classes are restricted.',
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherAttendanceTab(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isLoadingTeacher) {
      return const AppLoadingIndicator(message: 'Loading roll call data...');
    }

    if (_teacherAssignments.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          icon: Icons.assignment_late_outlined,
          title: 'No Active Class Assignments',
          description: 'You are not assigned to any class to take attendance.',
        ),
      );
    }

    final assignment = _selectedAssignment ?? _teacherAssignments.first;
    final totalInClass = _classStudents.length;
    final presentCount = _classStudents
        .where((s) => (_attendanceMap[s.id] ?? true))
        .length;
    final absentCount = totalInClass - presentCount;
    final attendancePct = totalInClass > 0
        ? ((presentCount / totalInClass) * 100).toStringAsFixed(0)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeacherClassHeader(assignment, theme),
        AppSpacing.gapMd,

        // 4-Pod Metrics Strip
        Row(
          children: [
            Expanded(
              child: _buildAttendancePod(
                label: 'TOTAL',
                value: '$totalInClass',
                icon: Icons.groups_rounded,
                color: theme.colorScheme.onSurface,
                bgColor: AppColors.surfaceContainerHigh,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'PRESENT',
                value: '$presentCount',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                bgColor: AppColors.successContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'ABSENT',
                value: '$absentCount',
                icon: Icons.cancel_rounded,
                color: AppColors.error,
                bgColor: AppColors.errorContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendancePod(
                label: 'RATE',
                value: '$attendancePct%',
                icon: Icons.pie_chart_rounded,
                color: AppColors.primary,
                bgColor: AppColors.secondaryFixed,
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,

        // Quick Controls Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  for (final s in _classStudents) {
                    _attendanceMap[s.id] = true;
                  }
                });
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark All Present'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_classStudents.isNotEmpty)
              AppButton.primary(
                text: _isSavingAttendance ? 'Saving...' : 'Submit Attendance',
                icon: Icons.check_circle_outline,
                isCompact: true,
                fullWidth: false,
                onPressed: _isSavingAttendance ? null : _saveAttendance,
              ),
          ],
        ),
        AppSpacing.gapSm,

        // Student Roll Call List
        if (_classStudents.isEmpty)
          AppCard(
            child: AppEmptyState(
              icon: Icons.group_off_outlined,
              title: 'No Students Found',
              description:
                  'No active students found in Class ${assignment.classId}-${assignment.sectionId}.',
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _classStudents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final student = _classStudents[idx];
              final isPresent = _attendanceMap[student.id] ?? true;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isPresent
                        ? AppColors.clayBorder.withAlpha(40)
                        : AppColors.error.withAlpha(80),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.clayShadow.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isPresent
                            ? AppColors.secondaryFixed
                            : AppColors.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          student.rollNumber,
                          style: AppTypography.labelSmall.copyWith(
                            color: isPresent
                                ? AppColors.primaryDeep
                                : AppColors.error,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Adm: ${student.admissionNumber}',
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(140),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tactile P/A Segmented Selector
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _attendanceMap[student.id] = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? AppColors.success
                                    : Colors.transparent,
                                borderRadius: AppRadius.radiusPill,
                                boxShadow: isPresent
                                    ? [
                                        BoxShadow(
                                          color: AppColors.success.withAlpha(
                                            90,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'P',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isPresent
                                      ? Colors.white
                                      : theme.colorScheme.onSurface.withAlpha(
                                          130,
                                        ),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _attendanceMap[student.id] = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: !isPresent
                                    ? AppColors.error
                                    : Colors.transparent,
                                borderRadius: AppRadius.radiusPill,
                                boxShadow: !isPresent
                                    ? [
                                        BoxShadow(
                                          color: AppColors.error.withAlpha(90),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'A',
                                style: AppTypography.labelSmall.copyWith(
                                  color: !isPresent
                                      ? Colors.white
                                      : theme.colorScheme.onSurface.withAlpha(
                                          130,
                                        ),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTeacherRosterTab(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isLoadingTeacher) {
      return const AppLoadingIndicator(message: 'Loading class roster...');
    }

    if (_teacherAssignments.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          icon: Icons.assignment_late_outlined,
          title: 'No Active Class Assignments',
          description: 'You are not assigned to any class.',
        ),
      );
    }

    final assignment = _selectedAssignment ?? _teacherAssignments.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTeacherClassHeader(assignment, theme),
        AppSpacing.gapMd,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enrolled Students (${_classStudents.length})',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed,
                borderRadius: AppRadius.radiusPill,
              ),
              child: Text(
                'Class ${assignment.classId}-${assignment.sectionId}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapSm,
        if (_classStudents.isEmpty)
          AppCard(
            child: AppEmptyState(
              icon: Icons.people_outline,
              title: 'Empty Class Roster',
              description:
                  'No students currently enrolled in Class ${assignment.classId}-${assignment.sectionId}.',
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _classStudents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final student = _classStudents[idx];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.clayBorder.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          student.rollNumber,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Adm No: ${student.admissionNumber} • Class: ${student.classId}-${student.section}',
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(140),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Text(
                        'Active',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSuccessContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAttendancePod({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color.withAlpha(180),
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
        ],
      ),
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
        // Executive Desk Header Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      'ADMINISTRATIVE CONTROL',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SYSTEM HEALTHY',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSuccessContainer,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Text(
                'Executive Desk',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'MPS Institutional Oversight & Firestore Security Operations',
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              AppSpacing.gapMd,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppButton.primary(
                    text: 'Staff Directory',
                    icon: Icons.manage_accounts,
                    isCompact: true,
                    fullWidth: false,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffProvisioningScreen(
                            authRepository: widget.authRepository,
                            assignmentRepository: _assignmentRepository,
                            schoolId: _schoolId,
                            currentPrincipalUid: widget.userProfile.uid,
                          ),
                        ),
                      );
                    },
                  ),
                  AppButton.outlined(
                    text: 'Add Student',
                    icon: Icons.person_add,
                    isCompact: true,
                    fullWidth: false,
                    onPressed: () => _showAddStudentDialog(),
                  ),
                  AppButton.outlined(
                    text: 'Assign Faculty',
                    icon: Icons.assignment_ind,
                    isCompact: true,
                    fullWidth: false,
                    onPressed: () => _showCreateAssignmentDialog(),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,

        // 4-Pod Institutional Bento Grid
        ResponsiveGrid(
          targetItemWidth: 220.0,
          children: [
            AppStatCard(
              title: 'Enrolled Students',
              value: '$totalStudents',
              badge: totalStudents > 0 ? 'Active Records' : 'Empty Database',
              badgeVariant: totalStudents > 0
                  ? AppBadgeVariant.success
                  : AppBadgeVariant.info,
              icon: Icons.groups_rounded,
            ),
            AppStatCard(
              title: 'Faculty Assignments',
              value: '$totalAssignments',
              badge: 'AY 26-27 Active',
              badgeVariant: AppBadgeVariant.info,
              icon: Icons.badge_outlined,
            ),
            AppStatCard(
              title: l10n.translate('fee_total_collected'),
              value: '₹${totalCollected.toStringAsFixed(0)}',
              badge: 'Audited Offline Ledger',
              badgeVariant: AppBadgeVariant.success,
              icon: Icons.account_balance_wallet_rounded,
            ),
            AppStatCard(
              title: 'Pending Collections',
              value: '₹${pendingBalance.toStringAsFixed(0)}',
              badge: pendingBalance > 0 ? 'Recovery Active' : 'All Cleared',
              badgeVariant: pendingBalance > 0
                  ? AppBadgeVariant.warning
                  : AppBadgeVariant.success,
              icon: Icons.pending_actions_rounded,
            ),
          ],
        ),
        AppSpacing.gapMd,

        // Stitch Institutional Notice Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.secondaryFixed,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.primary.withAlpha(50)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_update_good_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zero-Trust Security & Multi-Role Active',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All role validations, teacher assignments, and manual payment audit logs are verified server-side.',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,

        // Architectural Specification Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.hub_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Authoritative System Specifications',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Text(
                '• Firestore is the single authoritative source of truth across all school tenants\n'
                '• Phone Authentication with verified OTP controls user enrollment\n'
                '• Principal directly provisions Teacher and Administrative credentials\n'
                '• Strict Teacher Assignment boundaries enforced on attendance and grading\n'
                '• Offline ManualPaymentProvider preserves non-repudiation audit trails',
                style: AppTypography.bodySmall.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrincipalStudentsTab(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isLoadingPrincipal) {
      return const AppLoadingIndicator(message: 'Loading student directory...');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      'STUDENT DIRECTORY',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  AppButton.primary(
                    text: 'Enroll Student',
                    icon: Icons.person_add,
                    isCompact: true,
                    fullWidth: false,
                    onPressed: () => _showAddStudentDialog(),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Text(
                'All Enrolled Students (${_allStudents.length})',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Authoritative student registry across all classes and sections in MPS.',
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        if (_allStudents.isEmpty)
          AppCard(
            child: AppEmptyState(
              icon: Icons.group_off_outlined,
              title: 'No Students Enrolled',
              description: 'No active student records found in Firestore.',
              actionLabel: 'Enroll First Student',
              onAction: () => _showAddStudentDialog(),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allStudents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final student = _allStudents[idx];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.clayBorder.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          student.rollNumber,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                student.fullName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: AppRadius.radiusPill,
                                ),
                                child: Text(
                                  'Class ${student.classId}-${student.section}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Adm: ${student.admissionNumber} • Roll: ${student.rollNumber}',
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(140),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Text(
                        'Active',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSuccessContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPrincipalFacultyTab(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isLoadingPrincipal) {
      return const AppLoadingIndicator(
        message: 'Loading faculty assignments...',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      'FACULTY ALLOCATIONS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      AppButton.outlined(
                        text: 'Staff Directory',
                        icon: Icons.manage_accounts,
                        isCompact: true,
                        fullWidth: false,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StaffProvisioningScreen(
                                authRepository: widget.authRepository,
                                assignmentRepository: _assignmentRepository,
                                schoolId: _schoolId,
                                currentPrincipalUid: widget.userProfile.uid,
                              ),
                            ),
                          );
                        },
                      ),
                      AppButton.primary(
                        text: 'Assign Faculty',
                        icon: Icons.assignment_ind,
                        isCompact: true,
                        fullWidth: false,
                        onPressed: () => _showCreateAssignmentDialog(),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Text(
                'Active Teaching Assignments (${_allAssignments.length})',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Controls which classes, sections, and subjects teachers can access.',
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        if (_allAssignments.isEmpty)
          AppCard(
            child: AppEmptyState(
              icon: Icons.assignment_late_outlined,
              title: 'No Faculty Assignments',
              description: 'No teacher assignments configured in Firestore.',
              actionLabel: 'Assign Faculty',
              onAction: () => _showCreateAssignmentDialog(),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allAssignments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final asgn = _allAssignments[idx];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.clayBorder.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.badge_outlined,
                          color: AppColors.primaryDeep,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Class ${asgn.classId} • Sec ${asgn.sectionId}',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryFixed,
                                  borderRadius: AppRadius.radiusPill,
                                ),
                                child: Text(
                                  'AY ${asgn.academicYearId}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primaryDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Subject: ${asgn.subjectId ?? 'Class Teacher (Full Class)'}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Teacher UID: ${asgn.teacherId}',
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(130),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Text(
                        'Authorized',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSuccessContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPrincipalFinanceTab(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isLoadingPrincipal) {
      return const AppLoadingIndicator(
        message: 'Loading school financial ledger...',
      );
    }

    final totalCollected = _schoolFeeMetrics?['totalCollected'] ?? 0.0;
    final pendingBalance = _schoolFeeMetrics?['pendingBalance'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Executive Finance Header
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryFixed,
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Text(
                  'FINANCIAL LEDGER & COLLECTIONS',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
              AppSpacing.gapSm,
              Text(
                'School Financial Operations',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Real-time collection audit and offline payment counter ledger.',
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,

        // 2-Pod Financial Metrics
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.success.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TOTAL COLLECTED',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSuccessContainer,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₹${totalCollected.toStringAsFixed(0)}',
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.onSuccessContainer,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Audited Offline Receipts',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSuccessContainer.withAlpha(180),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: pendingBalance > 0
                      ? AppColors.errorContainer
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: pendingBalance > 0
                        ? AppColors.error.withAlpha(50)
                        : AppColors.clayBorder.withAlpha(50),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pending_actions_rounded,
                          color: pendingBalance > 0
                              ? AppColors.error
                              : theme.colorScheme.onSurface,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PENDING DUES',
                          style: AppTypography.labelSmall.copyWith(
                            color: pendingBalance > 0
                                ? AppColors.error
                                : theme.colorScheme.onSurface.withAlpha(160),
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₹${pendingBalance.toStringAsFixed(0)}',
                      style: AppTypography.displaySmall.copyWith(
                        color: pendingBalance > 0
                            ? AppColors.error
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Outstanding Collections',
                      style: AppTypography.labelSmall.copyWith(
                        color: pendingBalance > 0
                            ? AppColors.error.withAlpha(180)
                            : theme.colorScheme.onSurface.withAlpha(130),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,

        // Rule 8 Policy Notice
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.clayBorder.withAlpha(40)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.point_of_sale_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Rule 8 Financial Integrity: Online payments are disabled. Use the ManualPaymentProvider to record official cash, cheque, or bank receipts.',
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,

        // Fee Ledger Records List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fee Records (${_allSchoolFees.length})',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              tooltip: 'Refresh Ledger',
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => _loadPrincipalData(forceRefresh: true),
            ),
          ],
        ),
        AppSpacing.gapSm,

        if (_allSchoolFees.isEmpty)
          AppCard(
            child: AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Fee Records',
              description: 'No student fee invoices found in Firestore.',
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allSchoolFees.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final fee = _allSchoolFees[idx];
              final isFullyPaid = fee.status == PaymentStatus.paid;
              final isPartial =
                  !isFullyPaid &&
                  (fee.status == PaymentStatus.partiallyPaid ||
                      fee.paidAmount > 0);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.clayBorder.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed,
                                borderRadius: AppRadius.radiusPill,
                              ),
                              child: Text(
                                fee.title.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryDeep,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              fee.studentName.isNotEmpty
                                  ? fee.studentName
                                  : 'Student ID: ${fee.studentId}',
                              style: AppTypography.labelSmall.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  140,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isFullyPaid
                                ? AppColors.successContainer
                                : isPartial
                                ? AppColors.secondaryFixed
                                : AppColors.errorContainer,
                            borderRadius: AppRadius.radiusPill,
                          ),
                          child: Text(
                            isFullyPaid
                                ? 'PAID'
                                : isPartial
                                ? 'PARTIAL'
                                : 'PENDING',
                            style: AppTypography.labelSmall.copyWith(
                              color: isFullyPaid
                                  ? AppColors.onSuccessContainer
                                  : isPartial
                                  ? AppColors.primaryDeep
                                  : AppColors.error,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total: ₹${fee.amount.toStringAsFixed(0)}',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Paid: ₹${fee.paidAmount.toStringAsFixed(0)} • Due: ₹${fee.balanceDue.toStringAsFixed(0)}',
                              style: AppTypography.labelSmall.copyWith(
                                color: fee.balanceDue > 0
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (fee.balanceDue > 0)
                          AppButton.primary(
                            text: 'Collect Cash',
                            icon: Icons.payments_outlined,
                            isCompact: true,
                            fullWidth: false,
                            onPressed: () => _recordManualPayment(fee),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNavigationRail(AppLocalizations l10n) {
    final destinations = _getDestinations(l10n);
    return NavigationRail(
      selectedIndex: _safeNavIndex,
      onDestinationSelected: (idx) => setState(() => _selectedNavIndex = idx),
      labelType: NavigationRailLabelType.selected,
      minWidth: 56,
      destinations: destinations.map((d) {
        return NavigationRailDestination(
          icon: d.icon,
          selectedIcon: d.selectedIcon,
          label: Text(d.label),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopSidebar(AppLocalizations l10n, ThemeData theme) {
    final destinations = _getDestinations(l10n);
    final activeIdx = _safeNavIndex;
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
            ...List.generate(destinations.length, (idx) {
              final d = destinations[idx];
              final isSelected = activeIdx == idx;
              return ListTile(
                leading: isSelected ? d.selectedIcon : d.icon,
                title: Text(
                  d.label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                selected: isSelected,
                onTap: () => setState(() => _selectedNavIndex = idx),
              );
            }),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/phone_number_formatter.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_state_views.dart';
import '../../core/widgets/app_text_field.dart';
import '../../domain/models/teacher_assignment.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/teacher_assignment_repository.dart';

/// Administrator Staff & User Provisioning Screen (Rules 6, 7, 8, 11).
class StaffProvisioningScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final TeacherAssignmentRepository assignmentRepository;
  final String schoolId;
  final String currentPrincipalUid;

  const StaffProvisioningScreen({
    super.key,
    required this.authRepository,
    required this.assignmentRepository,
    required this.schoolId,
    required this.currentPrincipalUid,
  });

  @override
  State<StaffProvisioningScreen> createState() =>
      _StaffProvisioningScreenState();
}

class _StaffProvisioningScreenState extends State<StaffProvisioningScreen> {
  List<UserProfile> _staffList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.authRepository.getSchoolStaffUsers(
      widget.schoolId,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.isSuccess) {
          _staffList = result.dataOrNull ?? [];
        } else {
          _errorMessage = result.errorOrNull?.message;
        }
      });
    }
  }

  Future<void> _toggleUserActiveStatus(
    UserProfile staff,
    bool newStatus,
  ) async {
    final result = await widget.authRepository.setUserActiveStatus(
      uid: staff.uid,
      isActive: newStatus,
      changedByUserId: widget.currentPrincipalUid,
    );

    if (result.isSuccess && mounted) {
      _loadStaff();
    } else if (mounted) {
      AppDialog.showAlert(
        context: context,
        title: 'Update Failed',
        message: result.errorOrNull?.message ?? 'Could not update user status.',
      );
    }
  }

  void _showProvisionStaffDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final staffIdCtrl = TextEditingController(
      text:
          'MPS-STF-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
    UserRole selectedRole = UserRole.teacher;

    // Teacher assignment fields
    final classCtrl = TextEditingController(text: '6');
    final secCtrl = TextEditingController(text: 'A');
    final subjectCtrl = TextEditingController(text: 'Mathematics');
    bool isClassTeacher = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Provision Staff Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(label: 'Full Name', controller: nameCtrl),
                AppSpacing.gapSm,
                AppTextField(
                  label: 'Registered Mobile Number',
                  hint: '10-digit number (e.g. 9876543210)',
                  prefixText: '+91 ',
                  keyboardType: TextInputType.phone,
                  controller: phoneCtrl,
                ),
                AppSpacing.gapSm,
                AppTextField(
                  label: 'Staff ID / Employee No',
                  controller: staffIdCtrl,
                ),
                AppSpacing.gapMd,
                Text(
                  'Assigned Role:',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<UserRole>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.teacher,
                      child: Text('Teacher'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.principal,
                      child: Text('Principal'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.vicePrincipal,
                      child: Text('Vice Principal'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.accountant,
                      child: Text('Accountant'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.feeClerk,
                      child: Text('Fee Clerk'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),
                if (selectedRole == UserRole.teacher) ...[
                  AppSpacing.gapMd,
                  const Divider(),
                  Text(
                    'Class & Subject Assignment:',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Class',
                          controller: classCtrl,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          label: 'Section',
                          controller: secCtrl,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  AppTextField(
                    label: 'Subject (e.g. Mathematics)',
                    controller: subjectCtrl,
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Is Primary Class Teacher'),
                    value: isClassTeacher,
                    onChanged: (val) {
                      setDialogState(() => isClassTeacher = val ?? false);
                    },
                  ),
                ],
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
                final normalized = PhoneNumberFormatter.normalize(
                  phoneCtrl.text.trim(),
                );
                if (nameCtrl.text.trim().isEmpty || normalized == null) {
                  return;
                }

                Navigator.pop(ctx);

                final profile = UserProfile(
                  uid: '',
                  phoneNumber: normalized,
                  fullName: nameCtrl.text.trim(),
                  role: selectedRole,
                  schoolId: widget.schoolId,
                  staffId: staffIdCtrl.text.trim(),
                  isActive: true,
                  createdAt: DateTime.now(),
                );

                final provResult = await widget.authRepository.provisionUser(
                  profile,
                );

                if (provResult.isSuccess) {
                  // If teacher, also create authoritative assignment
                  if (selectedRole == UserRole.teacher) {
                    final assignment = TeacherAssignment(
                      id: '',
                      teacherId: normalized, // Queryable by phone/uid
                      academicYearId: '2026-2027',
                      classId: classCtrl.text.trim(),
                      sectionId: secCtrl.text.trim().toUpperCase(),
                      subjectId: subjectCtrl.text.trim(),
                      isClassTeacher: isClassTeacher,
                      assignedAt: DateTime.now(),
                    );
                    await widget.assignmentRepository.assignTeacher(assignment);
                  }

                  if (mounted) {
                    AppDialog.showAlert(
                      context: context,
                      title: 'Staff Provisioned',
                      message:
                          '${profile.fullName} has been provisioned as ${profile.role.value}.\nRegistered Phone: ${PhoneNumberFormatter.formatDisplay(normalized)}',
                    );
                    _loadStaff();
                  }
                } else if (mounted) {
                  AppDialog.showAlert(
                    context: context,
                    title: 'Provisioning Failed',
                    message:
                        provResult.errorOrNull?.message ??
                        'Could not provision staff.',
                  );
                }
              },
              child: const Text('Provision Account'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & User Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaff,
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingIndicator(
              message: 'Loading school staff directory...',
            )
          : _errorMessage != null
          ? AppErrorState(message: _errorMessage!, onRetry: _loadStaff)
          : _staffList.isEmpty
          ? Center(
              child: AppEmptyState(
                icon: Icons.person_add_alt_1_outlined,
                title: 'No Staff Accounts Provisioned',
                description: 'No teacher or administrator accounts have been provisioned in MPS yet.',
                actionLabel: 'Provision First Staff Member',
                onAction: _showProvisionStaffDialog,
              ),
            )
          : ListView(
              padding: AppSpacing.paddingMd,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Authorized Staff (${_staffList.length})',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppButton.primary(
                      text: 'Add Staff Member',
                      icon: Icons.add,
                      isCompact: true,
                      fullWidth: false,
                      onPressed: _showProvisionStaffDialog,
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                ...List.generate(_staffList.length, (idx) {
                  final staff = _staffList[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: staff.isActive
                                ? AppColors.primaryContainer
                                : AppColors.errorContainer,
                            child: Icon(
                              staff.role == UserRole.principal
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              size: 18,
                              color: staff.isActive
                                  ? AppColors.primary
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      staff.fullName,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AppBadge(
                                      label: staff.role.value.toUpperCase(),
                                      variant: staff.role == UserRole.principal
                                          ? AppBadgeVariant.info
                                          : AppBadgeVariant.neutral,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Phone: ${PhoneNumberFormatter.formatDisplay(staff.phoneNumber)} ${staff.staffId != null ? "• ID: ${staff.staffId}" : ""}',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppBadge(
                                label: staff.isActive ? 'ACTIVE' : 'INACTIVE',
                                variant: staff.isActive
                                    ? AppBadgeVariant.success
                                    : AppBadgeVariant.error,
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: staff.isActive,
                                activeThumbColor: AppColors.success,
                                onChanged: (val) =>
                                    _toggleUserActiveStatus(staff, val),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

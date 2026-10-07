/// User roles conforming to Rule 5 of Antigravity Workspace Rules.
enum UserRole {
  parent('parent'),
  teacher('teacher'),
  principal('principal'),
  vicePrincipal('vicePrincipal'),
  accountant('accountant'),
  feeClerk('feeClerk'),
  officeStaff('officeStaff');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? role) {
    return UserRole.values.firstWhere(
      (r) => r.value.toLowerCase() == role?.toLowerCase(),
      orElse: () => UserRole.parent,
    );
  }

  /// Whether this role has full school administrative access (Rule 5).
  bool get isPrincipal => this == UserRole.principal;

  /// Whether this role can manage financial collections & fee verification.
  bool get canManageFees =>
      this == UserRole.principal ||
      this == UserRole.accountant ||
      this == UserRole.feeClerk;

  /// Whether this role is an academic instructor authorized for class attendance.
  bool get isTeacher => this == UserRole.teacher || this == UserRole.vicePrincipal;

  /// Whether this role is a parent/guardian.
  bool get isParent => this == UserRole.parent;
}

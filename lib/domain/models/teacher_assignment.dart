/// Authoritative Teacher Assignment entity.
/// Defines the explicit class, section, and subject boundaries for a teacher.
class TeacherAssignment {
  final String id;
  final String teacherId;
  final String academicYearId;
  final String classId;
  final String sectionId;
  final String? subjectId; // Optional if class teacher without specific subject
  final bool isClassTeacher;
  final bool isActive;
  final DateTime assignedAt;

  const TeacherAssignment({
    required this.id,
    required this.teacherId,
    required this.academicYearId,
    required this.classId,
    required this.sectionId,
    this.subjectId,
    this.isClassTeacher = false,
    this.isActive = true,
    required this.assignedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacherId': teacherId,
      'academicYearId': academicYearId,
      'classId': classId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'isClassTeacher': isClassTeacher,
      'isActive': isActive,
      'assignedAt': assignedAt.toIso8601String(),
    };
  }

  factory TeacherAssignment.fromMap(Map<String, dynamic> map, String docId) {
    return TeacherAssignment(
      id: docId,
      teacherId: map['teacherId'] as String? ?? '',
      academicYearId: map['academicYearId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      subjectId: map['subjectId'] as String?,
      isClassTeacher: map['isClassTeacher'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      assignedAt: _parseDateTime(map['assignedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      final dynamic ts = value;
      if (ts.runtimeType.toString().contains('Timestamp')) {
        return (ts as dynamic).toDate() as DateTime;
      }
    } catch (_) {}
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

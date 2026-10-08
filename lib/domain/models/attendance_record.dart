/// Attendance status.
enum AttendanceStatus {
  present('present'),
  absent('absent'),
  leave('leave');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromString(String? status) {
    return AttendanceStatus.values.firstWhere(
      (s) => s.value.toLowerCase() == status?.toLowerCase(),
      orElse: () => AttendanceStatus.present,
    );
  }
}

/// Strongly typed Attendance entity with audit traceability (Rule 9).
class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String classId;
  final String section;
  final DateTime date;
  final AttendanceStatus status;
  final String markedByUserId;
  final DateTime markedAt;
  final String? lastChangedByUserId;
  final DateTime? lastChangedAt;
  final String? remark;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.section,
    required this.date,
    required this.status,
    required this.markedByUserId,
    required this.markedAt,
    this.lastChangedByUserId,
    this.lastChangedAt,
    this.remark,
  });

  bool get isPresent => status == AttendanceStatus.present;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'section': section,
      'date': date.toIso8601String(),
      'status': status.value,
      'markedByUserId': markedByUserId,
      'markedAt': markedAt.toIso8601String(),
      'lastChangedByUserId': lastChangedByUserId,
      'lastChangedAt': lastChangedAt?.toIso8601String(),
      'remark': remark,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String docId) {
    return AttendanceRecord(
      id: docId,
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      section: map['section'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      status: AttendanceStatus.fromString(map['status'] as String?),
      markedByUserId: map['markedByUserId'] as String? ?? '',
      markedAt: DateTime.tryParse(map['markedAt'] as String? ?? '') ?? DateTime.now(),
      lastChangedByUserId: map['lastChangedByUserId'] as String?,
      lastChangedAt: map['lastChangedAt'] != null
          ? DateTime.tryParse(map['lastChangedAt'] as String)
          : null,
      remark: map['remark'] as String?,
    );
  }
}

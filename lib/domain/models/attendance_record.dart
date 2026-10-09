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
      date: _parseDateTime(map['date']) ?? DateTime.now(),
      status: AttendanceStatus.fromString(map['status'] as String?),
      markedByUserId: map['markedByUserId'] as String? ?? '',
      markedAt: _parseDateTime(map['markedAt']) ?? DateTime.now(),
      lastChangedByUserId: map['lastChangedByUserId'] as String?,
      lastChangedAt: _parseDateTime(map['lastChangedAt']),
      remark: map['remark'] as String?,
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

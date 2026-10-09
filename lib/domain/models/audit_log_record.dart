/// Immutable Audit Log Record capturing system mutations (Rule 22).
class AuditLogRecord {
  final String id;
  final String schoolId;
  final String actorUserId;
  final String actorRole;
  final String action;
  final String
  entityType; // e.g. student, attendance, mark, payment, assignment, user
  final String entityId;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const AuditLogRecord({
    required this.id,
    required this.schoolId,
    required this.actorUserId,
    required this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.metadata = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'actorUserId': actorUserId,
      'actorRole': actorRole,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLogRecord.fromMap(Map<String, dynamic> map, String docId) {
    return AuditLogRecord(
      id: docId,
      schoolId: map['schoolId'] as String? ?? '',
      actorUserId: map['actorUserId'] as String? ?? '',
      actorRole: map['actorRole'] as String? ?? '',
      action: map['action'] as String? ?? '',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
      timestamp: _parseDateTime(map['timestamp']) ?? DateTime.now(),
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

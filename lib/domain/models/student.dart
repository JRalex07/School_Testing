/// Strongly typed Student entity complying with normalized schema (Rule 7).
class Student {
  final String id;
  final String admissionNumber;
  final String fullName;
  final String classId;
  final String section;
  final String rollNumber;
  final List<String> parentUserIds;
  final String? profilePhotoUrl;
  final bool isActive;

  const Student({
    required this.id,
    required this.admissionNumber,
    required this.fullName,
    required this.classId,
    required this.section,
    required this.rollNumber,
    required this.parentUserIds,
    this.profilePhotoUrl,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'admissionNumber': admissionNumber,
      'fullName': fullName,
      'classId': classId,
      'section': section,
      'rollNumber': rollNumber,
      'parentUserIds': parentUserIds,
      'profilePhotoUrl': profilePhotoUrl,
      'isActive': isActive,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, String docId) {
    return Student(
      id: docId,
      admissionNumber: map['admissionNumber'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      section: map['section'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      parentUserIds: List<String>.from(map['parentUserIds'] as List? ?? []),
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}

import '../utils/json_utils.dart';

/// แถวของตาราง `students` (ไม่มี `auth_user_id` โดยตั้งใจ)
class Student {
  const Student({
    required this.studentId,
    required this.fullName,
    this.building,
    this.room,
    this.phone,
    this.email,
    required this.semester,
    this.verified = false,
    this.lateCount = 0,
    this.createdAt,
  });

  final String studentId;
  final String fullName;
  final String? building;
  final String? room;
  final String? phone;
  final String? email;
  final String semester;
  final bool verified;
  final int lateCount;
  final DateTime? createdAt;

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    studentId: json['student_id'] as String,
    fullName: json['full_name'] as String,
    building: json['building'] as String?,
    room: json['room'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    semester: json['semester'] as String,
    verified: (json['verified'] as bool?) ?? false,
    lateCount: (json['late_count'] as num?)?.toInt() ?? 0,
    createdAt: parseDateTimeOrNull(json['created_at']),
  );
}

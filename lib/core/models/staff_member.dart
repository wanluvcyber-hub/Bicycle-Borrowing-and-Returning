import 'app_role.dart';

/// แถวของตาราง `staff` (ป้อมรปภ.หรือผู้ดูแลระบบ)
class StaffMember {
  const StaffMember({
    required this.userId,
    required this.fullName,
    required this.role,
  });

  final String userId;
  final String fullName;
  final AppRole role; // guard หรือ admin เท่านั้น

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    userId: json['user_id'] as String,
    fullName: (json['full_name'] as String?) ?? '',
    role: AppRole.fromStaffRole(json['role'] as String),
  );
}

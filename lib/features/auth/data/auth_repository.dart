import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/staff_member.dart';
import '../../../core/models/student.dart';
import '../../../core/supabase/supabase_client.dart';

/// ตัวเรียก Supabase ของระบบล็อกอิน (แยกเป็น interface เพื่อให้เทสต์ SessionProvider ได้)
abstract class AuthRepository {
  /// id ผู้ใช้ที่ล็อกอินอยู่ตอนนี้ (null = ยังไม่ล็อกอิน)
  String? get currentUserId;

  /// ส่งค่าเมื่อ "ตัวผู้ใช้" เปลี่ยนจริงๆ (ล็อกอิน/ออก/เปลี่ยนคน) ไม่ส่งตอน token refresh
  Stream<String?> get userIdChanges;

  Future<void> signIn(String email, String password);
  Future<void> signOut();

  /// แถวของตัวเองใน `staff` (null = ไม่ใช่เจ้าหน้าที่)
  Future<StaffMember?> fetchStaff(String userId);

  /// เรียก `claim_student_profile()` · โยน `PostgrestException('not_in_dorm_list')` ถ้าไม่อยู่ในรายชื่อ
  Future<Student> claimStudent();
}

class SupabaseAuthRepository implements AuthRepository {
  @override
  String? get currentUserId => supabase.auth.currentUser?.id;

  @override
  Stream<String?> get userIdChanges => supabase.auth.onAuthStateChange
      .where(
        (s) =>
            s.event != AuthChangeEvent.tokenRefreshed &&
            s.event != AuthChangeEvent.userUpdated,
      )
      .map((s) => s.session?.user.id)
      .distinct();

  @override
  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => supabase.auth.signOut();

  @override
  Future<StaffMember?> fetchStaff(String userId) async {
    final row = await supabase
        .from('staff')
        .select('user_id, full_name, role')
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : StaffMember.fromJson(row);
  }

  @override
  Future<Student> claimStudent() async {
    final res = await supabase.rpc('claim_student_profile');
    final row = res is List ? res.first : res;
    return Student.fromJson(Map<String, dynamic>.from(row as Map));
  }
}

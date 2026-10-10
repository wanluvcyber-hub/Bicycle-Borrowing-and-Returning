import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/app_role.dart';
import '../../../core/models/staff_member.dart';
import '../../../core/models/student.dart';
import '../data/auth_repository.dart';

enum SessionStatus {
  /// กำลังเช็กเซสชัน/บทบาท
  loading,

  /// ยังไม่ล็อกอิน
  signedOut,

  /// ล็อกอินแล้วและรู้บทบาทแล้ว
  ready,

  /// ล็อกอินได้ แต่ไม่ใช่เจ้าหน้าที่และไม่อยู่ในรายชื่อหอใน
  noAccess,

  /// โหลดข้อมูลบทบาทไม่สำเร็จ (เช่น เน็ตหลุด) · ไม่ออกจากระบบให้ ให้กดลองใหม่ได้
  error,
}

/// สถานะล็อกอิน + บทบาทของผู้ใช้ทั้งแอป · router ฟังตัวนี้เพื่อ redirect
///
/// ลำดับตัดสิน: มีแถวใน `staff` → guard/admin · ไม่มี → `claim_student_profile()` → นิสิต
/// · `not_in_dorm_list` → noAccess
class SessionProvider extends ChangeNotifier {
  SessionProvider(this._repo) {
    _sub = _repo.userIdChanges.listen(_onUserChanged);
    _onUserChanged(_repo.currentUserId);
  }

  final AuthRepository _repo;
  StreamSubscription<String?>? _sub;

  SessionStatus _status = SessionStatus.loading;
  AppRole? _role;
  Student? _student;
  StaffMember? _staff;
  String? _loadError;
  String? _userId;
  int _generation = 0; // กันผลของการโหลดรอบเก่าทับรอบใหม่

  SessionStatus get status => _status;
  AppRole? get role => _role;
  Student? get student => _student;
  StaffMember? get staff => _staff;

  /// ข้อความ error ตอน status = error
  String? get loadError => _loadError;

  /// ชื่อที่ใช้ทักทาย
  String? get displayName => _student?.fullName ?? _staff?.fullName;

  /// path แรกของแต่ละบทบาท
  String? get homePath => switch (_role) {
    AppRole.student => '/borrow',
    AppRole.guard => '/guard',
    AppRole.admin => '/admin',
    null => null,
  };

  void _onUserChanged(String? userId) {
    if (userId != null && userId == _userId && _status == SessionStatus.ready) {
      return; // คนเดิมที่พร้อมแล้ว ไม่ต้องโหลดซ้ำ
    }
    _userId = userId;
    _load(userId);
  }

  Future<void> _load(String? userId) async {
    final gen = ++_generation;
    _role = null;
    _student = null;
    _staff = null;
    _loadError = null;

    if (userId == null) {
      _status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }

    _status = SessionStatus.loading;
    notifyListeners();

    try {
      final staff = await _repo.fetchStaff(userId);
      if (gen != _generation) return;
      if (staff != null) {
        _staff = staff;
        _role = staff.role;
        _status = SessionStatus.ready;
      } else {
        final student = await _repo.claimStudent();
        if (gen != _generation) return;
        _student = student;
        _role = AppRole.student;
        _status = SessionStatus.ready;
      }
    } catch (e) {
      if (gen != _generation) return;
      if (dbErrorCode(e) == 'not_in_dorm_list') {
        _status = SessionStatus.noAccess;
      } else {
        _status = SessionStatus.error;
        _loadError = errorMessage(e);
      }
    }
    notifyListeners();
  }

  /// ล็อกอินด้วยอีเมล+รหัสผ่าน · คืนข้อความ error ภาษาไทย หรือ null ถ้าสำเร็จ
  /// (ผลต่อ router มาทาง stream ของ Supabase เอง)
  Future<String?> signIn(String email, String password) async {
    try {
      await _repo.signIn(email, password);
      return null;
    } catch (e) {
      return errorMessage(e);
    }
  }

  /// ลองโหลดบทบาทใหม่ (ปุ่ม "ลองอีกครั้ง" ตอน status = error)
  Future<void> retry() => _load(_userId);

  /// ออกจากระบบ · ทุกฝั่งเรียกใช้ได้ (ดู `SignOutButton`)
  Future<void> signOut() async {
    try {
      await _repo.signOut();
    } on AuthException catch (e) {
      debugPrint('[session] signOut: ${e.message}');
    } catch (e) {
      debugPrint('[session] signOut: $e');
    }
    // แม้ออกจากระบบฝั่งเซิร์ฟเวอร์ไม่สำเร็จ ให้เคลียร์สถานะในแอปไว้ก่อน
    _onUserChanged(null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

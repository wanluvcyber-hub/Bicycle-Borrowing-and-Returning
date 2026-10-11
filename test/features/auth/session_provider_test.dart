import 'dart:async';

import 'package:bike_loan/core/models/app_role.dart';
import 'package:bike_loan/core/models/staff_member.dart';
import 'package:bike_loan/core/models/student.dart';
import 'package:bike_loan/core/router/app_router.dart';
import 'package:bike_loan/features/auth/data/auth_repository.dart';
import 'package:bike_loan/features/auth/state/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.userId});

  String? userId;
  StaffMember? staff;
  Object? claimError;
  Object? staffError;
  int claimCalls = 0;
  final _controller = StreamController<String?>.broadcast(sync: true);

  @override
  String? get currentUserId => userId;
  @override
  Stream<String?> get userIdChanges => _controller.stream;

  void emit(String? id) {
    userId = id;
    _controller.add(id);
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (password != 'pw') {
      throw const AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      );
    }
    emit('u1');
  }

  @override
  Future<void> signOut() async => emit(null);

  @override
  Future<StaffMember?> fetchStaff(String userId) async {
    if (staffError != null) throw staffError!;
    return staff;
  }

  @override
  Future<Student> claimStudent() async {
    claimCalls++;
    if (claimError != null) throw claimError!;
    return const Student(
      studentId: '66000001',
      fullName: 'นิสิต',
      phone: '0800000001',
      semester: '1/2569',
      verified: true,
    );
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('ยังไม่ล็อกอิน → signedOut', () async {
    final s = SessionProvider(FakeAuthRepository());
    await settle();
    expect(s.status, SessionStatus.signedOut);
    expect(redirectFor(s, '/borrow'), '/login');
    expect(redirectFor(s, '/login'), isNull);
  });

  test('มีแถวใน staff → เป็นเจ้าหน้าที่ ไม่เรียก claim', () async {
    final repo = FakeAuthRepository(userId: 'u1')
      ..staff = const StaffMember(
        userId: 'u1',
        fullName: 'ยาม',
        role: AppRole.guard,
      );
    final s = SessionProvider(repo);
    await settle();
    expect(s.status, SessionStatus.ready);
    expect(s.role, AppRole.guard);
    expect(s.homePath, '/guard');
    expect(repo.claimCalls, 0);
  });

  test('ไม่ใช่เจ้าหน้าที่ → claim เป็นนิสิต', () async {
    final repo = FakeAuthRepository(userId: 'u1');
    final s = SessionProvider(repo);
    await settle();
    expect(s.role, AppRole.student);
    expect(s.student!.studentId, '66000001');
    expect(s.displayName, 'นิสิต');
  });

  test('not_in_dorm_list → noAccess', () async {
    final repo = FakeAuthRepository(userId: 'u1')
      ..claimError = PostgrestException(message: 'not_in_dorm_list');
    final s = SessionProvider(repo);
    await settle();
    expect(s.status, SessionStatus.noAccess);
    expect(s.role, isNull);
    expect(redirectFor(s, '/borrow'), '/no-access');
  });

  test('เน็ตหลุดตอนโหลดบทบาท → error ไม่ออกจากระบบ แล้ว retry ได้', () async {
    final repo = FakeAuthRepository(userId: 'u1')
      ..claimError = StateError('offline');
    final s = SessionProvider(repo);
    await settle();
    expect(s.status, SessionStatus.error);
    expect(s.loadError, isNotNull);
    expect(redirectFor(s, '/login'), '/splash');

    repo.claimError = null;
    await s.retry();
    expect(s.status, SessionStatus.ready);
  });

  test('signIn สำเร็จ/ผิด และ signOut', () async {
    final repo = FakeAuthRepository();
    final s = SessionProvider(repo);
    await settle();

    expect(await s.signIn('a@b.c', 'wrong'), 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    expect(s.status, SessionStatus.signedOut);

    expect(await s.signIn('a@b.c', 'pw'), isNull);
    await settle();
    expect(s.status, SessionStatus.ready);

    await s.signOut();
    expect(s.status, SessionStatus.signedOut);
    expect(s.student, isNull);
  });

  test('ผู้ใช้คนเดิมส่งสัญญาณซ้ำ ไม่โหลดซ้ำ', () async {
    final repo = FakeAuthRepository(userId: 'u1');
    final s = SessionProvider(repo);
    await settle();
    expect(repo.claimCalls, 1);
    repo.emit('u1');
    await settle();
    expect(repo.claimCalls, 1);
    expect(s.status, SessionStatus.ready);
  });

  test('redirect ตามบทบาท', () async {
    final repo = FakeAuthRepository(userId: 'u1')
      ..staff = const StaffMember(
        userId: 'u1',
        fullName: 'แอดมิน',
        role: AppRole.admin,
      );
    final s = SessionProvider(repo);
    await settle();
    expect(redirectFor(s, '/splash'), '/admin');
    expect(redirectFor(s, '/login'), '/admin');
    expect(redirectFor(s, '/borrow'), '/admin');
    expect(redirectFor(s, '/guard/x'), '/admin');
    expect(redirectFor(s, '/admin'), isNull);
    expect(redirectFor(s, '/admin/anything'), isNull);
    expect(redirectFor(s, '/administrator'), '/admin');
  });
}

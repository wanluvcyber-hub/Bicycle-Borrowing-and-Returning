import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'borrow_error.dart';
import 'borrow_models.dart';

/// จุดเดียวที่แอปนิสิตคุยกับฐานข้อมูล (docs/database.md หัวข้อ 4.2, 4.3, 4.7, 11)
abstract class BorrowRepository {
  /// ข้อมูลของนิสิตที่ล็อกอินอยู่ (null = ยังไม่ผูกบัญชี)
  Future<StudentProfile?> fetchMyProfile();

  /// รายการยืมค้างของตัวเอง พร้อมรหัสล็อก (null = ไม่มี) เรียกตอนเปิดแอปทุกครั้ง
  Future<MyLoan?> getMyActiveLoan();

  /// ยืมด้วยค่าที่ได้จาก QR · โยน error รหัสตามหัวข้อ 5
  Future<MyLoan> borrowBike(String qrCode);

  /// แก้เบอร์มือถือของตัวเอง · คืนเบอร์ที่บันทึกจริง (ตัดขีด/ช่องว่างแล้ว)
  /// โยน `invalid_phone` ถ้าไม่ใช่เบอร์ 10 หลักขึ้นต้นด้วย 0
  Future<String> updateMyPhone(String phone);

  /// รายการจักรยานทั้งหมดแบบสด (ส่งค่าแรกทันที แล้วส่งใหม่ทุกครั้งที่มีคนยืม/คืน)
  Stream<List<BorrowBike>> watchBikes();
}

class SupabaseBorrowRepository implements BorrowRepository {
  SupabaseBorrowRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<StudentProfile?> fetchMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('students')
        .select('student_id, full_name, building, room, phone')
        .eq('auth_user_id', userId)
        .maybeSingle();
    return row == null ? null : StudentProfile.fromJson(row);
  }

  @override
  Future<MyLoan?> getMyActiveLoan() async {
    final res = await _client.rpc('get_my_active_loan');
    return res == null ? null : MyLoan.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<MyLoan> borrowBike(String qrCode) async {
    final res = await _client.rpc('borrow_bike', params: {'p_qr_code': qrCode});
    return MyLoan.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<String> updateMyPhone(String phone) async {
    final res = await _client.rpc('update_my_phone', params: {'p_phone': phone});
    return res as String;
  }

  @override
  Stream<List<BorrowBike>> watchBikes() => _client
      .from('bikes')
      .stream(primaryKey: ['bike_no'])
      .order('bike_no')
      .map((rows) => [for (final row in rows) BorrowBike.fromJson(row)]);
}

/// ข้อมูลปลอมไว้ทำ UI และเทสต์ ไม่ต้องต่อ Supabase
/// ทำงานเหมือน borrow_bike จริง: โยน BorrowException ด้วยรหัสเดียวกับฐานข้อมูล
class FakeBorrowRepository implements BorrowRepository {
  FakeBorrowRepository({
    this.profile = const StudentProfile(
      studentId: '66000001',
      fullName: 'สมชาย ใจดี',
      building: 'อาคาร A',
      room: '101',
      phone: '0800000001',
    ),
    this.afterHours = false,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    for (var i = 1; i <= 10; i++) {
      final no = 'B${i.toString().padLeft(2, '0')}';
      _bikes[no] = BorrowBike(
        bikeNo: no,
        status: BikeAvailability.available,
        station: 'ป้อมรปภ.',
      );
      _locks[no] = '${i.toString().padLeft(2, '0')}11';
    }
    _bikes['B02'] = const BorrowBike(
        bikeNo: 'B02', status: BikeAvailability.borrowed, station: 'ป้อมรปภ.');
    _bikes['B05'] = const BorrowBike(
        bikeNo: 'B05', status: BikeAvailability.broken, station: 'ป้อมรปภ.');
  }

  StudentProfile? profile;

  /// จำลองยืมหลัง 21.00 น.
  bool afterHours;

  /// จำลองเน็ตหลุดหลังเซิร์ฟเวอร์สร้างรายการแล้ว (แอปไม่ได้รับคำตอบ)
  bool dropNextBorrowResponse = false;

  /// จำลองเน็ตหลุดก่อนถึงเซิร์ฟเวอร์ (ยังไม่มีรายการเกิดขึ้น)
  bool failNextBorrowBeforeServer = false;

  int borrowCalls = 0;

  /// จำลองเน็ตหลุดตอนบันทึกเบอร์โทร
  bool failNextPhoneUpdate = false;

  int phoneUpdateCalls = 0;

  final DateTime Function() _clock;
  final _bikes = <String, BorrowBike>{};
  final _locks = <String, String>{};
  final _controller = StreamController<List<BorrowBike>>.broadcast();
  MyLoan? _myLoan;
  var _nextLoanId = 1;

  List<BorrowBike> get _snapshot => _bikes.values.toList();

  /// จำลองคนอื่นยืม/คืนคันนี้จากอีกเครื่อง
  void setBikeStatus(String bikeNo, BikeAvailability status) {
    final b = _bikes[bikeNo]!;
    _bikes[bikeNo] =
        BorrowBike(bikeNo: bikeNo, status: status, station: b.station);
    _controller.add(_snapshot);
  }

  /// จำลองป้อมรปภ.รับคืนรายการของเรา
  void returnMyLoan() {
    final loan = _myLoan;
    if (loan == null) return;
    _myLoan = null;
    setBikeStatus(loan.bikeNo, BikeAvailability.available);
  }

  @override
  Future<StudentProfile?> fetchMyProfile() async => profile;

  @override
  Future<MyLoan?> getMyActiveLoan() async => _myLoan;

  @override
  Future<MyLoan> borrowBike(String qrCode) async {
    borrowCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (failNextBorrowBeforeServer) {
      failNextBorrowBeforeServer = false;
      throw const _FakeNetworkError();
    }
    if (profile == null) throw const BorrowException('not_verified');
    if (_myLoan != null) throw const BorrowException('already_borrowing');
    final bike = _bikes[qrCode];
    if (bike == null) throw const BorrowException('bike_not_found');
    if (bike.status != BikeAvailability.available) {
      throw const BorrowException('bike_not_available');
    }
    if (afterHours) throw const BorrowException('after_hours');

    final now = _clock();
    final loan = MyLoan(
      loanId: _nextLoanId++,
      bikeNo: bike.bikeNo,
      lockCode: _locks[bike.bikeNo],
      borrowedAt: now,
      dueAt: DateTime(now.year, now.month, now.day, 21),
    );
    _myLoan = loan;
    setBikeStatus(bike.bikeNo, BikeAvailability.borrowed);
    if (dropNextBorrowResponse) {
      dropNextBorrowResponse = false;
      throw const _FakeNetworkError();
    }
    return loan;
  }

  @override
  Future<String> updateMyPhone(String phone) async {
    phoneUpdateCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (failNextPhoneUpdate) {
      failNextPhoneUpdate = false;
      throw const _FakeNetworkError();
    }
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(cleaned)) {
      throw const BorrowException('invalid_phone');
    }
    final current = profile;
    if (current == null) throw const BorrowException('not_verified');
    profile = current.withPhone(cleaned);
    return cleaned;
  }

  @override
  Stream<List<BorrowBike>> watchBikes() async* {
    yield _snapshot;
    yield* _controller.stream;
  }
}

class _FakeNetworkError implements Exception {
  const _FakeNetworkError();
}

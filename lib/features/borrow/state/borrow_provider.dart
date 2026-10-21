import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/borrow_error.dart';
import '../data/borrow_models.dart';
import '../data/borrow_repository.dart';

class BorrowProvider extends ChangeNotifier {
  /// [onBorrowed] = จุดเรียก "ตั้งเตือน 20.30 / 20.50" ของคนที่ 4 ตอนยืมสำเร็จ
  /// (ยังไม่ได้ตกลงชื่อฟังก์ชันกับคนที่ 4 · ส่ง `dueAt` ไปให้ ดู docs/person-2-borrow.md ข้อ 2)
  BorrowProvider(
    this._repo, {
    this.onBorrowed,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final BorrowRepository _repo;
  final void Function(MyLoan loan)? onBorrowed;
  final DateTime Function() _clock;
  StreamSubscription<List<BorrowBike>>? _bikesSub;
  var _disposed = false;

  DateTime get now => _clock();

  // ---------- ข้อมูลหลัก ----------
  StudentProfile? _profile;
  MyLoan? _myLoan;
  List<BorrowBike> _bikes = const [];
  bool _loading = false;
  bool _loadedOnce = false;
  String? _loadError;

  StudentProfile? get profile => _profile;
  MyLoan? get myLoan => _myLoan;
  bool get hasActiveLoan => _myLoan != null;
  List<BorrowBike> get bikes => _bikes;
  List<BorrowBike> get availableBikes =>
      _bikes.where((b) => b.status == BikeAvailability.available).toList();
  bool get loading => _loading;
  bool get loadedOnce => _loadedOnce;
  String? get loadError => _loadError;

  /// เปิดหน้าหลัก: ดึงข้อมูลตัวเอง + รายการยืมค้าง (ถ้าปิดแอปไปแล้วเปิดใหม่ ต้องยังเห็นรหัสล็อก)
  /// แล้วฟังรายการจักรยานแบบสด
  Future<void> start() async {
    await refreshAll();
    _bikesSub ??= _repo.watchBikes().listen(
      (bikes) {
        _bikes = bikes;
        _notify();
        // มีรายการค้างอยู่แล้วจักรยานเปลี่ยนสถานะ = อาจถูกรับคืนแล้ว ให้เช็กใหม่
        if (_myLoan != null && !_borrowing) reloadActiveLoan();
      },
      onError: (Object e) {
        _loadError = borrowErrorMessage(e);
        _notify();
      },
    );
  }

  Future<void> refreshAll() async {
    _loading = true;
    _loadError = null;
    _notify();
    try {
      _profile = await _repo.fetchMyProfile();
      _myLoan = await _repo.getMyActiveLoan();
      _loadedOnce = true;
    } catch (e) {
      _loadError = borrowErrorMessage(e);
    } finally {
      _loading = false;
      _notify();
    }
  }

  // ---------- ยืม ----------
  bool _borrowing = false;
  String? _borrowError;

  bool get borrowing => _borrowing;
  String? get borrowError => _borrowError;

  static String normalizeQr(String input) => input.trim();

  void clearBorrowError() {
    _borrowError = null;
    _notify();
  }

  /// ยืนยันการยืม · ล็อกไว้ระหว่างรอ กดรัวๆ ก็ส่งคำขอเดียว
  Future<BorrowOutcome> confirmBorrow(String qrInput) async {
    final qr = normalizeQr(qrInput);
    if (_borrowing) return BorrowOutcome.failed;
    if (qr.isEmpty) {
      _borrowError = borrowErrorMessage(const BorrowException('bike_not_found'));
      _notify();
      return BorrowOutcome.failed;
    }
    _borrowing = true;
    _borrowError = null;
    _notify();
    try {
      _myLoan = await _repo.borrowBike(qr);
      _runOnBorrowed(_myLoan!);
      return BorrowOutcome.success;
    } catch (e) {
      if (isServerReply(e)) {
        _borrowError = borrowErrorMessage(e);
        // ถ้าฐานข้อมูลบอกว่ามีรายการค้างอยู่ ดึงมาแสดงให้ตรงกับความจริง
        if (errorCodeOf(e) == 'already_borrowing') {
          await _syncActiveLoan();
        }
        return BorrowOutcome.failed;
      }
      // เน็ตหลุด: รายการอาจถูกสร้างไปแล้วทั้งที่แอปไม่ได้รับคำตอบ ต้องเช็กก่อนให้ลองใหม่
      final found = await _syncActiveLoan();
      if (found != null) {
        _runOnBorrowed(found);
        return BorrowOutcome.success;
      }
      _borrowError = borrowErrorMessage(e);
      return BorrowOutcome.failed;
    } finally {
      _borrowing = false;
      _notify();
    }
  }

  Future<MyLoan?> _syncActiveLoan() async {
    try {
      _myLoan = await _repo.getMyActiveLoan();
      return _myLoan;
    } catch (_) {
      return null;
    }
  }

  void _runOnBorrowed(MyLoan loan) {
    try {
      onBorrowed?.call(loan);
    } catch (_) {
      // การตั้งเตือนล้มเหลวต้องไม่ทำให้การยืมที่สำเร็จแล้วดูเหมือนล้มเหลว
    }
  }

  /// เรียกเมื่อกลับมาที่หน้าหลัก หรือเมื่อรายการค้างหายไป (ป้อมรปภ.รับคืนแล้ว)
  Future<void> reloadActiveLoan() async {
    await _syncActiveLoan();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _bikesSub?.cancel();
    super.dispose();
  }
}

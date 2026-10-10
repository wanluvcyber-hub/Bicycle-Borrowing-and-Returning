import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/bike.dart';
import '../data/admin_repository.dart';

/// ข้อมูลจักรยาน+รหัสล็อก ใช้ร่วมกันใน 3 แท็บ (จักรยาน / รหัสล็อก / งานซ่อม)
/// เมธอดที่แก้ข้อมูลคืนข้อความ error ภาษาไทย หรือ null ถ้าสำเร็จ
class AdminBikesProvider extends ChangeNotifier {
  AdminBikesProvider(this._repo);
  final AdminRepository _repo;

  List<AdminBike> _bikes = const [];
  bool _loading = false;
  String? _loadError;

  List<AdminBike> get bikes => _bikes;
  bool get loading => _loading;
  String? get loadError => _loadError;
  List<AdminBike> get broken =>
      _bikes.where((b) => b.bike.status == BikeStatus.broken).toList();

  Future<void> load() async {
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      _bikes = await _repo.fetchBikes();
    } catch (e) {
      _loadError = errorMessage(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> _run(
    Future<void> Function() action, {
    String? duplicateMessage,
  }) async {
    try {
      await action();
    } catch (e) {
      if (duplicateMessage != null &&
          e is PostgrestException &&
          e.code == '23505') {
        return duplicateMessage;
      }
      return errorMessage(e);
    }
    await load();
    return null;
  }

  Future<String?> addBike({
    required String bikeNo,
    String? station,
    required String lockCode,
  }) {
    final no = bikeNo.trim();
    final lock = lockCode.trim();
    if (no.isEmpty || no.contains(RegExp(r'\s'))) {
      return Future.value('เลขคันต้องไม่ว่างและไม่มีช่องว่าง');
    }
    final lockError = validateLockCode(lock);
    if (lockError != null) return Future.value(lockError);
    return _run(
      () => _repo.addBike(
        bikeNo: no,
        station: _blankToNull(station),
        lockCode: lock,
      ),
      duplicateMessage: 'มีจักรยานเลขคัน $no อยู่แล้ว',
    );
  }

  Future<String?> updateStation(String bikeNo, String? station) =>
      _run(() => _repo.updateStation(bikeNo, _blankToNull(station)));

  Future<String?> setLockCode(String bikeNo, String lockCode) {
    final lock = lockCode.trim();
    final error = validateLockCode(lock);
    if (error != null) return Future.value(error);
    return _run(() => _repo.setLockCode(bikeNo, lock));
  }

  Future<String?> markRepaired(String bikeNo) =>
      _run(() => _repo.markRepaired(bikeNo));

  static String? _blankToNull(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// รหัสล็อกต้องไม่ว่าง ไม่มีช่องว่าง ยาวไม่เกิน 10 ตัว
  static String? validateLockCode(String code) {
    if (code.isEmpty) return 'กรอกรหัสล็อก';
    if (code.contains(RegExp(r'\s'))) return 'รหัสล็อกต้องไม่มีช่องว่าง';
    if (code.length > 10) return 'รหัสล็อกยาวเกิน 10 ตัว';
    return null;
  }
}

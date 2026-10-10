import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/loan.dart';
import '../data/active_loan_source.dart';
import '../data/reminder_service.dart';

/// ถือ "รายการยืมที่ค้างอยู่" ของนิสิต + ตั้ง/ยกเลิกเตือนให้ตรงกับเซิร์ฟเวอร์
///
/// ข้อมูลจริงอยู่ที่เซิร์ฟเวอร์เสมอ (`get_my_active_loan`) ปิดแอปแล้วเปิดใหม่จึงเห็นเวลาเดิม
/// ไม่ต้องเก็บอะไรลงเครื่อง (โดยเฉพาะรหัสล็อก)
class ReminderProvider extends ChangeNotifier {
  ReminderProvider(this._source, this._service);

  final ActiveLoanSource _source;
  final ReminderService _service;

  ActiveLoan? _loan;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  int _generation = 0; // กันผลของรอบเก่าทับรอบใหม่

  /// รายการที่ยืมค้างอยู่ (null = ไม่มี หรือยังไม่โหลด ดู [loaded])
  ActiveLoan? get loan => _loan;
  bool get loading => _loading;

  /// โหลดสำเร็จอย่างน้อยหนึ่งครั้งแล้ว (ใช้แยก "ยังไม่รู้" ออกจาก "ไม่ได้ยืม")
  bool get loaded => _loaded;

  /// ข้อความ error ภาษาไทย (เน็ตหลุด ฯลฯ) · ยังโชว์ [loan] เดิมต่อได้
  String? get error => _error;

  /// เรียกตอนเปิดหน้าหลักนิสิต และทุกครั้งที่แอปกลับมาจากพื้นหลัง
  Future<void> refresh() async {
    final gen = ++_generation;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final loan = await _service.syncWithServer(_source);
      if (gen != _generation) return;
      _loan = loan;
      _loaded = true;
    } catch (e) {
      if (gen != _generation) return;
      _error = errorMessage(e);
    }
    _loading = false;
    notifyListeners();
  }

  /// คนที่ 2 เรียกหลัง `borrow_bike` สำเร็จ: ตั้งเตือนและโชว์นับถอยหลังทันที ไม่ต้องรอโหลดใหม่
  Future<void> startLoan(ActiveLoan loan) async {
    _generation++;
    _loan = loan;
    _loaded = true;
    _error = null;
    _loading = false;
    notifyListeners();
    try {
      await _service.scheduleForLoan(bikeNo: loan.bikeNo, dueAt: loan.dueAt);
      await _service.askExactAlarmIfNeeded();
    } catch (e) {
      // ตั้งเตือนไม่สำเร็จ (เช่น ไม่ได้สิทธิ์) ต้องไม่ทำให้การยืมที่สำเร็จแล้วดูเหมือนล้มเหลว
      debugPrint('[reminder] ตั้งเตือนไม่สำเร็จ: ${e.runtimeType}');
    }
  }

  /// ทางลัดสำหรับฟีเจอร์ยืม (ที่ไม่ได้ใช้ [ActiveLoan] ของ core) ให้ส่งแค่ข้อมูลที่จำเป็น
  /// ไม่รับรหัสล็อก เพื่อไม่ให้รหัสล็อกวิ่งมาถึงส่วนแจ้งเตือนโดยไม่จำเป็น
  Future<void> onLoanStarted({
    required int loanId,
    required String bikeNo,
    required DateTime borrowedAt,
    required DateTime dueAt,
  }) => startLoan(
    ActiveLoan(
      loanId: loanId,
      bikeNo: bikeNo,
      lockCode: '',
      borrowedAt: borrowedAt,
      dueAt: dueAt,
    ),
  );

  /// ล้างตอนออกจากระบบ (กันเตือนของคนเก่าโผล่ให้คนใหม่)
  Future<void> clear() async {
    _generation++;
    _loan = null;
    _loaded = false;
    _error = null;
    _loading = false;
    notifyListeners();
    await _service.cancelAll();
  }
}

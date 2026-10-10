import 'package:flutter/foundation.dart';

import '../../../core/models/loan.dart';
import 'active_loan_source.dart';
import 'notification_gateway.dart';
import 'reminder_schedule.dart';

/// ตั้ง/ยกเลิกแจ้งเตือนเวลาคืนของรายการยืม
///
/// คนที่ 2 เรียก `ReminderService.instance.scheduleForLoan(...)` หลัง `borrow_bike` สำเร็จ
/// ฝั่งแอปเรียก `syncWithServer()` ตอนเปิดแอป/กลับมาจากพื้นหลัง (ดู `ReminderProvider`)
class ReminderService {
  ReminderService(this._gateway, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// ตัวที่ใช้จริงในแอป
  static final ReminderService instance = ReminderService(
    LocalNotificationGateway(),
  );

  final NotificationGateway _gateway;
  final DateTime Function() _now;

  Future<void> init() => _gateway.init();

  /// ตั้งเตือนของรายการยืมนี้ · เรียกซ้ำได้ (ล้างของเดิมก่อนแล้วตั้งใหม่ ไม่เกิดซ้อน)
  ///
  /// - เตือนที่ 30 และ 10 นาทีก่อน [dueAt] (อันที่เวลาผ่านไปแล้วจะข้าม)
  /// - แถบนับถอยหลังค้างในแถบแจ้งเตือน จนถึง [dueAt]
  /// - เด้ง "เกินเวลา" ตอนถึง [dueAt]
  ///
  /// [bikeNo] ใช้ในข้อความเท่านั้น **ห้ามใส่รหัสล็อก** เพราะแจ้งเตือนโผล่บนหน้าจอล็อกได้
  Future<void> scheduleForLoan({
    required String bikeNo,
    required DateTime dueAt,
  }) async {
    final now = _now();
    final clock = formatThaiClock(dueAt);

    if (!dueAt.isAfter(now)) {
      // เลยกำหนดไปแล้ว (เช่น ลืมคืนแล้วเปิดแอปทีหลัง): เหลือแค่แสดงสถานะ "เกินเวลา" แบบเงียบ
      // ไม่ยกเลิก/ตั้งเสียงเตือนใหม่ ไม่งั้นจะเด้งซ้ำทุกครั้งที่เปิดแอป
      await _cancelExcept(kOverdueNotificationId);
      await _gateway.showOverdueStatus(
        id: kOverdueNotificationId,
        title: 'เกินเวลาคืนจักรยานแล้ว',
        body: 'จักรยาน $bikeNo เลยกำหนด $clock น. กรุณาคืนที่ป้อมยามโดยเร็ว',
      );
      return;
    }

    await cancelAll();

    await _gateway.showCountdown(
      id: kCountdownNotificationId,
      title: 'กำลังยืมจักรยาน $bikeNo',
      body: 'คืนภายใน $clock น.',
      countdownTo: dueAt,
    );

    for (final slot in planReminders(dueAt, now)) {
      await _gateway.schedule(
        id: slot.id,
        at: slot.fireAt,
        urgent: slot.isUrgent,
        title: slot.isUrgent
            ? 'ใกล้ถึงเวลาคืนแล้ว!'
            : 'เตือนคืนจักรยาน $bikeNo',
        body:
            'เหลืออีก ${slot.minutesBefore} นาที '
            'กรุณาคืนจักรยาน $bikeNo ที่ป้อมยามก่อน $clock น.',
      );
    }

    await _gateway.schedule(
      id: kOverdueNotificationId,
      at: dueAt,
      urgent: true,
      title: 'เกินเวลาคืนจักรยานแล้ว',
      body: 'จักรยาน $bikeNo เลยกำหนด $clock น. กรุณาคืนที่ป้อมยามโดยเร็ว',
    );
  }

  /// ยกเลิกทุกอย่างของฟีเจอร์นี้ (ไม่แตะแจ้งเตือนของฟีเจอร์อื่น)
  Future<void> cancelAll() => _cancelExcept(null);

  Future<void> _cancelExcept(int? keepId) async {
    for (final id in kAllReminderNotificationIds) {
      if (id != keepId) await _gateway.cancel(id);
    }
  }

  bool _askedExactAlarm = false;

  /// ถ้าเครื่องยังไม่อนุญาต exact alarm ให้เปิดหน้าตั้งค่าของระบบ (ขอแค่ครั้งเดียวต่อการเปิดแอป)
  /// เรียกตอนยืมสำเร็จ ไม่ใช่ตอนซิงก์ เพื่อไม่ให้ถามซ้ำทุกครั้งที่เปิดแอป
  /// พอผู้ใช้กลับมาที่แอป การซิงก์รอบถัดไปจะตั้งเตือนใหม่แบบตรงเวลาให้เอง
  Future<void> askExactAlarmIfNeeded() async {
    if (_askedExactAlarm) return;
    _askedExactAlarm = true;
    if (await _gateway.canScheduleExact()) return;
    await _gateway.requestExactAlarm();
  }

  /// ซิงก์กับเซิร์ฟเวอร์: ไม่มีรายการค้าง → ยกเลิก · มี → ตั้งใหม่ให้ตรง `due_at`
  ///
  /// ถ้าเรียกเซิร์ฟเวอร์ไม่สำเร็จ (เน็ตหลุด) จะ **ไม่แตะ** แจ้งเตือนที่ตั้งไว้ แล้วโยน error ต่อ
  /// เพื่อไม่ให้ยกเลิกเตือนทิ้งเพียงเพราะสัญญาณไม่ดี
  /// คืนรายการค้างที่ได้ (null = ไม่มี)
  Future<ActiveLoan?> syncWithServer(ActiveLoanSource source) async {
    final ActiveLoan? loan;
    try {
      loan = await source.fetchActiveLoan();
    } catch (e) {
      debugPrint('[reminder] sync ไม่สำเร็จ คงเตือนเดิมไว้: ${e.runtimeType}');
      rethrow;
    }
    if (loan == null) {
      await cancelAll();
    } else {
      await scheduleForLoan(bikeNo: loan.bikeNo, dueAt: loan.dueAt);
    }
    return loan;
  }
}

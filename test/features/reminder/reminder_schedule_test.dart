import 'package:bike_loan/features/reminder/data/reminder_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final due = DateTime(2026, 10, 10, 21);

  group('planReminders', () {
    test('ยืมตอนเช้า ได้ 2 ครั้ง 30 และ 10 นาทีก่อน (20.30 / 20.50)', () {
      final slots = planReminders(due, DateTime(2026, 10, 10, 9));
      expect(slots.map((s) => s.minutesBefore), [30, 10]);
      expect(slots.first.fireAt, DateTime(2026, 10, 10, 20, 30));
      expect(slots.last.fireAt, DateTime(2026, 10, 10, 20, 50));
    });

    test('ข้ามอันที่เวลาผ่านไปแล้ว', () {
      final slots = planReminders(due, DateTime(2026, 10, 10, 20, 42));
      expect(slots.map((s) => s.minutesBefore), [10]);
    });

    test('เวลาตรงกับจุดเตือนพอดี ถือว่าผ่านแล้ว', () {
      final slots = planReminders(due, DateTime(2026, 10, 10, 20, 30));
      expect(slots.map((s) => s.minutesBefore), [10]);
      expect(planReminders(due, DateTime(2026, 10, 10, 20, 50)), isEmpty);
    });

    test('เลยกำหนดแล้ว ไม่มีเตือน', () {
      expect(planReminders(due, DateTime(2026, 10, 10, 21, 1)), isEmpty);
    });

    test('id คงที่และไม่ซ้ำกัน', () {
      final ids = kAllReminderNotificationIds;
      expect(ids.toSet().length, ids.length);
      expect(reminderNotificationId(30), 4130);
      expect(reminderNotificationId(10), 4110);
    });

    test('เตือนครั้งสุดท้าย (10 นาที) เป็น urgent ส่วน 30 นาทีไม่ใช่', () {
      final slots = planReminders(due, DateTime(2026, 10, 10, 9));
      expect(slots.where((s) => s.isUrgent).map((s) => s.minutesBefore), [10]);
    });
  });

  group('phaseFor', () {
    test('แบ่งช่วงตามเวลาที่เหลือ', () {
      expect(phaseFor(due, DateTime(2026, 10, 10, 18)), LoanPhase.normal);
      expect(phaseFor(due, DateTime(2026, 10, 10, 20, 30)), LoanPhase.soon);
      expect(phaseFor(due, DateTime(2026, 10, 10, 20, 49)), LoanPhase.soon);
      expect(phaseFor(due, DateTime(2026, 10, 10, 20, 50)), LoanPhase.urgent);
      expect(phaseFor(due, DateTime(2026, 10, 10, 20, 59)), LoanPhase.urgent);
      expect(phaseFor(due, DateTime(2026, 10, 10, 21)), LoanPhase.overdue);
      expect(phaseFor(due, DateTime(2026, 10, 10, 22)), LoanPhase.overdue);
    });
  });

  test('nextReminderMinutes', () {
    expect(nextReminderMinutes(due, DateTime(2026, 10, 10, 9)), 30);
    expect(nextReminderMinutes(due, DateTime(2026, 10, 10, 20, 31)), 10);
    expect(nextReminderMinutes(due, DateTime(2026, 10, 10, 20, 51)), isNull);
  });

  test('formatThaiClock ไม่ขึ้นกับโซนเวลาของเครื่อง', () {
    // 14:00 UTC = 21:00 เวลาไทย
    expect(formatThaiClock(DateTime.utc(2026, 10, 10, 14)), '21:00');
    expect(formatThaiClock(DateTime.utc(2026, 10, 10, 13, 5)), '20:05');
    // ข้ามเที่ยงคืน: 18:30 UTC = 01:30 วันถัดไปตามเวลาไทย
    expect(formatThaiClock(DateTime.utc(2026, 10, 10, 18, 30)), '01:30');
  });
}

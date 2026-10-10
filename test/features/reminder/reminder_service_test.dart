import 'dart:io';

import 'package:bike_loan/features/reminder/data/reminder_schedule.dart';
import 'package:bike_loan/features/reminder/data/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  // 14:00 UTC = 21:00 เวลาไทย (ใช้ UTC เพื่อให้เทสต์ผ่านไม่ว่าเครื่องตั้งโซนเวลาอะไร)
  final due = DateTime.utc(2026, 10, 10, 14);
  late FakeGateway gateway;
  late DateTime now;
  late ReminderService service;

  setUp(() {
    gateway = FakeGateway();
    now = DateTime.utc(2026, 10, 10, 11); // 18:00 เวลาไทย
    service = ReminderService(gateway, now: () => now);
  });

  test('ตั้งเตือน 2 อัน (30/10) + เด้งตอนเกินเวลา + แถบนับถอยหลัง', () async {
    await service.scheduleForLoan(bikeNo: 'B01', dueAt: due);

    expect(gateway.scheduled.keys.toSet(), {
      reminderNotificationId(30),
      reminderNotificationId(10),
      kOverdueNotificationId,
    });
    for (final m in kReminderMinutes) {
      expect(
        gateway.scheduled[reminderNotificationId(m)]!.at,
        due.subtract(Duration(minutes: m)),
      );
    }
    expect(gateway.scheduled[kOverdueNotificationId]!.at, due);
    expect(gateway.countdowns[kCountdownNotificationId], due);
  });

  test('ยืมตอน 20:42 ตั้งแค่ -10 (-30 ผ่านไปแล้ว)', () async {
    now = DateTime.utc(2026, 10, 10, 13, 42);
    await service.scheduleForLoan(bikeNo: 'B01', dueAt: due);

    expect(gateway.scheduled.containsKey(reminderNotificationId(30)), isFalse);
    expect(gateway.scheduled.containsKey(reminderNotificationId(10)), isTrue);
  });

  test('ตั้งซ้ำได้ ไม่เกิดซ้อน (id คงที่ + ล้างของเดิมก่อน)', () async {
    await service.scheduleForLoan(bikeNo: 'B01', dueAt: due);
    final count = gateway.scheduled.length;
    await service.scheduleForLoan(bikeNo: 'B01', dueAt: due);
    expect(gateway.scheduled.length, count);
  });

  test('ข้อความมีเลขคัน และเวลาไทย 21:00 ไม่มีรหัสล็อก', () async {
    await service.scheduleForLoan(bikeNo: 'B07', dueAt: due);
    for (final c in gateway.scheduled.values) {
      expect('${c.title} ${c.body}', contains('B07'));
      expect(c.body, contains('21:00'));
      expect('${c.title} ${c.body}', isNot(contains('0111')));
    }
    expect(gateway.scheduled[reminderNotificationId(10)]!.urgent, isTrue);
    expect(gateway.scheduled[reminderNotificationId(30)]!.urgent, isFalse);
  });

  group('เลยกำหนดแล้ว', () {
    setUp(() => now = DateTime.utc(2026, 10, 10, 14, 5));

    test('แสดงสถานะเกินเวลาแบบเงียบ ไม่ตั้งเสียงเตือนใหม่', () async {
      await service.scheduleForLoan(bikeNo: 'B01', dueAt: due);

      expect(gateway.overdueStatus.keys, [kOverdueNotificationId]);
      expect(gateway.overdueStatus[kOverdueNotificationId], contains('21:00'));
      expect(gateway.scheduled, isEmpty);
      expect(gateway.countdowns, isEmpty);
    });

    test('ไม่ยกเลิกแจ้งเตือน "เกินเวลา" เดิมที่โชว์อยู่', () async {
      await service.scheduleForLoan(bikeNo: 'B01', dueAt: due);
      expect(gateway.cancelled, isNot(contains(kOverdueNotificationId)));
    });

    test('ซิงก์ซ้ำหลายรอบ (เปิดแอปบ่อยๆ) ไม่เกิดเสียงเตือนซ้ำ', () async {
      final source = FakeLoanSource(loanDueAt(due));
      for (var i = 0; i < 3; i++) {
        await service.syncWithServer(source);
      }
      expect(gateway.scheduled, isEmpty);
    });
  });

  test('cancelAll ยกเลิกเฉพาะ id ของฟีเจอร์นี้', () async {
    await service.scheduleForLoan(bikeNo: 'B01', dueAt: due);
    gateway.cancelled.clear();
    await service.cancelAll();

    expect(gateway.scheduled, isEmpty);
    expect(gateway.countdowns, isEmpty);
    expect(gateway.cancelled.toSet(), kAllReminderNotificationIds.toSet());
  });

  group('exact alarm', () {
    test('ยังไม่อนุญาต → ขอ 1 ครั้ง แล้วไม่ถามซ้ำ', () async {
      await service.askExactAlarmIfNeeded();
      await service.askExactAlarmIfNeeded();
      expect(gateway.exactRequests, 1);
    });

    test('อนุญาตแล้ว → ไม่ขอ', () async {
      gateway.exactAllowed = true;
      await service.askExactAlarmIfNeeded();
      expect(gateway.exactRequests, 0);
    });
  });

  group('syncWithServer', () {
    test('มีรายการค้าง → ตั้งเตือนให้ตรง due_at ของเซิร์ฟเวอร์', () async {
      final source = FakeLoanSource(loanDueAt(due, bikeNo: 'B03'));
      final loan = await service.syncWithServer(source);

      expect(loan!.bikeNo, 'B03');
      expect(
        gateway.scheduled[reminderNotificationId(30)]!.at,
        due.subtract(const Duration(minutes: 30)),
      );
    });

    test('ไม่มีรายการค้าง (คืนแล้ว) → ยกเลิกเตือนที่ค้างอยู่', () async {
      await service.scheduleForLoan(bikeNo: 'B01', dueAt: due);
      expect(gateway.scheduled, isNotEmpty);

      final loan = await service.syncWithServer(FakeLoanSource(null));
      expect(loan, isNull);
      expect(gateway.scheduled, isEmpty);
      expect(gateway.countdowns, isEmpty);
    });

    test('คืนแล้วหลังเกินเวลา → ล้างสถานะเกินเวลาด้วย', () async {
      now = DateTime.utc(2026, 10, 10, 14, 5);
      await service.syncWithServer(FakeLoanSource(loanDueAt(due)));
      expect(gateway.overdueStatus, isNotEmpty);

      await service.syncWithServer(FakeLoanSource(null));
      expect(gateway.cancelled, contains(kOverdueNotificationId));
    });

    test('due_at เปลี่ยน → ตั้งใหม่ ไม่เหลือของเก่า', () async {
      await service.scheduleForLoan(bikeNo: 'B01', dueAt: due);
      final later = due.add(const Duration(hours: 1));
      await service.syncWithServer(FakeLoanSource(loanDueAt(later)));

      expect(gateway.scheduled[kOverdueNotificationId]!.at, later);
    });

    test('เน็ตหลุด → ไม่ยกเลิกเตือนเดิม และโยน error ต่อ', () async {
      await service.scheduleForLoan(bikeNo: 'B01', dueAt: due);
      final before = gateway.scheduled.length;
      final source = FakeLoanSource()..error = const SocketException('offline');

      await expectLater(
        service.syncWithServer(source),
        throwsA(isA<SocketException>()),
      );
      expect(gateway.scheduled.length, before);
    });
  });
}

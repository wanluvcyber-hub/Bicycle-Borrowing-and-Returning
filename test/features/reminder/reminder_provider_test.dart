import 'dart:io';

import 'package:bike_loan/features/reminder/data/reminder_schedule.dart';
import 'package:bike_loan/features/reminder/data/reminder_service.dart';
import 'package:bike_loan/features/reminder/state/reminder_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  final due = DateTime(2026, 10, 10, 21);
  late FakeGateway gateway;
  late FakeLoanSource source;
  late ReminderProvider provider;

  setUp(() {
    gateway = FakeGateway();
    source = FakeLoanSource();
    provider = ReminderProvider(
      source,
      ReminderService(gateway, now: () => DateTime(2026, 10, 10, 18)),
    );
  });

  test('เปิดแอปใหม่: refresh ได้รายการเดิมจากเซิร์ฟเวอร์', () async {
    source.loan = loanDueAt(due);
    expect(provider.loaded, isFalse);

    await provider.refresh();

    expect(provider.loaded, isTrue);
    expect(provider.loan!.dueAt, due);
    expect(provider.error, isNull);
    expect(gateway.scheduled, isNotEmpty);
  });

  test('ไม่ได้ยืม: loaded เป็นจริงแต่ loan เป็น null', () async {
    await provider.refresh();
    expect(provider.loaded, isTrue);
    expect(provider.loan, isNull);
  });

  test('คืนแล้ว: refresh รอบถัดไปล้างรายการและเตือน', () async {
    source.loan = loanDueAt(due);
    await provider.refresh();
    source.loan = null;
    await provider.refresh();

    expect(provider.loan, isNull);
    expect(gateway.scheduled, isEmpty);
  });

  test('เน็ตหลุด: มี error แต่ยังเก็บรายการเดิมและเตือนเดิมไว้', () async {
    source.loan = loanDueAt(due);
    await provider.refresh();
    source.error = const SocketException('offline');
    await provider.refresh();

    expect(provider.error, isNotNull);
    expect(provider.loan, isNotNull);
    expect(gateway.scheduled, isNotEmpty);
  });

  test('startLoan: โชว์ทันทีและตั้งเตือน', () async {
    await provider.startLoan(loanDueAt(due));
    expect(provider.loan!.bikeNo, 'B01');
    expect(gateway.scheduled.containsKey(reminderNotificationId(10)), isTrue);
  });

  test('startLoan: ขอสิทธิ์ exact alarm ส่วน refresh ไม่ขอ', () async {
    source.loan = loanDueAt(due);
    await provider.refresh();
    expect(gateway.exactRequests, 0);

    await provider.startLoan(loanDueAt(due));
    expect(gateway.exactRequests, 1);
  });

  test('clear: ล้างทุกอย่าง (ออกจากระบบ)', () async {
    await provider.startLoan(loanDueAt(due));
    await provider.clear();
    expect(provider.loan, isNull);
    expect(provider.loaded, isFalse);
    expect(gateway.scheduled, isEmpty);
  });
}

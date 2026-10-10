import 'package:bike_loan/features/reminder/data/reminder_schedule.dart';
import 'package:bike_loan/features/reminder/data/reminder_service.dart';
import 'package:bike_loan/features/reminder/presentation/reminder_scope.dart';
import 'package:bike_loan/features/reminder/state/reminder_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  final due = DateTime.utc(2026, 10, 10, 14);
  late FakeGateway gateway;
  late FakeLoanSource source;
  late ReminderService service;

  setUp(() {
    gateway = FakeGateway();
    source = FakeLoanSource();
    service = ReminderService(
      gateway,
      now: () => DateTime.utc(2026, 10, 10, 11),
    );
  });

  testWidgets('เปิดหน้า → ซิงก์กับเซิร์ฟเวอร์ 1 ครั้ง', (tester) async {
    await tester.pumpWidget(
      ReminderScope(
        source: source,
        service: service,
        builder: (_, _) => const SizedBox(),
      ),
    );
    await tester.pump();
    expect(source.calls, 1);
  });

  testWidgets('ยืมสำเร็จ (onLoanStarted) → ตั้งเตือน', (tester) async {
    late ReminderProvider reminder;
    await tester.pumpWidget(
      ReminderScope(
        source: source,
        service: service,
        builder: (_, r) {
          reminder = r;
          return const SizedBox();
        },
      ),
    );
    await reminder.onLoanStarted(
      loanId: 1,
      bikeNo: 'B01',
      borrowedAt: due.subtract(const Duration(hours: 3)),
      dueAt: due,
    );
    expect(gateway.scheduled.containsKey(reminderNotificationId(30)), isTrue);
    expect(reminder.loan!.bikeNo, 'B01');
  });

  testWidgets('ออกจากหน้า (ออกจากระบบ) → ยกเลิกเตือนทั้งหมด', (tester) async {
    late ReminderProvider reminder;
    await tester.pumpWidget(
      ReminderScope(
        source: source,
        service: service,
        builder: (_, r) {
          reminder = r;
          return const SizedBox();
        },
      ),
    );
    await reminder.onLoanStarted(
      loanId: 1,
      bikeNo: 'B01',
      borrowedAt: due.subtract(const Duration(hours: 3)),
      dueAt: due,
    );
    expect(gateway.scheduled, isNotEmpty);

    await tester.pumpWidget(const SizedBox()); // ถอดหน้านี้ออก
    await tester.pump();
    expect(gateway.scheduled, isEmpty);
    expect(gateway.countdowns, isEmpty);
  });
}

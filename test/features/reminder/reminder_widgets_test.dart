import 'package:bike_loan/features/reminder/presentation/countdown_format.dart';
import 'package:bike_loan/features/reminder/presentation/loan_countdown_card.dart';
import 'package:bike_loan/features/reminder/presentation/overdue_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final due = DateTime(2026, 10, 10, 21);

  test('formatCountdown', () {
    expect(
      formatCountdown(const Duration(hours: 1, minutes: 5, seconds: 9)),
      '01:05:09',
    );
    expect(formatCountdown(Duration.zero), '00:00:00');
    expect(formatCountdown(const Duration(seconds: -75)), '00:01:15');
  });

  testWidgets('การ์ดนับถอยหลังเดินทุกวินาที', (tester) async {
    var now = DateTime(2026, 10, 10, 20, 0, 0);
    await tester.pumpWidget(
      _wrap(
        LoanCountdownCard(
          bikeNo: 'B01',
          borrowedAt: DateTime(2026, 10, 10, 18),
          dueAt: due,
          clock: () => now,
        ),
      ),
    );
    expect(find.text('01:00:00'), findsOneWidget);
    expect(find.text('จักรยาน B01'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:59:59'), findsOneWidget);
  });

  testWidgets('เลยกำหนด: โชว์ว่าเกินเวลา', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LoanCountdownCard(
          bikeNo: 'B01',
          borrowedAt: DateTime(2026, 10, 10, 18),
          dueAt: due,
          clock: () => DateTime(2026, 10, 10, 21, 10),
        ),
      ),
    );
    expect(find.text('เกินเวลามาแล้ว'), findsOneWidget);
    expect(find.text('00:10:00'), findsOneWidget);
  });

  testWidgets('OverdueBanner', (tester) async {
    await tester.pumpWidget(
      _wrap(OverdueBanner(dueAt: due, now: DateTime(2026, 10, 10, 21, 30))),
    );
    expect(find.textContaining('เกินเวลา 30 นาที'), findsOneWidget);
  });
}

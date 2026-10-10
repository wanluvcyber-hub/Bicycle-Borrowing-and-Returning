import 'package:bike_loan/core/utils/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final due = DateTime(2026, 10, 10, 21);

  test('formatClock / formatDateTime', () {
    expect(formatClock(due), '21:00');
    expect(formatClock(DateTime(2026, 1, 1, 9, 5)), '09:05');
    expect(formatDateTime(due), '10/10/2569 21:00');
  });

  test('formatRemaining', () {
    expect(
      formatRemaining(due, now: DateTime(2026, 10, 10, 18, 45)),
      'เหลือ 2 ชม. 15 นาที',
    );
    expect(
      formatRemaining(due, now: DateTime(2026, 10, 10, 20)),
      'เหลือ 1 ชม.',
    );
    expect(
      formatRemaining(due, now: DateTime(2026, 10, 10, 20, 45)),
      'เหลือ 15 นาที',
    );
    expect(
      formatRemaining(due, now: DateTime(2026, 10, 10, 20, 59, 30)),
      'เหลือไม่ถึง 1 นาที',
    );
    expect(
      formatRemaining(due, now: DateTime(2026, 10, 10, 21, 30)),
      'เกินเวลา 30 นาที',
    );
  });
}

import 'package:bike_loan/features/admin/data/admin_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 15:00 UTC = 22:00 เวลาไทย ของวันที่ 10 ต.ค. (เลยเที่ยงคืนไทยแล้วเมื่อเทียบ UTC วันเดียวกัน)
  final now = DateTime.utc(2026, 10, 10, 13); // 20:00 ไทย
  final dayStart = DateTime.utc(2026, 10, 9, 17); // 00:00 ไทย วันที่ 10

  Map<String, dynamic> bike(String no, String status, [String? note]) => {
    'bike_no': no,
    'status': status,
    'note': note,
  };

  Map<String, dynamic> loan({
    required int id,
    required String bike,
    required DateTime borrowed,
    required DateTime due,
    DateTime? returned,
    bool late = false,
    String student = '66000001',
  }) => {
    'loan_id': id,
    'bike_no': bike,
    'student_id': student,
    'borrowed_at': borrowed.toIso8601String(),
    'due_at': due.toIso8601String(),
    'returned_at': returned?.toIso8601String(),
    'is_late': late,
    'students': {
      'full_name': 'นิสิตทดสอบ',
      'building': 'อาคาร A',
      'room': '305',
    },
  };

  final due = DateTime.utc(2026, 10, 10, 14); // 21:00 ไทย

  test('thaiDayStart: ต้นวันตามเวลาไทย ไม่ขึ้นกับโซนเครื่อง', () {
    expect(thaiDayStart(now), dayStart);
    // 00:30 ไทย (= 17:30 UTC วันก่อน) ยังเป็นวันใหม่ของไทย
    expect(thaiDayStart(DateTime.utc(2026, 10, 9, 17, 30)), dayStart);
    // 23:59 ไทย ของวันก่อนหน้า
    expect(
      thaiDayStart(DateTime.utc(2026, 10, 9, 16, 59)),
      DateTime.utc(2026, 10, 8, 17),
    );
  });

  test('นับสถานะจักรยานและอัตราหมุนเวียน (ไม่นับคันชำรุดเป็นฐาน)', () {
    final d = AdminDashboard.fromRows(
      bikes: [
        bike('B01', 'available'),
        bike('B02', 'available'),
        bike('B03', 'borrowed'),
        bike('B04', 'borrowed'),
        bike('B05', 'broken', 'เบรกเสีย'),
      ],
      loans: const [],
      studentCount: 100,
      now: now,
    );
    expect(d.total, 5);
    expect(d.available, 2);
    expect(d.inUse, 2);
    expect(d.broken, 1);
    expect(d.utilization, closeTo(0.5, 1e-9)); // 2 / (5-1)
    expect(d.brokenBikes.single.note, 'เบรกเสีย');
    expect(d.studentCount, 100);
  });

  test('ไม่มีจักรยานใช้งานได้ → อัตราหมุนเวียน 0 ไม่หารศูนย์', () {
    final d = AdminDashboard.fromRows(
      bikes: [bike('B01', 'broken')],
      loans: const [],
      studentCount: 0,
      now: now,
    );
    expect(d.utilization, 0);
    expect(
      AdminDashboard.fromRows(
        bikes: const [],
        loans: const [],
        studentCount: 0,
        now: now,
      ).utilization,
      0,
    );
  });

  test('เกินเวลา: ยังไม่คืนและเลย due_at · เรียงเกินนานสุดก่อน', () {
    final d = AdminDashboard.fromRows(
      bikes: [
        bike('B07', 'borrowed'),
        bike('B08', 'borrowed'),
        bike('B09', 'borrowed'),
      ],
      loans: [
        // เลย 21:00? now=20:00 จึงยังไม่เกิน
        loan(id: 1, bike: 'B09', borrowed: dayStart, due: due),
        // due 19:25 ไทย = เกิน 35 นาที
        loan(
          id: 2,
          bike: 'B07',
          borrowed: dayStart,
          due: DateTime.utc(2026, 10, 10, 12, 25),
        ),
        // due 18:00 ไทย = เกิน 2 ชม. (นานสุด)
        loan(
          id: 3,
          bike: 'B08',
          borrowed: dayStart,
          due: DateTime.utc(2026, 10, 10, 11),
        ),
      ],
      studentCount: 0,
      now: now,
    );
    expect(d.overdue, 2);
    expect(d.overdueLoans.map((l) => l.bikeNo), ['B08', 'B07']);
    expect(d.overdueLoans.last.lateBy(now), const Duration(minutes: 35));
    expect(d.overdueLoans.first.studentName, 'นิสิตทดสอบ');
    expect(d.overdueLoans.first.roomLabel, 'อาคาร A · ห้อง 305');
  });

  test(
    'สถิติวันนี้: ยืมวันนี้ / คืนตรงเวลา / คืนล่าช้า (เฉพาะที่คืนวันนี้)',
    () {
      final yesterday = dayStart.subtract(const Duration(hours: 5));
      final d = AdminDashboard.fromRows(
        bikes: const [],
        loans: [
          loan(
            id: 1,
            bike: 'B01',
            borrowed: dayStart.add(const Duration(hours: 2)),
            due: due,
            returned: dayStart.add(const Duration(hours: 5)),
          ),
          loan(
            id: 2,
            bike: 'B02',
            borrowed: dayStart.add(const Duration(hours: 3)),
            due: due,
            returned: dayStart.add(const Duration(hours: 6)),
          ),
          loan(
            id: 3,
            bike: 'B03',
            borrowed: dayStart.add(const Duration(hours: 1)),
            due: due,
            returned: dayStart.add(const Duration(hours: 15)),
            late: true,
          ),
          // ยืมเมื่อวาน คืนวันนี้ช้า: นับเฉพาะ "คืนล่าช้า" ไม่นับ "ยืมวันนี้"
          loan(
            id: 4,
            bike: 'B04',
            borrowed: yesterday,
            due: yesterday.add(const Duration(hours: 3)),
            returned: dayStart.add(const Duration(hours: 1)),
            late: true,
          ),
          // ยืมวันนี้ ยังไม่คืน
          loan(
            id: 5,
            bike: 'B05',
            borrowed: dayStart.add(const Duration(hours: 4)),
            due: due,
          ),
          // คืนเมื่อวาน ไม่นับวันนี้เลย
          loan(
            id: 6,
            bike: 'B06',
            borrowed: yesterday,
            due: yesterday,
            returned: yesterday.add(const Duration(hours: 1)),
          ),
        ],
        studentCount: 0,
        now: now,
      );
      expect(d.borrowedToday, 4); // id 1,2,3,5
      expect(d.returnedOnTimeToday, 2);
      expect(d.returnedLateToday, 2); // id 3 และ 4
      expect(d.returnedToday, 4);
      expect(d.onTimeRate, closeTo(0.5, 1e-9));
    },
  );

  test('วันนี้ยังไม่มีการคืน → onTimeRate เป็น null', () {
    final d = AdminDashboard.fromRows(
      bikes: const [],
      loans: [loan(id: 1, bike: 'B01', borrowed: dayStart, due: due)],
      studentCount: 0,
      now: now,
    );
    expect(d.onTimeRate, isNull);
  });

  test('ข้อมูลนิสิตที่ join มาไม่ครบ ไม่ทำให้พัง', () {
    final row = loan(
      id: 1,
      bike: 'B01',
      borrowed: dayStart,
      due: DateTime.utc(2026, 10, 10, 11),
    )..['students'] = null;
    final d = AdminDashboard.fromRows(
      bikes: const [],
      loans: [row],
      studentCount: 0,
      now: now,
    );
    expect(d.overdueLoans.single.studentName, isNull);
    expect(d.overdueLoans.single.roomLabel, '');
  });
}

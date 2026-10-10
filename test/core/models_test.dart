import 'package:bike_loan/core/models/app_role.dart';
import 'package:bike_loan/core/models/bike.dart';
import 'package:bike_loan/core/models/loan.dart';
import 'package:bike_loan/core/models/staff_member.dart';
import 'package:bike_loan/core/models/student.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Student.fromJson', () {
    final s = Student.fromJson({
      'student_id': '66000001',
      'full_name': 'นิสิตทดสอบ 01',
      'building': 'อาคาร 1',
      'room': '101',
      'phone': null,
      'email': 'test01@example.com',
      'semester': '1/2569',
      'verified': true,
      'late_count': 2,
      'created_at': '2026-10-10T04:30:00+00:00',
    });
    expect(s.studentId, '66000001');
    expect(s.phone, isNull);
    expect(s.verified, isTrue);
    expect(s.lateCount, 2);
    expect(s.createdAt!.isUtc, isFalse);
  });

  test('Bike.fromJson และป้ายสถานะภาษาไทย', () {
    final b = Bike.fromJson({
      'bike_no': 'B01',
      'qr_code': 'B01',
      'station': 'ป้อมยามหอใน',
      'status': 'broken',
      'note': 'เบรกเสีย',
    });
    expect(b.status, BikeStatus.broken);
    expect(b.status.labelTh, 'ชำรุด');
    expect(BikeStatus.available.labelTh, 'ว่าง');
    expect(BikeStatus.borrowed.labelTh, 'ถูกยืม');
    expect(() => BikeStatus.fromDb('lost'), throwsFormatException);
  });

  test('Loan.fromJson (ยังไม่คืน / คืนแล้ว)', () {
    final open = Loan.fromJson({
      'loan_id': 12,
      'student_id': '66000001',
      'bike_no': 'B01',
      'borrowed_at': '2026-10-10T04:30:00+00:00',
      'due_at': '2026-10-10T14:00:00+00:00',
      'returned_at': null,
      'received_by': null,
      'condition': null,
      'status': 'borrowing',
      'is_late': false,
    });
    expect(open.returnedAt, isNull);
    expect(open.condition, isNull);
    expect(open.isOverdueAt(DateTime.utc(2026, 10, 10, 13)), isFalse);
    expect(open.isOverdueAt(DateTime.utc(2026, 10, 10, 15)), isTrue);

    final done = Loan.fromJson({
      'loan_id': 12,
      'student_id': '66000001',
      'bike_no': 'B01',
      'borrowed_at': '2026-10-10T04:30:00+00:00',
      'due_at': '2026-10-10T14:00:00+00:00',
      'returned_at': '2026-10-10T15:00:00+00:00',
      'received_by': 'abc',
      'condition': 'damaged',
      'status': 'returned',
      'is_late': true,
    });
    expect(done.condition, LoanCondition.damaged);
    expect(done.status.labelTh, 'คืนแล้ว');
    expect(done.isLate, isTrue);
    expect(done.isOverdueAt(DateTime.utc(2030)), isFalse);
  });

  test(
    'ActiveLoan.fromJson: borrow_bike ไม่มี status / get_my_active_loan มี',
    () {
      final base = {
        'loan_id': 12,
        'bike_no': 'B01',
        'lock_code': '0111',
        'borrowed_at': '2026-10-10T04:30:00+00:00',
        'due_at': '2026-10-10T14:00:00+00:00',
      };
      final a = ActiveLoan.fromJson(base);
      expect(a.status, LoanStatus.borrowing);
      expect(a.lockCode, '0111');
      expect(a.toString(), isNot(contains('0111')));
      final b = ActiveLoan.fromJson({...base, 'status': 'overdue'});
      expect(b.isOverdueAt(DateTime.utc(2026, 10, 10, 1)), isTrue);
    },
  );

  test('StaffMember / AppRole', () {
    final m = StaffMember.fromJson({
      'user_id': 'u1',
      'full_name': 'ป้อมยามทดสอบ',
      'role': 'guard',
    });
    expect(m.role, AppRole.guard);
    expect(AppRole.fromStaffRole('admin'), AppRole.admin);
    expect(() => AppRole.fromStaffRole('boss'), throwsFormatException);
  });
}

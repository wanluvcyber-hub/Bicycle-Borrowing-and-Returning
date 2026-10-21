// กันไม่ให้ SQL (supabase/migrations) · โค้ด · เอกสาร (docs/database.md) แยกทางกัน
// ถ้าเทสต์นี้แดง แปลว่ามีคนแก้ schema/รหัส error/ค่าสถานะ โดยไม่ได้แก้อีกฝั่งให้ตรง
import 'dart:io';

import 'package:bike_loan/core/errors/app_error.dart';
import 'package:bike_loan/core/models/app_role.dart';
import 'package:bike_loan/core/models/bike.dart';
import 'package:bike_loan/core/models/loan.dart';
import 'package:flutter_test/flutter_test.dart';

/// รหัส error ที่ฐานข้อมูลโยนได้ ตามหัวข้อ 5 ของ database.md
/// `invalid_condition` คือบั๊กของแอป ไม่แสดงให้ผู้ใช้จึงไม่มีข้อความไทย
const _expectedCodes = {
  'not_authenticated',
  'not_in_dorm_list',
  'not_verified',
  'already_borrowing',
  'bike_not_found',
  'bike_not_available',
  'no_lock_code',
  'after_hours',
  'staff_only',
  'invalid_condition',
  'note_required',
  'no_active_loan',
};
const _hiddenFromUser = {'invalid_condition'};

String _read(String path) => File(path).readAsStringSync();

void main() {
  final sql = [
    _read('supabase/migrations/001_init.sql'),
  ].join('\n');
  final doc = _read('docs/database.md');

  test('ไม่เก็บเบอร์โทรนิสิต: โค้ด เอกสาร และ migration 006 ที่ลบคอลัมน์ตรงกัน', () {
    final drop = _read('supabase/migrations/006_drop_student_phone.sql');
    expect(drop, contains('drop column if exists phone'));
    expect(drop, contains('drop function if exists public.update_my_phone'));
    expect(doc, isNot(contains('update_my_phone(')));
    expect(doc, isNot(contains('| `phone` |')));
  });

  group('รหัส error', () {
    test('SQL โยนรหัสเท่ากับที่เอกสารกำหนดพอดี', () {
      final inSql = RegExp(r"raise exception '([a-z_]+)'")
          .allMatches(sql)
          .map((m) => m.group(1)!)
          .toSet();
      expect(inSql, _expectedCodes);
    });

    test('ทุกรหัสที่ผู้ใช้เห็นได้ มีข้อความไทยใน app_error.dart', () {
      expect(
        kDbErrorMessages.keys.toSet(),
        _expectedCodes.difference(_hiddenFromUser),
      );
    });

    test('ทุกรหัสอยู่ในตารางหัวข้อ 5 ของ database.md', () {
      for (final code in _expectedCodes) {
        expect(doc, contains('`$code`'), reason: 'database.md ไม่มี $code');
      }
    });
  });

  group('ค่าสถานะ', () {
    // check (... in ('a','b')) ทั้งหมดใน SQL
    final sqlSets = RegExp(r"in \(((?:'[a-z_]+',?\s*)+)\)")
        .allMatches(sql)
        .map(
          (m) =>
              RegExp(r"'([a-z_]+)'")
                  .allMatches(m.group(1)!)
                  .map((e) => e.group(1)!)
                  .toSet(),
        )
        .toList();

    void expectSqlHas(String name, Set<String> values) => expect(
      sqlSets.any((s) => s.length == values.length && s.containsAll(values)),
      isTrue,
      reason: '$name: SQL ไม่มีชุดค่า $values (พบ $sqlSets)',
    );

    test('enum ในโค้ดตรงกับ check constraint ใน SQL', () {
      expectSqlHas(
        'bikes.status',
        BikeStatus.values.map((e) => e.dbValue).toSet(),
      );
      expectSqlHas(
        'loans.status',
        LoanStatus.values.map((e) => e.dbValue).toSet(),
      );
      expectSqlHas(
        'loans.condition',
        LoanCondition.values.map((e) => e.dbValue).toSet(),
      );
      expectSqlHas('staff.role', {'guard', 'admin'});
    });

    test('ทุกค่าสถานะอยู่ในตารางหัวข้อ 7 ของ database.md', () {
      for (final v in [
        ...BikeStatus.values.map((e) => e.dbValue),
        ...LoanStatus.values.map((e) => e.dbValue),
        ...LoanCondition.values.map((e) => e.dbValue),
        'guard',
        'admin',
      ]) {
        expect(doc, contains('`$v`'), reason: 'database.md ไม่มี $v');
      }
    });

    test('ป้ายภาษาไทยตรงกับตารางหัวข้อ 7', () {
      expect(
        {for (final e in BikeStatus.values) e.dbValue: e.labelTh},
        {'available': 'ว่าง', 'borrowed': 'ถูกยืม', 'broken': 'ชำรุด'},
      );
      expect(
        {for (final e in LoanStatus.values) e.dbValue: e.labelTh},
        {'borrowing': 'กำลังยืม', 'overdue': 'เกินเวลา', 'returned': 'คืนแล้ว'},
      );
      expect(
        {for (final e in LoanCondition.values) e.dbValue: e.labelTh},
        {'normal': 'ปกติ', 'damaged': 'ชำรุด'},
      );
      expect(AppRole.guard.labelTh, 'ป้อมรปภ.');
      expect(AppRole.admin.labelTh, 'ผู้ดูแลระบบ');
    });

    test('ค่าที่ไม่รู้จักโยน FormatException ไม่เงียบ', () {
      expect(() => LoanStatus.fromDb('lost'), throwsFormatException);
      expect(() => LoanCondition.fromDb('broken'), throwsFormatException);
    });
  });

  group('ฟังก์ชัน (rpc)', () {
    test('ฟังก์ชันที่เอกสารบอกมีอยู่จริงใน SQL', () {
      for (final f in [
        'claim_student_profile',
        'borrow_bike',
        'get_my_active_loan',
        'return_bike',
        'mark_overdue_loans',
        'is_staff',
        'is_admin',
      ]) {
        expect(sql, contains('function public.$f'), reason: 'SQL ไม่มี $f');
        expect(doc, contains(f), reason: 'database.md ไม่มี $f');
      }
    });
  });
}

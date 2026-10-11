import 'package:bike_loan/features/admin/data/csv_parser.dart';
import 'package:bike_loan/features/admin/data/student_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCsv', () {
    test('คอมมา, เครื่องหมายคำพูด, CRLF, BOM, บรรทัดว่าง', () {
      final t = parseCsv('﻿a,b,c\r\n1,"x,y",3\r\n\r\n"he said ""hi""",,\n');
      expect(t, [
        ['a', 'b', 'c'],
        ['1', 'x,y', '3'],
        ['he said "hi"', '', ''],
      ]);
    });

    test('ขึ้นบรรทัดใหม่ในช่องที่ครอบด้วยเครื่องหมายคำพูด', () {
      expect(parseCsv('a,b\n"l1\nl2",2'), [
        ['a', 'b'],
        ['l1\nl2', '2'],
      ]);
    });
  });

  group('parseStudentCsv', () {
    const header = 'student_id,full_name,building,room,phone,email,semester';

    test('ไฟล์ถูกต้อง', () {
      final r = parseStudentCsv(
        '$header\n'
        '66000001,สมชาย ใจดี,อาคาร 1,101,0800000001,a@example.com,1/2569\n'
        '66000002,สมหญิง,,,,,1/2569\n',
      );
      expect(r.fileErrors, isEmpty);
      expect(r.validRows, hasLength(2));
      expect(r.rows[1].data['email'], isNull);
      expect(r.rows[1].rowNumber, 3);
      expect(r.rows[0].data.keys, containsAll(kStudentCsvColumns));
    });

    test('ขาดคอลัมน์จำเป็น', () {
      final r = parseStudentCsv('student_id,full_name\n1,a');
      expect(r.fileErrors.single, contains('semester'));
      expect(r.rows, isEmpty);
    });

    test('เบอร์มือถือเป็นคอลัมน์จำเป็นและห้ามเว้นว่าง', () {
      final missingColumn = parseStudentCsv(
        'student_id,full_name,semester\n66000001,A,1/2569',
      );
      expect(missingColumn.fileErrors.single, contains('phone'));

      final emptyValue = parseStudentCsv(
        '$header\n66000001,A,,,,,1/2569',
      );
      expect(emptyValue.validRows, isEmpty);
      expect(emptyValue.rows.single.errors, contains('ไม่มี phone'));
    });

    test('ไฟล์ว่าง / มีแต่หัว', () {
      expect(parseStudentCsv('').fileErrors, isNotEmpty);
      expect(parseStudentCsv(header).fileErrors, isNotEmpty);
    });

    test('แถวผิด: ขาดค่า, อีเมลผิดรูปแบบ, ซ้ำในไฟล์', () {
      final r = parseStudentCsv(
        '$header\n'
        '66000001,A,,,0800000001,a@example.com,1/2569\n'
        ',B,,,0800000002,,1/2569\n'
        '66000003,C,,,0800000003,not-an-email,1/2569\n'
        '66000001,D,,,0800000004,,1/2569\n'
        '66000005,E,,,0800000005,A@example.com,1/2569\n',
      );
      expect(r.validRows.map((e) => e.rowNumber), [2]);
      expect(r.rows[1].errors.single, contains('student_id'));
      expect(r.rows[2].errors.single, contains('อีเมล'));
      expect(r.rows[3].errors.single, contains('แถว 2'));
      expect(r.rows[4].errors.single, contains('แถว 2'));
    });

    test('ไม่ส่ง verified/late_count/auth_user_id และไม่ทับคอลัมน์เสริมที่ไม่มีในไฟล์', () {
      final r = parseStudentCsv(
        'student_id,full_name,phone,semester,verified,late_count,auth_user_id\n'
        '66000001,A,0800000001,1/2569,true,9,xyz',
      );
      expect(r.ignoredColumns, ['verified', 'late_count', 'auth_user_id']);
      expect(r.rows.single.data.keys.toSet(), {
        'student_id',
        'full_name',
        'phone',
        'semester',
      });
    });

    test('ตัดช่องว่างหัวท้ายและไม่สนตัวพิมพ์ของหัวคอลัมน์', () {
      final r = parseStudentCsv(
        ' Student_ID , FULL_NAME , Phone ,Semester\n'
        ' 66000001 , A , 0800000001 , 1/2569 ',
      );
      expect(r.fileErrors, isEmpty);
      expect(r.rows.single.data['student_id'], '66000001');
      expect(r.rows.single.data['full_name'], 'A');
      expect(r.rows.single.data['phone'], '0800000001');
    });
  });
}

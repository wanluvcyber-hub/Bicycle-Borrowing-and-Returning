import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/bike.dart';
import '../../../core/supabase/supabase_client.dart';
import 'student_import.dart';

/// จักรยานพร้อมรหัสล็อก (แอดมินอ่าน `bike_locks` ได้)
class AdminBike {
  const AdminBike(this.bike, this.lockCode);
  final Bike bike;

  /// null = ยังไม่มีแถวใน `bike_locks` (นิสิตยืมคันนี้ไม่ได้: `no_lock_code`)
  final String? lockCode;
}

/// ตัวเรียก Supabase ของหน้าผู้ดูแลระบบ (7.0)
class AdminRepository {
  static const _chunkSize = 200;

  // ---------- นำเข้ารายชื่อ ----------

  /// นำเข้าแถวที่ผ่านการตรวจแล้ว: `upsert(onConflict: 'student_id')` ส่งเฉพาะคอลัมน์ในไฟล์
  /// (ไม่ส่ง verified / late_count / auth_user_id จึงไม่ทับสถานะของคนที่ผูกบัญชีแล้ว)
  Future<StudentImportSummary> importStudents(
    List<StudentImportRow> allRows,
  ) async {
    final issues = <ImportIssue>[
      for (final r in allRows.where((r) => !r.isValid))
        ImportIssue(r.rowNumber, r.studentId, r.errors.join(', ')),
    ];
    final rows = allRows.where((r) => r.isValid).toList();

    final existing = await _fetchExistingStudents();
    final existingIds = existing.keys.toSet();
    final emailOwner = <String, String>{
      for (final e in existing.entries)
        if (e.value != null) e.value!.toLowerCase(): e.key,
    };

    // อีเมลนี้เป็นของนิสิตอีกรหัสในฐานข้อมูลแล้ว → ผิด (ฐานข้อมูลห้ามอีเมลซ้ำ)
    final toSend = <StudentImportRow>[];
    for (final r in rows) {
      final email = r.data['email']?.toLowerCase();
      final owner = email == null ? null : emailOwner[email];
      if (owner != null && owner != r.studentId) {
        issues.add(
          ImportIssue(
            r.rowNumber,
            r.studentId,
            'อีเมลนี้เป็นของนิสิตรหัส $owner ในระบบแล้ว',
          ),
        );
      } else {
        toSend.add(r);
      }
    }

    var added = 0;
    var updated = 0;
    void count(StudentImportRow r) =>
        existingIds.contains(r.studentId) ? updated++ : added++;

    for (var i = 0; i < toSend.length; i += _chunkSize) {
      final chunk = toSend.skip(i).take(_chunkSize).toList();
      try {
        await _upsert(chunk);
        chunk.forEach(count);
      } on PostgrestException {
        // ทั้งก้อนล้ม: ลองทีละแถวเพื่อบอกว่าแถวไหนผิดเพราะอะไร
        for (final r in chunk) {
          try {
            await _upsert([r]);
            count(r);
          } catch (e) {
            issues.add(ImportIssue(r.rowNumber, r.studentId, _rowError(e)));
          }
        }
      }
    }

    issues.sort((a, b) => a.rowNumber.compareTo(b.rowNumber));
    return StudentImportSummary(added: added, updated: updated, issues: issues);
  }

  Future<void> _upsert(List<StudentImportRow> rows) => supabase
      .from('students')
      .upsert([for (final r in rows) r.data], onConflict: 'student_id');

  String _rowError(Object e) {
    if (e is PostgrestException && e.code == '23505') {
      return 'ข้อมูลซ้ำกับนิสิตคนอื่น (เช่น อีเมลซ้ำ)';
    }
    return errorMessage(e);
  }

  /// student_id → email ของนิสิตที่มีอยู่แล้ว (อ่านทีละ 1000 แถว เพราะ PostgREST จำกัดต่อคำขอ)
  Future<Map<String, String?>> _fetchExistingStudents() async {
    final result = <String, String?>{};
    const page = 1000;
    for (var from = 0; ; from += page) {
      final data = await supabase
          .from('students')
          .select('student_id, email')
          .order('student_id')
          .range(from, from + page - 1);
      for (final r in data) {
        result[r['student_id'] as String] = r['email'] as String?;
      }
      if (data.length < page) break;
    }
    return result;
  }

  // ---------- จักรยาน / รหัสล็อก / งานซ่อม ----------

  Future<List<AdminBike>> fetchBikes() async {
    final data = await supabase
        .from('bikes')
        .select(
          'bike_no, qr_code, station, status, note, bike_locks(lock_code)',
        )
        .order('bike_no');
    return [
      for (final r in data)
        AdminBike(Bike.fromJson(r), _lockOf(r['bike_locks'])),
    ];
  }

  // ความสัมพันธ์ 1:1 PostgREST อาจส่งเป็น object หรือ list ขึ้นกับการตั้งค่า รองรับทั้งสองแบบ
  String? _lockOf(Object? embedded) {
    final map = embedded is List
        ? (embedded.isEmpty ? null : embedded.first)
        : embedded;
    return map is Map ? map['lock_code'] as String? : null;
  }

  /// เพิ่มจักรยาน + แถว `bike_locks` (qr_code = เลขคัน) ถ้าใส่รหัสล็อกไม่สำเร็จจะลบคันที่เพิ่งเพิ่มคืน
  Future<void> addBike({
    required String bikeNo,
    required String? station,
    required String lockCode,
  }) async {
    await supabase.from('bikes').insert({
      'bike_no': bikeNo,
      'qr_code': bikeNo,
      'station': station,
    });
    try {
      await supabase.from('bike_locks').insert({
        'bike_no': bikeNo,
        'lock_code': lockCode,
      });
    } catch (_) {
      await supabase.from('bikes').delete().eq('bike_no', bikeNo);
      rethrow;
    }
  }

  Future<void> updateStation(String bikeNo, String? station) =>
      supabase.from('bikes').update({'station': station}).eq('bike_no', bikeNo);

  /// ตั้ง/เปลี่ยนรหัสล็อก (ใช้ upsert เพื่อให้คันที่ยังไม่มีแถวรหัสก็ตั้งได้)
  Future<void> setLockCode(String bikeNo, String lockCode) =>
      supabase.from('bike_locks').upsert({
        'bike_no': bikeNo,
        'lock_code': lockCode,
      }, onConflict: 'bike_no');

  /// ซ่อมเสร็จ: broken → available และล้างหมายเหตุ (เฉพาะคันที่ยังชำรุดอยู่)
  Future<void> markRepaired(String bikeNo) => supabase
      .from('bikes')
      .update({'status': BikeStatus.available.dbValue, 'note': null})
      .eq('bike_no', bikeNo)
      .eq('status', BikeStatus.broken.dbValue);
}

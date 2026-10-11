import 'csv_parser.dart';

/// รูปแบบ CSV นำเข้ารายชื่อหอใน (UTF-8, แถวแรกเป็นหัวคอลัมน์)
/// ส่งเฉพาะคอลัมน์เหล่านี้ **ห้ามมี verified / late_count / auth_user_id** (database.md 4.7)
const kStudentCsvRequired = ['student_id', 'full_name', 'phone', 'semester'];
const kStudentCsvOptional = ['building', 'room', 'email'];
const kStudentCsvColumns = [...kStudentCsvRequired, ...kStudentCsvOptional];

const kStudentCsvExample =
    'student_id,full_name,building,room,phone,email,semester\n'
    '66000001,สมชาย ใจดี,อาคาร 1,101,0800000001,somchai@example.com,1/2569';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// 1 แถวข้อมูลในไฟล์ (นับเลขแถวตามที่เห็นในไฟล์: แถวหัว = 1)
class StudentImportRow {
  StudentImportRow(this.rowNumber, this.data, [List<String>? errors])
    : errors = errors ?? [];

  final int rowNumber;

  /// เฉพาะคอลัมน์ใน [kStudentCsvColumns] ที่มีในไฟล์ · ช่องว่างเป็น null
  final Map<String, String?> data;
  final List<String> errors;

  bool get isValid => errors.isEmpty;
  String? get studentId => data['student_id'];
  String? get fullName => data['full_name'];
}

class StudentCsvResult {
  const StudentCsvResult({
    this.rows = const [],
    this.fileErrors = const [],
    this.ignoredColumns = const [],
  });

  final List<StudentImportRow> rows;

  /// ปัญหาระดับไฟล์ (เช่น ขาดคอลัมน์) · มีแล้วนำเข้าไม่ได้
  final List<String> fileErrors;

  /// คอลัมน์ที่ไม่รู้จัก ถูกข้าม
  final List<String> ignoredColumns;

  List<StudentImportRow> get validRows => rows.where((r) => r.isValid).toList();
  List<StudentImportRow> get invalidRows =>
      rows.where((r) => !r.isValid).toList();
}

StudentCsvResult parseStudentCsv(String text) {
  final table = parseCsv(text);
  if (table.isEmpty) {
    return const StudentCsvResult(fileErrors: ['ไฟล์ว่าง ไม่มีข้อมูล']);
  }

  final header = table.first.map((h) => h.trim().toLowerCase()).toList();
  final missing = kStudentCsvRequired
      .where((c) => !header.contains(c))
      .toList();
  if (missing.isNotEmpty) {
    return StudentCsvResult(
      fileErrors: ['ไม่พบคอลัมน์ที่จำเป็น: ${missing.join(', ')}'],
    );
  }
  final ignored = header
      .where((h) => h.isNotEmpty && !kStudentCsvColumns.contains(h))
      .toList();

  final rows = <StudentImportRow>[];
  for (var i = 1; i < table.length; i++) {
    final cells = table[i];
    final data = <String, String?>{};
    for (final col in kStudentCsvColumns) {
      final idx = header.indexOf(col);
      // คอลัมน์เสริมที่ไม่มีในไฟล์ ไม่ส่งไปเลย จะได้ไม่ไปทับค่าเดิมในฐานข้อมูลเป็นว่าง
      if (idx < 0) continue;
      final v = idx < cells.length ? cells[idx].trim() : '';
      data[col] = v.isEmpty ? null : v;
    }
    final row = StudentImportRow(i + 1, data);
    for (final col in kStudentCsvRequired) {
      if (data[col] == null) row.errors.add('ไม่มี $col');
    }
    final email = data['email'];
    if (email != null && !_emailPattern.hasMatch(email)) {
      row.errors.add('อีเมลไม่ถูกรูปแบบ');
    }
    rows.add(row);
  }

  // รหัสนิสิต/อีเมลซ้ำกันในไฟล์เดียวกัน: แถวหลังๆ ที่ซ้ำถือว่าผิด
  final seenIds = <String, int>{};
  final seenEmails = <String, int>{};
  for (final row in rows) {
    final id = row.studentId;
    if (id != null) {
      final first = seenIds[id];
      if (first != null) {
        row.errors.add('รหัสนิสิตซ้ำกับแถว $first');
      } else {
        seenIds[id] = row.rowNumber;
      }
    }
    final email = row.data['email']?.toLowerCase();
    if (email != null) {
      final first = seenEmails[email];
      if (first != null) {
        row.errors.add('อีเมลซ้ำกับแถว $first');
      } else {
        seenEmails[email] = row.rowNumber;
      }
    }
  }

  if (rows.isEmpty) {
    return StudentCsvResult(
      fileErrors: const ['มีแค่แถวหัวคอลัมน์ ไม่มีข้อมูลนิสิต'],
      ignoredColumns: ignored,
    );
  }
  return StudentCsvResult(rows: rows, ignoredColumns: ignored);
}

/// แถวที่นำเข้าไม่ผ่าน (ทั้งจากตรวจไฟล์และจากฐานข้อมูล)
class ImportIssue {
  const ImportIssue(this.rowNumber, this.studentId, this.reason);
  final int rowNumber;
  final String? studentId;
  final String reason;
}

class StudentImportSummary {
  const StudentImportSummary({
    required this.added,
    required this.updated,
    required this.issues,
  });

  final int added;
  final int updated;
  final List<ImportIssue> issues;
}

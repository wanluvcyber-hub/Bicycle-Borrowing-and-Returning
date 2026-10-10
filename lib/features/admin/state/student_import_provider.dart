import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../data/admin_repository.dart';
import '../data/student_import.dart';

enum ImportStage { pick, preview, importing, done }

/// ขั้นตอนนำเข้ารายชื่อ: เลือกไฟล์ → ตรวจ/ดูตัวอย่าง → นำเข้า → สรุป
class StudentImportProvider extends ChangeNotifier {
  StudentImportProvider(this._repo);
  final AdminRepository _repo;

  ImportStage _stage = ImportStage.pick;
  String? _fileName;
  StudentCsvResult? _parsed;
  StudentImportSummary? _summary;
  String? _error;

  ImportStage get stage => _stage;
  String? get fileName => _fileName;
  StudentCsvResult? get parsed => _parsed;
  StudentImportSummary? get summary => _summary;
  String? get error => _error;

  /// ปุ่มนำเข้ากดได้เมื่อไม่มี error ระดับไฟล์ และมีอย่างน้อย 1 แถวที่ผ่าน
  bool get canImport =>
      _stage == ImportStage.preview &&
      _parsed != null &&
      _parsed!.fileErrors.isEmpty &&
      _parsed!.validRows.isNotEmpty;

  void loadCsv(String fileName, String text) {
    _fileName = fileName;
    _parsed = parseStudentCsv(text);
    _error = null;
    _stage = ImportStage.preview;
    notifyListeners();
  }

  Future<void> runImport() async {
    if (!canImport) return;
    _stage = ImportStage.importing;
    _error = null;
    notifyListeners();
    try {
      _summary = await _repo.importStudents(_parsed!.rows);
      _stage = ImportStage.done;
    } catch (e) {
      _error = errorMessage(e);
      _stage = ImportStage.preview;
    }
    notifyListeners();
  }

  void reset() {
    _stage = ImportStage.pick;
    _fileName = null;
    _parsed = null;
    _summary = null;
    _error = null;
    notifyListeners();
  }
}

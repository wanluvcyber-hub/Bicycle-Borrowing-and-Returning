import 'package:flutter/foundation.dart';

import '../../../core/errors/app_error.dart';
import '../data/admin_dashboard.dart';
import '../data/admin_repository.dart';

/// ข้อมูลหน้าแดชบอร์ดผู้ดูแล (อ่านอย่างเดียว) · โหลดตอนเปิดหน้า ดึงลงเพื่อรีเฟรช หรือกลับมาที่แท็บ
class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider(this._repo);

  final AdminRepository _repo;

  AdminDashboard? _data;
  bool _loading = false;
  String? _error;

  AdminDashboard? get data => _data;
  bool get loading => _loading;

  /// ข้อความ error ภาษาไทย · ถ้ามีข้อมูลเดิมอยู่ ยังโชว์ต่อได้
  String? get error => _error;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _repo.fetchDashboard();
    } catch (e) {
      _error = errorMessage(e);
    }
    _loading = false;
    notifyListeners();
  }
}

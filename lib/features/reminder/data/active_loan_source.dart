import '../../../core/models/loan.dart';
import '../../../core/supabase/supabase_client.dart';

/// แหล่งข้อมูล "รายการที่ยืมค้างอยู่ของฉัน" แยกเป็น interface เพื่อให้เทสต์ได้
abstract class ActiveLoanSource {
  /// null = ไม่มีรายการค้าง (คืนแล้ว หรือยังไม่เคยยืม) · โยน error ถ้าเน็ตหลุด
  Future<ActiveLoan?> fetchActiveLoan();
}

/// เรียก `get_my_active_loan()` (docs/database.md 4.3)
class SupabaseActiveLoanSource implements ActiveLoanSource {
  @override
  Future<ActiveLoan?> fetchActiveLoan() async {
    final res = await supabase.rpc('get_my_active_loan');
    final row = res is List ? (res.isEmpty ? null : res.first) : res;
    if (row == null) return null;
    return ActiveLoan.fromJson(Map<String, dynamic>.from(row as Map));
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

// แปลงรหัส error ของฐานข้อมูล (docs/database.md หัวข้อ 5) เป็นข้อความไทย
// ใช้ชั่วคราวจนกว่าคนที่ 1 ทำ lib/core/errors/app_error.dart เสร็จ แล้วค่อยเปลี่ยนไปใช้ตัวกลาง

const _messages = <String, String>{
  'not_authenticated': 'กรุณาเข้าสู่ระบบก่อน',
  'staff_only': 'ฟังก์ชันนี้สำหรับเจ้าหน้าที่เท่านั้น',
  'note_required': 'ถ้าชำรุด ต้องใส่หมายเหตุ',
  'no_active_loan': 'ไม่พบรายการยืมค้างของคันนี้',
};

String guardErrorMessage(Object error) {
  if (error is PostgrestException) {
    final known = _messages[error.message.trim()];
    if (known != null) return known;
  }
  // error อื่นไม่ใช่ความผิดของผู้ใช้ (เช่น เน็ตหลุด สิทธิ์ไม่พอ) แสดงข้อความกลางๆ
  return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
}

/// ใช้โยนจาก repository จำลอง ให้หน้าจอได้ข้อความเหมือนของจริง
class GuardException implements Exception {
  const GuardException(this.code);
  final String code;

  String get message => _messages[code] ?? code;

  @override
  String toString() => code;
}

String guardMessageOf(Object error) =>
    error is GuardException ? error.message : guardErrorMessage(error);

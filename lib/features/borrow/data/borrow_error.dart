import 'package:supabase_flutter/supabase_flutter.dart';

// แปลงรหัส error ของฐานข้อมูล (docs/database.md หัวข้อ 5) เป็นข้อความไทย
// ใช้ชั่วคราวจนกว่าคนที่ 1 ทำ lib/core/errors/app_error.dart เสร็จ แล้วค่อยเปลี่ยนไปใช้ตัวกลาง

const _messages = <String, String>{
  'not_authenticated': 'กรุณาเข้าสู่ระบบก่อน',
  'not_verified': 'บัญชีนี้ยังไม่ได้ยืนยันสิทธิ์หอใน',
  'already_borrowing': 'คุณมีจักรยานที่ยืมค้างอยู่ ต้องคืนก่อน',
  'bike_not_found': 'ไม่พบจักรยานคันนี้ ลองสแกนอีกครั้ง',
  'bike_not_available': 'จักรยานคันนี้ไม่ว่าง',
  'no_lock_code': 'จักรยานคันนี้ยังไม่มีรหัสล็อก แจ้งผู้ดูแล',
  'after_hours': 'เลยเวลา 21.00 น. แล้ว ยืมไม่ได้',
  'invalid_phone': 'เบอร์โทรไม่ถูกต้อง ต้องเป็นเบอร์มือถือ 10 หลัก ขึ้นต้นด้วย 0',
};

const networkErrorMessage = 'เชื่อมต่อไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
const unknownErrorMessage = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';

/// ใช้โยนจาก repository จำลอง ให้หน้าจอได้ข้อความเหมือนของจริง
class BorrowException implements Exception {
  const BorrowException(this.code);
  final String code;

  @override
  String toString() => code;
}

/// error ที่ฐานข้อมูลตอบกลับมา (แปลว่าคำขอถึงเซิร์ฟเวอร์แล้ว) ไม่ใช่เน็ตหลุด
bool isServerReply(Object error) =>
    error is PostgrestException || error is BorrowException;

/// รหัส error ของฐานข้อมูล (null = ไม่ใช่คำตอบจากเซิร์ฟเวอร์ เช่น เน็ตหลุด)
String? errorCodeOf(Object error) => switch (error) {
      PostgrestException(:final message) => message.trim(),
      BorrowException(:final code) => code,
      _ => null,
    };

String borrowErrorMessage(Object error) {
  final code = errorCodeOf(error);
  if (code != null) return _messages[code] ?? unknownErrorMessage;
  // error อื่น (เน็ตหลุด timeout ฯลฯ) ถือว่าเป็นปัญหาการเชื่อมต่อ
  return networkErrorMessage;
}

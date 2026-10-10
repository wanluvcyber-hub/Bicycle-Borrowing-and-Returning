import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// รหัส error ของฟังก์ชันฐานข้อมูล → ข้อความไทย (docs/database.md หัวข้อ 5)
const Map<String, String> kDbErrorMessages = {
  'not_authenticated': 'กรุณาเข้าสู่ระบบก่อน',
  'not_in_dorm_list': 'ไม่พบอีเมลนี้ในรายชื่อนิสิตหอใน กรุณาติดต่อกองหอพัก',
  'not_verified': 'บัญชีนี้ยังไม่ได้ยืนยันสิทธิ์หอใน',
  'already_borrowing': 'คุณมีจักรยานที่ยืมค้างอยู่ ต้องคืนก่อน',
  'bike_not_found': 'ไม่พบจักรยานคันนี้ ลองสแกนอีกครั้ง',
  'bike_not_available': 'จักรยานคันนี้ไม่ว่าง',
  'no_lock_code': 'จักรยานคันนี้ยังไม่มีรหัสล็อก แจ้งผู้ดูแล',
  'after_hours': 'เลยเวลา 21.00 น. แล้ว ยืมไม่ได้',
  'staff_only': 'ฟังก์ชันนี้สำหรับเจ้าหน้าที่เท่านั้น',
  'note_required': 'ถ้าชำรุด ต้องใส่หมายเหตุ',
  'no_active_loan': 'ไม่พบรายการยืมค้างของคันนี้',
};

const _genericMessage = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
const _networkMessage = 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ ตรวจสอบสัญญาณแล้วลองใหม่';

/// รหัส error ของฐานข้อมูล (เช่น `already_borrowing`) หรือ null ถ้าไม่ใช่ error ของฟังก์ชันเรา
String? dbErrorCode(Object error) {
  if (error is! PostgrestException) return null;
  final code = error.message.trim();
  return kDbErrorMessages.containsKey(code) ? code : null;
}

/// แปลง error ใดๆ เป็นข้อความไทยสำหรับโชว์ผู้ใช้ (ไม่โชว์ข้อความดิบของระบบ)
/// error ที่ไม่รู้จักจะถูก log ไว้ให้ทีมดู
String errorMessage(Object error) {
  final code = dbErrorCode(error);
  if (code != null) return kDbErrorMessages[code]!;

  if (error is AuthException) return _authMessage(error);
  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException) {
    return _networkMessage;
  }

  debugPrint('[app_error] ${error.runtimeType}: $error');
  return _genericMessage;
}

String _authMessage(AuthException e) {
  final code = e.code ?? '';
  final msg = e.message.toLowerCase();
  if (code == 'invalid_credentials' || msg.contains('invalid login')) {
    return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
  }
  if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
    return 'อีเมลนี้ยังไม่ได้ยืนยัน กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ';
  }
  if (code.contains('rate_limit') || msg.contains('rate limit')) {
    return 'ลองบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่';
  }
  if (msg.contains('socket') ||
      msg.contains('network') ||
      msg.contains('failed host lookup')) {
    return _networkMessage;
  }
  debugPrint('[app_error] AuthException(${e.code}): ${e.message}');
  return 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
}

import 'dart:io';

import 'package:bike_loan/core/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('รหัส error ของฐานข้อมูลทุกตัวแปลเป็นข้อความไทย', () {
    for (final code in kDbErrorMessages.keys) {
      expect(
        errorMessage(PostgrestException(message: code)),
        kDbErrorMessages[code],
      );
      expect(dbErrorCode(PostgrestException(message: code)), code);
    }
  });

  test('error ที่ไม่รู้จักไม่โชว์ข้อความดิบ', () {
    final msg = errorMessage(
      PostgrestException(message: 'permission denied for table loans'),
    );
    expect(msg, isNot(contains('permission')));
    expect(
      dbErrorCode(PostgrestException(message: 'permission denied')),
      isNull,
    );
    expect(errorMessage(StateError('boom')), isNot(contains('boom')));
  });

  test('error ล็อกอินและเครือข่าย', () {
    expect(
      errorMessage(
        const AuthException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        ),
      ),
      'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
    );
    expect(errorMessage(const SocketException('x')), contains('เชื่อมต่อ'));
  });
}

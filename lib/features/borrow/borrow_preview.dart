import 'package:flutter/material.dart';

import '../../core/models/app_role.dart';
import '../../core/theme/app_theme.dart';

import 'data/borrow_repository.dart';
import 'presentation/borrow_home_page.dart';

// ทดลองแอปนิสิตด้วยข้อมูลปลอม ไม่ต้องต่อ Supabase (ไม่ต้องรอ core/ ของคนที่ 1):
//   flutter run -d chrome -t lib/features/borrow/borrow_preview.dart
// ลองกด "สแกน QR ยืม" แล้วพิมพ์ B01 (ยืมได้) · B02 (ถูกยืมอยู่) · B05 (ชำรุด) · X99 (QR มั่ว)
void main() {
  runApp(
    MaterialApp(
      theme: AppTheme.forRole(AppRole.student),
      home: BorrowHomePage(
        repository: FakeBorrowRepository(),
        onSignOut: () async {},
      ),
    ),
  );
}

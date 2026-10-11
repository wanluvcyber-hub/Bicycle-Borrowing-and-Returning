import 'package:flutter/material.dart';

import '../../core/models/app_role.dart';
import '../../core/theme/app_theme.dart';

import 'data/guard_repository.dart';
import 'presentation/guard_home_page.dart';

// ทดลองหน้าป้อมรปภ.ด้วยข้อมูลปลอม ไม่ต้องต่อ Supabase (ไม่ต้องรอ core/ ของคนที่ 1):
//   flutter run -d chrome -t lib/features/guard/guard_preview.dart
// ลองรับคืน B01 (ตรงเวลา) และ B03 (เกินเวลา) · ค้นประวัติ 66000001 / 66000003
void main() {
  runApp(
    MaterialApp(
      theme: AppTheme.forRole(AppRole.guard),
      home: GuardHomePage(repository: FakeGuardRepository()),
    ),
  );
}

import 'package:flutter/material.dart';

import 'data/guard_repository.dart';
import 'presentation/guard_home_page.dart';

// ทดลองหน้าป้อมยามด้วยข้อมูลปลอม ไม่ต้องต่อ Supabase (ไม่ต้องรอ core/ ของคนที่ 1):
//   flutter run -d chrome -t lib/features/guard/guard_preview.dart
// ลองรับคืน B01 (ตรงเวลา) และ B03 (เกินเวลา) · ค้นประวัติ 66000001 / 66000003
void main() {
  runApp(MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.orange),
    home: GuardHomePage(repository: FakeGuardRepository()),
  ));
}

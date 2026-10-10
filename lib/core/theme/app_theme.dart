import 'package:flutter/material.dart';

import '../models/app_role.dart';

/// ธีมกลาง สีประจำบทบาท: นิสิต=เขียว · ป้อมยาม=ส้ม · ผู้ดูแล=เทา
class AppTheme {
  const AppTheme._();

  static const studentColor = Color(0xFF2E7D32);
  static const guardColor = Color(0xFFEF6C00);
  static const adminColor = Color(0xFF546E7A);

  static Color seedFor(AppRole? role) => switch (role) {
    AppRole.guard => guardColor,
    AppRole.admin => adminColor,
    _ => studentColor,
  };

  /// ธีมตามบทบาท (ยังไม่ล็อกอิน = ธีมนิสิต)
  static ThemeData forRole(AppRole? role) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seedFor(role)),
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

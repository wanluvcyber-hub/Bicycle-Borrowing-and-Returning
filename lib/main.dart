import 'package:flutter/material.dart';

// จุดเริ่มต้นของแอป · ตอนนี้เป็นหน้าเปล่าไว้ให้โปรเจกต์รันได้
// คนที่ 1: เติม Supabase.initialize(...) + MultiProvider + router ที่นี่ (ดู docs/person-1-auth-admin.md)
void main() {
  runApp(const MaterialApp(
    home: Scaffold(body: Center(child: Text('ระบบยืมจักรยานหอใน'))),
  ));
}

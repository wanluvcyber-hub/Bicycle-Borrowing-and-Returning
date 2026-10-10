import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/message_view.dart';
import '../state/session_provider.dart';

/// ล็อกอินได้ แต่อีเมลไม่อยู่ในรายชื่อหอใน
class NoAccessPage extends StatelessWidget {
  const NoAccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MessageView(
          icon: Icons.block,
          title: 'ไม่พบสิทธิ์',
          message: 'ไม่พบอีเมลนี้ในรายชื่อนิสิตหอใน กรุณาติดต่อกองหอพัก',
          actions: [
            FilledButton(
              onPressed: () => context.read<SessionProvider>().signOut(),
              child: const Text('ออกจากระบบ'),
            ),
          ],
        ),
      ),
    );
  }
}

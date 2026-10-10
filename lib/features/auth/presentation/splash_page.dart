import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/message_view.dart';
import '../state/session_provider.dart';

/// หน้ารอตอนเปิดแอป/กำลังเช็กบทบาท · ถ้าโหลดไม่ได้จะโชว์ปุ่มลองใหม่/ออกจากระบบ
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.status == SessionStatus.error) {
      return Scaffold(
        body: SafeArea(
          child: MessageView(
            icon: Icons.cloud_off,
            message: session.loadError ?? 'เกิดข้อผิดพลาด',
            actions: [
              FilledButton(
                onPressed: session.retry,
                child: const Text('ลองอีกครั้ง'),
              ),
              TextButton(
                onPressed: session.signOut,
                child: const Text('ออกจากระบบ'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/logo.png',
                width: 96,
                height: 96,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.pedal_bike, size: 72),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

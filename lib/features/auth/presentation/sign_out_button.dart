import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session_provider.dart';

/// ปุ่มออกจากระบบ ใส่ใน `AppBar.actions` ได้ทุกฝั่ง (ถามยืนยันก่อนออก)
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'ออกจากระบบ',
      icon: const Icon(Icons.logout),
      onPressed: () async {
        final session = context.read<SessionProvider>();
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ออกจากระบบ'),
            content: const Text('ต้องการออกจากระบบใช่ไหม'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('ออกจากระบบ'),
              ),
            ],
          ),
        );
        if (ok == true) await session.signOut();
      },
    );
  }
}

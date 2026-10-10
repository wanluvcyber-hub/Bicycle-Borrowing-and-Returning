import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../state/reminder_provider.dart';

/// ครอบหน้าหลักของนิสิต: ซิงก์กับเซิร์ฟเวอร์ตอนเปิดหน้านี้ และทุกครั้งที่แอปกลับมาจากพื้นหลัง
/// (นิสิตอาจคืนจักรยานไปแล้วระหว่างที่แอปถูกพับ → ยกเลิกเตือนที่ค้าง / หรือเวลาเปลี่ยน → ตั้งใหม่)
///
/// ต้องอยู่ใต้ `ChangeNotifierProvider<ReminderProvider>`
class ReminderLifecycle extends StatefulWidget {
  const ReminderLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<ReminderLifecycle> createState() => _ReminderLifecycleState();
}

class _ReminderLifecycleState extends State<ReminderLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReminderProvider>().refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ReminderProvider>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

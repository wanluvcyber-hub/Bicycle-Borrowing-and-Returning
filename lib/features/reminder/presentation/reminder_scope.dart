import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/active_loan_source.dart';
import '../data/reminder_service.dart';
import '../state/reminder_provider.dart';
import 'reminder_lifecycle.dart';

/// ครอบหน้าหลักของนิสิตด้วยระบบแจ้งเตือนให้ครบในที่เดียว:
/// สร้าง [ReminderProvider] · ซิงก์กับเซิร์ฟเวอร์ตอนเปิด/กลับจากพื้นหลัง ([ReminderLifecycle])
/// · **ยกเลิกเตือนทั้งหมดเมื่อออกจากหน้านี้** (ออกจากระบบ → router พากลับหน้าล็อกอิน → หน้านี้ถูกถอดออก)
/// กันเตือนของนิสิตคนเก่าโผล่ให้คนใหม่ที่ใช้เครื่องเดียวกัน
///
/// ```dart
/// ReminderScope(
///   builder: (context, reminder) => BorrowHomePage(
///     onBorrowed: (loan) => reminder.onLoanStarted(...),
///   ),
/// )
/// ```
class ReminderScope extends StatefulWidget {
  const ReminderScope({
    super.key,
    required this.builder,
    this.source,
    this.service,
  });

  final Widget Function(BuildContext context, ReminderProvider reminder)
  builder;

  /// ไม่ส่ง = ใช้ Supabase จริง / [ReminderService.instance] (ส่งไว้สำหรับเทสต์)
  final ActiveLoanSource? source;
  final ReminderService? service;

  @override
  State<ReminderScope> createState() => _ReminderScopeState();
}

class _ReminderScopeState extends State<ReminderScope> {
  late final ReminderService _service =
      widget.service ?? ReminderService.instance;
  late final ReminderProvider _provider = ReminderProvider(
    widget.source ?? SupabaseActiveLoanSource(),
    _service,
  );

  @override
  void dispose() {
    _provider.dispose();
    _service.cancelAll().catchError((Object e) {
      debugPrint('[reminder] ยกเลิกเตือนตอนออกไม่สำเร็จ: ${e.runtimeType}');
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReminderProvider>.value(
      value: _provider,
      child: ReminderLifecycle(
        child: Builder(builder: (ctx) => widget.builder(ctx, _provider)),
      ),
    );
  }
}

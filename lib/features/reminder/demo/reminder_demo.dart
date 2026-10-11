// แอปเดโมแยก สำหรับทดสอบเฉพาะส่วนแจ้งเตือน (ไม่ใช้ Supabase ไม่ต้องล็อกอิน)
//
//   flutter run -t lib/features/reminder/demo/reminder_demo.dart
//
// "เซิร์ฟเวอร์จำลอง" เก็บเป็นไฟล์ในเครื่อง จึงลองปิดแอปแล้วเปิดใหม่ได้
// แจ้งเตือนเป็นของจริง (ใช้ ReminderService เดียวกับแอปหลัก)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../../core/models/loan.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../data/active_loan_source.dart';
import '../data/reminder_service.dart';
import '../presentation/loan_countdown_card.dart';
import '../presentation/overdue_banner.dart';
import '../presentation/reminder_lifecycle.dart';
import '../state/reminder_provider.dart';

/// get_my_active_loan จำลอง · เก็บในไฟล์ให้รอดการปิดแอป
class DemoLoanSource implements ActiveLoanSource {
  // มือถือ: เก็บเป็นไฟล์ (รอดการปิดแอป) · เว็บ: เก็บในหน่วยความจำ (รีโหลดหน้าแล้วหาย)
  static String? _memory;
  File? get _file => kIsWeb
      ? null
      : File('${Directory.systemTemp.path}/reminder_demo_loan.json');

  String? _read() {
    final f = _file;
    if (f == null) return _memory;
    return f.existsSync() ? f.readAsStringSync() : null;
  }

  void _write(String? json) {
    final f = _file;
    if (f == null) {
      _memory = json;
    } else if (json == null) {
      if (f.existsSync()) f.deleteSync();
    } else {
      f.writeAsStringSync(json);
    }
  }

  /// เปิดเพื่อจำลองเน็ตหลุด
  bool offline = false;

  @override
  Future<ActiveLoan?> fetchActiveLoan() async {
    if (offline) throw TimeoutException('จำลองเน็ตหลุด');
    final raw = _read();
    if (raw == null) return null;
    return ActiveLoan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// เหมือน borrow_bike: สร้างรายการที่ due_at = ตอนนี้ + [minutes] นาที
  ActiveLoan borrow(String bikeNo, int minutes) {
    final now = DateTime.now().toUtc();
    final loan = {
      'loan_id': 1,
      'bike_no': bikeNo,
      'lock_code': '0000', // ปลอม
      'borrowed_at': now.toIso8601String(),
      'due_at': now.add(Duration(minutes: minutes)).toIso8601String(),
    };
    _write(jsonEncode(loan));
    return ActiveLoan.fromJson(loan);
  }

  /// เหมือนป้อมรปภ.รับคืนแล้ว
  void markReturned() => _write(null);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ขอสิทธิ์แจ้งเตือนตั้งแต่เปิดแอป · ถ้าพังต้องไม่ทำให้หน้าขาว ให้โชว์ error บนจอแทน
  String? initError;
  try {
    await ReminderService.instance.init();
  } catch (e, st) {
    debugPrint('[demo] init แจ้งเตือนไม่สำเร็จ: $e\n$st');
    initError = '$e';
  }
  final source = DemoLoanSource();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ReminderProvider(source, ReminderService.instance),
      child: MaterialApp(
        title: 'Reminder demo',
        theme: AppTheme.forRole(null),
        home: ReminderLifecycle(
          child: _DemoPage(source: source, initError: initError),
        ),
      ),
    ),
  );
}

class _DemoPage extends StatefulWidget {
  const _DemoPage({required this.source, this.initError});
  final DemoLoanSource source;
  final String? initError;

  @override
  State<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<_DemoPage> {
  final _minutes = TextEditingController(text: '35');
  String _log = '';

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _say(String s) =>
      setState(() => _log = '${formatClock(DateTime.now())}  $s\n$_log');

  Future<void> _borrow() async {
    final m = int.tryParse(_minutes.text.trim());
    if (m == null || m < 0) return _say('ใส่จำนวนนาทีเป็นตัวเลข');
    final loan = widget.source.borrow('B01', m);
    await context.read<ReminderProvider>().startLoan(loan);
    _say('ยืม B01 กำหนดคืนอีก $m นาที (${formatClock(loan.dueAt)} น.)');
  }

  Future<void> _returned() async {
    widget.source.markReturned();
    await context.read<ReminderProvider>().refresh();
    _say('จำลองรับคืนที่เซิร์ฟเวอร์ แล้วซิงก์ → เตือนควรถูกยกเลิก');
  }

  Future<void> _refresh() async {
    final p = context.read<ReminderProvider>();
    await p.refresh();
    _say(p.error != null ? 'ซิงก์ไม่สำเร็จ: ${p.error}' : 'ซิงก์แล้ว');
  }

  Future<void> _pending() async {
    try {
      final list = await FlutterLocalNotificationsPlugin()
          .pendingNotificationRequests();
      list.sort((a, b) => a.id.compareTo(b.id));
      _say(
        list.isEmpty
            ? 'ไม่มีเตือนที่รอเด้ง'
            : 'รอเด้ง ${list.length} อัน: ${list.map((e) => '#${e.id}').join(' ')}',
      );
    } catch (e) {
      _say('แพลตฟอร์มนี้ดูรายการที่รอเด้งไม่ได้ (${e.runtimeType})');
    }
  }

  Future<void> _exact() async {
    final android = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final before = await android?.canScheduleExactNotifications();
    _say('exact alarm ตอนนี้: $before');
    if (before == false) await android?.requestExactAlarmsPermission();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReminderProvider>();
    final loan = p.loan;
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.initError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'เริ่มระบบแจ้งเตือนไม่สำเร็จ (แพลตฟอร์มนี้อาจไม่รองรับ): '
                '${widget.initError}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (loan != null) ...[
            if (loan.isOverdueAt(DateTime.now()))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OverdueBanner(dueAt: loan.dueAt),
              ),
            LoanCountdownCard(
              bikeNo: loan.bikeNo,
              borrowedAt: loan.borrowedAt,
              dueAt: loan.dueAt,
            ),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(p.loaded ? 'ไม่ได้ยืมจักรยาน' : 'กำลังโหลด...'),
              ),
            ),
          if (p.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(p.error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minutes,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'กำหนดคืนอีกกี่นาที',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _borrow, child: const Text('ยืม B01')),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final m in [35, 15, 2, 0])
                ActionChip(
                  label: Text(m == 0 ? 'เกินเวลาแล้ว' : '$m นาที'),
                  onPressed: () => _minutes.text = '$m',
                ),
            ],
          ),
          const Divider(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _refresh,
                child: const Text('ซิงก์ (เหมือนเปิดแอป)'),
              ),
              OutlinedButton(
                onPressed: _returned,
                child: const Text('จำลองรับคืนแล้ว'),
              ),
              OutlinedButton(
                onPressed: _pending,
                child: const Text('ดูเตือนที่รอเด้ง'),
              ),
              OutlinedButton(
                onPressed: _exact,
                child: const Text('เช็ก/ขอ exact alarm'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await context.read<ReminderProvider>().clear();
                  _say('ล้างเตือนทั้งหมด (เหมือนออกจากระบบ)');
                },
                child: const Text('ล้างเตือน'),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('จำลองเน็ตหลุด'),
            subtitle: const Text('เปิดแล้วกดซิงก์ เตือนเดิมต้องไม่หาย'),
            value: widget.source.offline,
            onChanged: (v) => setState(() => widget.source.offline = v),
          ),
          const Divider(),
          Text(_log, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

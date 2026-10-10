import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/borrow_models.dart';
import '../state/borrow_provider.dart';
import 'borrow_widgets.dart';

/// ยืนยันการยืม: ข้อมูลนิสิตดึงจากบัญชีที่ล็อกอิน แสดงให้ดูเฉยๆ ห้ามพิมพ์เอง
/// (ต้องห่อด้วย ChangeNotifierProvider.value เพราะ push เป็น route ใหม่)
class ConfirmBorrowPage extends StatelessWidget {
  const ConfirmBorrowPage({super.key, required this.qrCode});

  final String qrCode;

  Future<void> _confirm(BuildContext context) async {
    final navigator = Navigator.of(context);
    final outcome = await context.read<BorrowProvider>().confirmBorrow(qrCode);
    if (outcome == BorrowOutcome.success) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BorrowProvider>();
    final student = p.profile;
    final now = p.now;
    final due = DateTime(now.year, now.month, now.day, 21);

    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันการยืม')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row('จักรยาน', qrCode),
                  _Row('ชื่อ', student?.fullName ?? '-'),
                  _Row('รหัสนิสิต', student?.studentId ?? '-'),
                  _Row('วันที่ยืม', formatDate(now)),
                  _Row('กำหนดคืน', '${formatClock(due)} ของวันนี้'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (p.borrowError != null) ErrorBanner(p.borrowError!),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: studentColor,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: p.borrowing ? null : () => _confirm(context),
            child: p.borrowing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('ยืนยันการยืม'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: p.borrowing
                ? null
                : () {
                    p.clearBorrowError();
                    Navigator.of(context).pop();
                  },
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/borrow_models.dart';
import 'borrow_widgets.dart';

/// รหัสล็อก + เวลานับถอยหลังถึง 21.00 น. · เวลาที่เหลือคำนวณจาก due_at ทุกครั้ง
/// เลยกำหนดแล้วเปลี่ยนเป็นสถานะ "เกินเวลา"
class ActiveLoanCard extends StatefulWidget {
  const ActiveLoanCard({super.key, required this.loan, required this.clock});

  final MyLoan loan;
  final DateTime Function() clock;

  @override
  State<ActiveLoanCard> createState() => _ActiveLoanCardState();
}

class _ActiveLoanCardState extends State<ActiveLoanCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // วาดใหม่ถี่กว่า 1 นาทีเล็กน้อย เพื่อให้สลับเป็น "เกินเวลา" ทันเวลา
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final now = widget.clock();
    final overdue = loan.isOverdue(now);
    final color = overdue ? Colors.red : studentColor;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('จักรยานที่คุณยืม',
                style: Theme.of(context).textTheme.titleMedium),
            Text(loan.bikeNo,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('รหัสล็อกล้อ'),
            Text(
              loan.lockCode ?? '----',
              key: const Key('lockCode'),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            StatusChip(
              label: overdue ? 'เกินเวลา' : 'กำลังยืม',
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              formatRemaining(loan.remaining(now)),
              key: const Key('remaining'),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: color),
            ),
            Text('กำหนดคืน ${formatClock(loan.dueAt)} · คืนที่ป้อมยาม'),
            Text('ยืมเมื่อ ${formatDate(loan.borrowedAt)} ${formatClock(loan.borrowedAt)}'),
          ],
        ),
      ),
    );
  }
}

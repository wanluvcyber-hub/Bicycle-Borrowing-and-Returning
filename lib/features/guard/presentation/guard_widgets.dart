import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/guard_models.dart';

/// สีประจำบทบาทป้อมยาม = ส้ม (ตามแผน)
const guardColor = Colors.orange;

final _timeFormat = DateFormat('dd/MM HH:mm');

String formatTime(DateTime? t) => t == null ? '-' : _timeFormat.format(t);

Color bikeStatusColor(BikeStatus status, {bool overdue = false}) {
  if (overdue) return Colors.red;
  return switch (status) {
    BikeStatus.available => Colors.green,
    BikeStatus.borrowed => Colors.blue,
    BikeStatus.broken => Colors.grey,
  };
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

/// การ์ดแสดงผู้ยืม + เวลา ใช้ทั้งหน้ารับคืนและแดชบอร์ด
class LoanDetails extends StatelessWidget {
  const LoanDetails({super.key, required this.loan, required this.now});

  final GuardLoan loan;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final overdue = loan.isOverdue(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${loan.studentName ?? '-'} (${loan.studentId})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (loan.roomLabel.isNotEmpty) Text(loan.roomLabel),
        if ((loan.phone ?? '').isNotEmpty) Text('โทร ${loan.phone}'),
        const SizedBox(height: 4),
        Text('ยืม ${formatTime(loan.borrowedAt)} · กำหนดคืน ${formatTime(loan.dueAt)}'),
        if (overdue)
          const Text('เกินเวลา',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}

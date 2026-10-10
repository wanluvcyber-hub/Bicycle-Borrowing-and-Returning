import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart' show formatDuration;
import '../data/reminder_schedule.dart';

/// แถบ "เกินเวลา" กลาง ใช้ทั้งฝั่งนิสิตและป้อมยาม
///
/// ```dart
/// if (loan.isOverdueAt(DateTime.now()))
///   OverdueBanner(dueAt: loan.dueAt)
/// ```
/// ถ้าส่ง [now] จะคำนวณจากค่านั้น (ไว้เทสต์) ไม่ส่งใช้เวลาปัจจุบัน
class OverdueBanner extends StatelessWidget {
  const OverdueBanner({super.key, required this.dueAt, this.now});

  final DateTime dueAt;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    final late = (now ?? DateTime.now()).difference(dueAt);
    final text = late.inMinutes < 1
        ? 'เกินเวลา · เลยกำหนด ${formatThaiClock(dueAt)} น.'
        : 'เกินเวลา ${formatDuration(late)} · กำหนด ${formatThaiClock(dueAt)} น.';
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: status.overdueContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: status.overdue, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.alarm_off, color: status.overdue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: status.overdue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

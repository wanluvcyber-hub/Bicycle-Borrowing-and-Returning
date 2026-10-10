import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;
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
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.alarm_off, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

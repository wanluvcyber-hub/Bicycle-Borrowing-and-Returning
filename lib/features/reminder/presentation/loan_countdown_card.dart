import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/time_format.dart';
import '../data/reminder_schedule.dart';
import 'countdown_format.dart';

/// การ์ดนับเวลาถอยหลังของรายการยืม (เดินทุกวินาที)
///
/// เริ่มนับตั้งแต่ [borrowedAt] จนถึง [dueAt] · ข้อมูลทั้งหมดมาจากเซิร์ฟเวอร์ ปิดแอปเปิดใหม่จึงตรงเดิม
/// **ไม่แสดงรหัสล็อก** (หน้ายืมของคนที่ 2 แสดงแยกเอง)
class LoanCountdownCard extends StatefulWidget {
  const LoanCountdownCard({
    super.key,
    required this.bikeNo,
    required this.borrowedAt,
    required this.dueAt,
    this.clock = DateTime.now,
  });

  final String bikeNo;
  final DateTime borrowedAt;
  final DateTime dueAt;

  /// ฟังก์ชันบอกเวลาปัจจุบัน (ใส่ค่าอื่นไว้เทสต์)
  final DateTime Function() clock;

  @override
  State<LoanCountdownCard> createState() => _LoanCountdownCardState();
}

class _LoanCountdownCardState extends State<LoanCountdownCard> {
  Timer? _timer;
  late DateTime _now = widget.clock();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = widget.clock());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = phaseFor(widget.dueAt, _now);
    final left = widget.dueAt.difference(_now);

    final (bg, fg) = switch (phase) {
      LoanPhase.normal => (scheme.primaryContainer, scheme.onPrimaryContainer),
      LoanPhase.soon => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      LoanPhase.urgent ||
      LoanPhase.overdue => (scheme.errorContainer, scheme.onErrorContainer),
    };

    final total = widget.dueAt.difference(widget.borrowedAt).inSeconds;
    final used = _now.difference(widget.borrowedAt).inSeconds;
    final progress = total <= 0 ? 1.0 : (used / total).clamp(0.0, 1.0);
    final next = nextReminderMinutes(widget.dueAt, _now);

    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'จักรยาน ${widget.bikeNo}',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: fg),
            ),
            const SizedBox(height: 4),
            Text(
              phase == LoanPhase.overdue ? 'เกินเวลามาแล้ว' : 'เวลาที่เหลือ',
              style: TextStyle(color: fg),
            ),
            Semantics(
              label: formatRemaining(widget.dueAt, now: _now),
              excludeSemantics: true,
              child: Text(
                formatCountdown(left),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, color: fg),
            const SizedBox(height: 12),
            Text(
              'ยืมเมื่อ ${formatThaiClock(widget.borrowedAt)} น. · '
              'คืนภายใน ${formatThaiClock(widget.dueAt)} น.',
              style: TextStyle(color: fg),
            ),
            if (next != null)
              Text(
                'จะเตือนอีกครั้งเมื่อเหลือ $next นาที',
                style: TextStyle(color: fg),
              ),
            if (phase == LoanPhase.overdue) ...[
              const SizedBox(height: 12),
              const Text('กรุณาคืนจักรยานที่ป้อมยามโดยเร็ว'),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/design_widgets.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.status;
    final phase = phaseFor(widget.dueAt, _now);
    final left = widget.dueAt.difference(_now);

    // ช่วงสี 4 ช่วงตามดีไซน์: ปกติ (เขียว) · ใกล้หมด (เหลืองส้มอ่อน) · เร่งด่วน/เกินเวลา (แดง + กรอบ)
    final (bg, fg, pill) = switch (phase) {
      LoanPhase.normal => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        'ปกติ',
      ),
      LoanPhase.soon => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        'ใกล้หมดเวลา',
      ),
      LoanPhase.urgent => (status.overdueContainer, status.overdue, 'เร่งด่วน'),
      LoanPhase.overdue => (
        status.overdueContainer,
        status.overdue,
        'เกินเวลา',
      ),
    };
    final alert = phase == LoanPhase.urgent || phase == LoanPhase.overdue;

    final total = widget.dueAt.difference(widget.borrowedAt).inSeconds;
    final used = _now.difference(widget.borrowedAt).inSeconds;
    final progress = total <= 0 ? 1.0 : (used / total).clamp(0.0, 1.0);
    final next = nextReminderMinutes(widget.dueAt, _now);
    final small = theme.textTheme.bodyMedium?.copyWith(color: fg);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: alert ? Border.all(color: status.overdue, width: 2) : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(alert ? Icons.alarm_off : Icons.timer_outlined, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'จักรยาน ${widget.bikeNo}',
                  style: theme.textTheme.titleMedium?.copyWith(color: fg),
                ),
              ),
              StatusPill(
                label: pill,
                color: fg,
                background: fg.withValues(alpha: 0.16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              phase == LoanPhase.overdue ? 'เกินเวลามาแล้ว' : 'เวลาที่เหลือ',
              style: small,
            ),
          ),
          Center(
            child: Semantics(
              label: formatRemaining(widget.dueAt, now: _now),
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatCountdown(left),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: fg,
                    fontSize: 44,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: fg,
              backgroundColor: fg.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ยืมเมื่อ ${formatThaiClock(widget.borrowedAt)} น.',
                style: small,
              ),
              Text(
                'คืนภายใน ${formatThaiClock(widget.dueAt)} น.',
                style: small?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: fg,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'จะเตือนอีกครั้งเมื่อเหลือ $next นาที',
                      style: small,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (phase == LoanPhase.overdue) ...[
            const SizedBox(height: 12),
            Text(
              'กรุณาคืนจักรยานที่ป้อมยามโดยเร็ว',
              style: small?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

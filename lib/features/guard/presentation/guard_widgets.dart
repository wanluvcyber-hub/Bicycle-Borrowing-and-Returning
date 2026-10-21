import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/design_widgets.dart';
import '../data/guard_models.dart';

/// สีประจำบทบาทป้อมรปภ. = ส้ม (ตามแผน) · ห้ามใช้เป็นสีเตือน เตือน/เกินเวลาใช้แดง (AppStatusColors.overdue)
const guardColor = AppTheme.guardColor;

final _timeFormat = DateFormat('dd/MM HH:mm');

String formatTime(DateTime? t) => t == null ? '-' : _timeFormat.format(t);

const _status = AppStatusColors.standard;

Color bikeStatusColor(BikeStatus status, {bool overdue = false}) {
  if (overdue) return _status.overdue;
  return switch (status) {
    BikeStatus.available => _status.available,
    BikeStatus.borrowed => _status.borrowed,
    BikeStatus.broken => _status.broken,
  };
}

Color bikeStatusBackground(BikeStatus status, {bool overdue = false}) {
  if (overdue) return _status.overdueContainer;
  return switch (status) {
    BikeStatus.available => _status.availableContainer,
    BikeStatus.borrowed => _status.borrowedContainer,
    BikeStatus.broken => _status.brokenContainer,
  };
}

IconData bikeStatusIcon(BikeStatus status, {bool overdue = false}) {
  if (overdue) return Icons.alarm_off;
  return switch (status) {
    BikeStatus.available => Icons.check_circle,
    BikeStatus.borrowed => Icons.pedal_bike,
    BikeStatus.broken => Icons.build,
  };
}

/// ป้ายสถานะ (ไอคอน + ข้อความ + สี)
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, color: color, icon: icon);
}

/// การ์ดแสดงผู้ยืม + เวลา ใช้ทั้งหน้ารับคืนและแดชบอร์ด
class LoanDetails extends StatelessWidget {
  const LoanDetails({super.key, required this.loan, required this.now});

  final GuardLoan loan;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = loan.isOverdue(now);
    Widget line(
      IconData icon,
      String text, {
      Color? color,
      FontWeight? weight,
    }) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: weight,
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loan.studentName ?? '-',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        line(Icons.badge_outlined, 'รหัส ${loan.studentId}'),
        if (loan.roomLabel.isNotEmpty) line(Icons.apartment, loan.roomLabel),
        line(
          Icons.schedule,
          'ยืม ${formatTime(loan.borrowedAt)} · กำหนดคืน ${formatTime(loan.dueAt)}',
        ),
        if (overdue)
          line(
            Icons.alarm_off,
            'เกินเวลา',
            color: _status.overdue,
            weight: FontWeight.w700,
          ),
      ],
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => ErrorNotice(message);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/design_widgets.dart';
import '../data/borrow_models.dart';

/// สีประจำบทบาทนิสิต = เขียว (ตามแผน)
const studentColor = Colors.green;

final _dateFormat = DateFormat('dd/MM/yyyy');
final _timeFormat = DateFormat('HH:mm');

String formatDate(DateTime t) => _dateFormat.format(t);

/// เวลาแบบ 21.00 น.
String formatClock(DateTime t) =>
    '${_timeFormat.format(t).replaceAll(':', '.')} น.';

/// เวลาที่เหลือ/เกิน เช่น "เหลือ 2 ชม. 5 นาที" หรือ "เกินเวลา 10 นาที"
String formatRemaining(Duration remaining) {
  final overdue = remaining.isNegative || remaining == Duration.zero;
  final d = overdue ? -remaining : remaining;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final text = h > 0 ? '$h ชม. $m นาที' : '${d.inMinutes} นาที';
  return overdue ? 'เกินเวลา $text' : 'เหลือ $text';
}

/// สีสถานะตามดีไซน์ (ว่าง=เขียว · ถูกยืม=น้ำเงิน · ชำรุด=เทาเข้ม)
Color availabilityColor(BikeAvailability status) => switch (status) {
  BikeAvailability.available => const Color(0xFF2E7D32),
  BikeAvailability.borrowed => const Color(0xFF1565C0),
  BikeAvailability.broken => const Color(0xFF424242),
};

Color availabilityBackground(BikeAvailability status) => switch (status) {
  BikeAvailability.available => const Color(0xFFE8F5E9),
  BikeAvailability.borrowed => const Color(0xFFE3F2FD),
  BikeAvailability.broken => const Color(0xFFEEEEEE),
};

IconData availabilityIcon(BikeAvailability status) => switch (status) {
  BikeAvailability.available => Icons.check_circle,
  BikeAvailability.borrowed => Icons.pedal_bike,
  BikeAvailability.broken => Icons.build,
};

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

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => ErrorNotice(message);
}

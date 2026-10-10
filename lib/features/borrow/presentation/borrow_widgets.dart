import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/borrow_models.dart';

/// สีประจำบทบาทนิสิต = เขียว (ตามแผน)
const studentColor = Colors.green;

final _dateFormat = DateFormat('dd/MM/yyyy');
final _timeFormat = DateFormat('HH:mm');

String formatDate(DateTime t) => _dateFormat.format(t);

/// เวลาแบบ 21.00 น.
String formatClock(DateTime t) => '${_timeFormat.format(t).replaceAll(':', '.')} น.';

/// เวลาที่เหลือ/เกิน เช่น "เหลือ 2 ชม. 5 นาที" หรือ "เกินเวลา 10 นาที"
String formatRemaining(Duration remaining) {
  final overdue = remaining.isNegative || remaining == Duration.zero;
  final d = overdue ? -remaining : remaining;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final text = h > 0 ? '$h ชม. $m นาที' : '${d.inMinutes} นาที';
  return overdue ? 'เกินเวลา $text' : 'เหลือ $text';
}

Color availabilityColor(BikeAvailability status) => switch (status) {
      BikeAvailability.available => Colors.green,
      BikeAvailability.borrowed => Colors.blue,
      BikeAvailability.broken => Colors.grey,
    };

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

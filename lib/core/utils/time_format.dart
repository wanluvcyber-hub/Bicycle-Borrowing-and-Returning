// ฟังก์ชันจัดรูปแบบเวลาที่ทุกฝั่งใช้เหมือนกัน

String _two(int n) => n.toString().padLeft(2, '0');

/// 21:00
String formatClock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// 10/10/2569 21:00 (ปีพุทธศักราช)
String formatDateTime(DateTime t) =>
    '${_two(t.day)}/${_two(t.month)}/${t.year + 543} ${formatClock(t)}';

/// "2 ชม. 15 นาที" · "15 นาที" · "ไม่ถึง 1 นาที"
String formatDuration(Duration d) {
  final minutes = d.abs().inMinutes;
  if (minutes < 1) return 'ไม่ถึง 1 นาที';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m นาที';
  if (m == 0) return '$h ชม.';
  return '$h ชม. $m นาที';
}

/// "เหลือ 2 ชม. 15 นาที" · "เหลือไม่ถึง 1 นาที" · "เกินเวลา 30 นาที" เมื่อเลย [due] แล้ว
String formatRemaining(DateTime due, {DateTime? now}) {
  final diff = due.difference(now ?? DateTime.now());
  if (diff.abs().inMinutes < 1) {
    return diff.isNegative ? 'เพิ่งเกินเวลา' : 'เหลือไม่ถึง 1 นาที';
  }
  return diff.isNegative
      ? 'เกินเวลา ${formatDuration(diff)}'
      : 'เหลือ ${formatDuration(diff)}';
}

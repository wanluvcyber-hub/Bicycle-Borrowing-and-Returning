/// 01:05:09 · เกิน 1 ชม. ก็ยังแสดงเป็น ชม:นาที:วินาที (ติดลบใช้ค่าสัมบูรณ์ ผู้เรียกใส่คำว่า "เกิน" เอง)
String formatCountdown(Duration d) {
  final total = d.abs().inSeconds;
  final h = (total ~/ 3600).toString().padLeft(2, '0');
  final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

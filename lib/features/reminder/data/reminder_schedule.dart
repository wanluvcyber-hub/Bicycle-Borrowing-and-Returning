/// ก่อนครบกำหนดคืนกี่นาทีถึงจะเตือน (เรียงจากไกลไปใกล้) = 20.30 และ 20.50 น. เมื่อกำหนดคือ 21.00 น.
const List<int> kReminderMinutes = [30, 10];

/// เหลือไม่เกินกี่นาทีถือว่า "ด่วน" (เตือนเสียงแรงขึ้น / การ์ดเป็นสีแดง)
const int kUrgentMinutes = 10;

/// id ของแจ้งเตือนทุกอัน ตั้งแบบ "คงที่" เพื่อให้ตั้งซ้ำแล้วทับของเดิม ไม่เกิดแจ้งเตือนซ้อน
/// (นิสิตยืมได้ครั้งละ 1 คัน จึงมีชุดเตือนได้ชุดเดียวเสมอ)
const int kCountdownNotificationId = 4000; // แถบนับถอยหลังที่ค้างอยู่
const int kOverdueNotificationId = 4001; // เด้งตอนครบ due_at
int reminderNotificationId(int minutesBefore) => 4100 + minutesBefore;

/// id ทั้งหมดที่ฟีเจอร์นี้เป็นเจ้าของ (ใช้ตอนยกเลิก โดยไม่ไปแตะแจ้งเตือนของฟีเจอร์อื่น)
final List<int> kAllReminderNotificationIds = List.unmodifiable([
  kCountdownNotificationId,
  kOverdueNotificationId,
  for (final m in kReminderMinutes) reminderNotificationId(m),
]);

/// เตือน 1 ครั้ง
class ReminderSlot {
  const ReminderSlot({
    required this.id,
    required this.minutesBefore,
    required this.fireAt,
  });

  final int id;
  final int minutesBefore;
  final DateTime fireAt;

  /// เตือนครั้งสุดท้ายแรงกว่าปกติ
  bool get isUrgent => minutesBefore <= kUrgentMinutes;

  @override
  String toString() => 'ReminderSlot(-${minutesBefore}m @ $fireAt)';
}

/// คำนวณว่าต้องตั้งเตือนเมื่อไหร่บ้าง · เวลาที่ผ่านไปแล้ว (หรือถึงพอดี) จะถูกข้าม
/// เช่น ยืมตอน 20:42 กำหนด 21:00 → ได้แค่ -10 (-30 ผ่านไปแล้ว)
List<ReminderSlot> planReminders(DateTime dueAt, DateTime now) => [
  for (final m in kReminderMinutes)
    if (dueAt.subtract(Duration(minutes: m)).isAfter(now))
      ReminderSlot(
        id: reminderNotificationId(m),
        minutesBefore: m,
        fireAt: dueAt.subtract(Duration(minutes: m)),
      ),
];

/// ช่วงของรายการยืม ใช้เปลี่ยนสี/ข้อความบนหน้าจอ
enum LoanPhase {
  /// เหลือเวลาเยอะ
  normal,

  /// เข้าช่วงเตือน (เหลือ ≤ 30 นาที)
  soon,

  /// เหลือ ≤ [kUrgentMinutes] นาที
  urgent,

  /// เลยกำหนดแล้ว
  overdue,
}

LoanPhase phaseFor(DateTime dueAt, DateTime now) {
  final left = dueAt.difference(now);
  if (!left.isNegative && left > Duration.zero) {
    if (left <= const Duration(minutes: kUrgentMinutes)) {
      return LoanPhase.urgent;
    }
    if (left <= Duration(minutes: kReminderMinutes.first)) {
      return LoanPhase.soon;
    }
    return LoanPhase.normal;
  }
  return LoanPhase.overdue;
}

/// เตือนครั้งถัดไปคือกี่นาทีก่อนกำหนด (null = ไม่เหลือแล้ว) ใช้โชว์ "เตือนอีกครั้งตอนเหลือ ..."
int? nextReminderMinutes(DateTime dueAt, DateTime now) {
  final slots = planReminders(dueAt, now);
  return slots.isEmpty ? null : slots.first.minutesBefore;
}

/// เวลาแบบ HH:MM ตามเวลาไทย (UTC+7) ไม่ขึ้นกับโซนเวลาที่ตั้งในมือถือ
/// ประเทศไทยไม่มีเวลาออมแสง จึงบวก 7 ชม. ตายตัวได้ถูกต้องเสมอ
String formatThaiClock(DateTime t) {
  final th = t.toUtc().add(const Duration(hours: 7));
  return '${th.hour.toString().padLeft(2, '0')}:'
      '${th.minute.toString().padLeft(2, '0')}';
}

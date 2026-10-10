import '../../../core/utils/json_utils.dart';

/// รายการยืมที่เกินกำหนดคืน (ยังไม่คืนและเลย due_at)
class OverdueLoan {
  const OverdueLoan({
    required this.loanId,
    required this.bikeNo,
    required this.studentId,
    required this.dueAt,
    this.studentName,
    this.building,
    this.room,
    this.phone,
  });

  final int loanId;
  final String bikeNo;
  final String studentId;
  final DateTime dueAt;
  final String? studentName;
  final String? building;
  final String? room;
  final String? phone;

  Duration lateBy(DateTime now) => now.difference(dueAt);

  String get roomLabel => [
    if ((building ?? '').isNotEmpty) building,
    if ((room ?? '').isNotEmpty) 'ห้อง $room',
  ].join(' · ');
}

/// จักรยานชำรุด (รอซ่อม)
class BrokenBike {
  const BrokenBike({required this.bikeNo, this.note});
  final String bikeNo;
  final String? note;
}

/// เริ่มต้นวัน (00:00 เวลาไทย) ของ [now] เป็นเวลาสัมบูรณ์ ไม่ขึ้นกับโซนเวลาของเครื่อง
DateTime thaiDayStart(DateTime now) {
  final th = now.toUtc().add(const Duration(hours: 7));
  return DateTime.utc(
    th.year,
    th.month,
    th.day,
  ).subtract(const Duration(hours: 7));
}

/// ตัวเลขสรุปของหน้าแดชบอร์ดผู้ดูแล · ทุกค่าคำนวณจาก bikes / loans / students (อ่านอย่างเดียว)
class AdminDashboard {
  const AdminDashboard({
    required this.total,
    required this.available,
    required this.inUse,
    required this.broken,
    required this.overdueLoans,
    required this.brokenBikes,
    required this.borrowedToday,
    required this.returnedOnTimeToday,
    required this.returnedLateToday,
    required this.studentCount,
    required this.updatedAt,
  });

  final int total;
  final int available;
  final int inUse;
  final int broken;
  final List<OverdueLoan> overdueLoans;
  final List<BrokenBike> brokenBikes;
  final int borrowedToday;
  final int returnedOnTimeToday;
  final int returnedLateToday;
  final int studentCount;
  final DateTime updatedAt;

  int get overdue => overdueLoans.length;
  int get returnedToday => returnedOnTimeToday + returnedLateToday;

  /// อัตราหมุนเวียน = คันที่ถูกยืม ÷ คันที่ใช้งานได้ (ไม่นับคันชำรุด) · 0 ถ้าไม่มีคันใช้งานได้
  double get utilization {
    final usable = total - broken;
    return usable <= 0 ? 0 : (inUse / usable).clamp(0.0, 1.0);
  }

  /// สัดส่วนคืนตรงเวลาของวันนี้ · null = วันนี้ยังไม่มีการคืน
  double? get onTimeRate =>
      returnedToday == 0 ? null : returnedOnTimeToday / returnedToday;

  /// คำนวณจากแถวที่ดึงมา (แยกเป็นฟังก์ชันล้วนเพื่อเทสต์ได้)
  factory AdminDashboard.fromRows({
    required List<Map<String, dynamic>> bikes,
    required List<Map<String, dynamic>> loans,
    required int studentCount,
    required DateTime now,
  }) {
    final dayStart = thaiDayStart(now);
    var available = 0, inUse = 0, broken = 0;
    final brokenBikes = <BrokenBike>[];
    for (final b in bikes) {
      switch (b['status']) {
        case 'available':
          available++;
        case 'borrowed':
          inUse++;
        case 'broken':
          broken++;
          brokenBikes.add(
            BrokenBike(
              bikeNo: b['bike_no'] as String,
              note: b['note'] as String?,
            ),
          );
      }
    }
    brokenBikes.sort((a, b) => a.bikeNo.compareTo(b.bikeNo));

    final overdueLoans = <OverdueLoan>[];
    var borrowedToday = 0, onTime = 0, late = 0;
    for (final l in loans) {
      final borrowedAt = parseDateTime(l['borrowed_at']);
      final dueAt = parseDateTime(l['due_at']);
      final returnedAt = parseDateTimeOrNull(l['returned_at']);
      if (!borrowedAt.isBefore(dayStart)) borrowedToday++;
      if (returnedAt != null) {
        if (!returnedAt.isBefore(dayStart)) {
          (l['is_late'] as bool? ?? false) ? late++ : onTime++;
        }
      } else if (dueAt.isBefore(now)) {
        final s = l['students'];
        final st = s is Map ? s : const {};
        overdueLoans.add(
          OverdueLoan(
            loanId: (l['loan_id'] as num).toInt(),
            bikeNo: l['bike_no'] as String,
            studentId: l['student_id'] as String,
            dueAt: dueAt,
            studentName: st['full_name'] as String?,
            building: st['building'] as String?,
            room: st['room'] as String?,
            phone: st['phone'] as String?,
          ),
        );
      }
    }
    // เกินนานสุดก่อน
    overdueLoans.sort((a, b) => a.dueAt.compareTo(b.dueAt));

    return AdminDashboard(
      total: bikes.length,
      available: available,
      inUse: inUse,
      broken: broken,
      overdueLoans: overdueLoans,
      brokenBikes: brokenBikes,
      borrowedToday: borrowedToday,
      returnedOnTimeToday: onTime,
      returnedLateToday: late,
      studentCount: studentCount,
      updatedAt: now,
    );
  }
}

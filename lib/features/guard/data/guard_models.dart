// โมเดลของโปรแกรมป้อมยาม (process 5.0 / 6.0)
// ชื่อฟิลด์และค่าสถานะตาม docs/database.md หัวข้อ 2 และ 7
// ทำไว้ในโฟลเดอร์ guard เองก่อน เพราะ lib/core/models/ ของคนที่ 1 ยังว่างอยู่

enum BikeStatus {
  available('ว่าง'),
  borrowed('ถูกยืม'),
  broken('ชำรุด');

  const BikeStatus(this.label);
  final String label;

  static BikeStatus fromDb(String? value) => switch (value) {
        'borrowed' => BikeStatus.borrowed,
        'broken' => BikeStatus.broken,
        _ => BikeStatus.available,
      };
}

/// ผลตรวจสภาพตอนรับคืน (ค่าในฐานข้อมูล: normal / damaged)
enum ReturnCondition {
  normal('normal', 'ปกติ'),
  damaged('damaged', 'ชำรุด');

  const ReturnCondition(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static ReturnCondition? fromDb(String? value) => switch (value) {
        'normal' => ReturnCondition.normal,
        'damaged' => ReturnCondition.damaged,
        _ => null,
      };
}

DateTime? _parseTime(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toLocal();

/// รายการยืม พร้อมข้อมูลผู้ยืม (join จากตาราง students)
class GuardLoan {
  const GuardLoan({
    required this.loanId,
    required this.studentId,
    required this.bikeNo,
    required this.borrowedAt,
    required this.dueAt,
    this.returnedAt,
    this.condition,
    this.isLate = false,
    this.studentName,
    this.building,
    this.room,
    this.phone,
  });

  factory GuardLoan.fromJson(Map<String, dynamic> json) {
    final student = json['students'] as Map<String, dynamic>?;
    return GuardLoan(
      loanId: (json['loan_id'] as num).toInt(),
      studentId: json['student_id'] as String,
      bikeNo: json['bike_no'] as String,
      borrowedAt: _parseTime(json['borrowed_at'])!,
      dueAt: _parseTime(json['due_at'])!,
      returnedAt: _parseTime(json['returned_at']),
      condition: ReturnCondition.fromDb(json['condition'] as String?),
      isLate: json['is_late'] as bool? ?? false,
      studentName: student?['full_name'] as String?,
      building: student?['building'] as String?,
      room: student?['room'] as String?,
      phone: student?['phone'] as String?,
    );
  }

  final int loanId;
  final String studentId;
  final String bikeNo;
  final DateTime borrowedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final ReturnCondition? condition;
  final bool isLate;
  final String? studentName;
  final String? building;
  final String? room;
  final String? phone;

  bool get isActive => returnedAt == null;

  /// เกินเวลาตัดสินจาก due_at เทียบเวลาปัจจุบัน ไม่พึ่งคอลัมน์ status
  /// เพราะ mark_overdue_loans() อาจยังไม่ได้รัน
  bool isOverdue(DateTime now) => isActive && dueAt.isBefore(now);

  String get roomLabel => [
        if (building != null && building!.isNotEmpty) building,
        if (room != null && room!.isNotEmpty) room,
      ].join(' ห้อง ');
}

/// จักรยาน 1 คัน พร้อมรายการยืมที่ค้างอยู่ (ถ้ามี)
class GuardBike {
  const GuardBike({
    required this.bikeNo,
    required this.status,
    this.station,
    this.note,
    this.activeLoan,
  });

  factory GuardBike.fromJson(Map<String, dynamic> json, {GuardLoan? activeLoan}) =>
      GuardBike(
        bikeNo: json['bike_no'] as String,
        status: BikeStatus.fromDb(json['status'] as String?),
        station: json['station'] as String?,
        note: json['note'] as String?,
        activeLoan: activeLoan,
      );

  final String bikeNo;
  final BikeStatus status;
  final String? station;
  final String? note;
  final GuardLoan? activeLoan;

  bool isOverdue(DateTime now) => activeLoan?.isOverdue(now) ?? false;
}

/// ตัวกรองในแดชบอร์ด
enum BikeFilter {
  all('ทั้งหมด'),
  available('ว่าง'),
  inUse('กำลังถูกใช้'),
  broken('ชำรุด'),
  overdue('เกินเวลา');

  const BikeFilter(this.label);
  final String label;

  bool matches(GuardBike bike, DateTime now) => switch (this) {
        BikeFilter.all => true,
        BikeFilter.available => bike.status == BikeStatus.available,
        BikeFilter.inUse => bike.status == BikeStatus.borrowed,
        BikeFilter.broken => bike.status == BikeStatus.broken,
        BikeFilter.overdue => bike.isOverdue(now),
      };
}

/// ตัวเลขสรุปบนแดชบอร์ด · "เกินเวลา" เป็นส่วนหนึ่งของ "กำลังถูกใช้"
class DashboardSummary {
  const DashboardSummary({
    required this.total,
    required this.available,
    required this.inUse,
    required this.broken,
    required this.overdue,
  });

  factory DashboardSummary.from(List<GuardBike> bikes, DateTime now) =>
      DashboardSummary(
        total: bikes.length,
        available: bikes.where((b) => b.status == BikeStatus.available).length,
        inUse: bikes.where((b) => b.status == BikeStatus.borrowed).length,
        broken: bikes.where((b) => b.status == BikeStatus.broken).length,
        overdue: bikes.where((b) => b.isOverdue(now)).length,
      );

  final int total;
  final int available;
  final int inUse;
  final int broken;
  final int overdue;
}

/// ผลลัพธ์ของ return_bike
class ReturnResult {
  const ReturnResult({
    required this.loanId,
    required this.studentId,
    required this.bikeNo,
    required this.returnedAt,
    required this.isLate,
    required this.condition,
  });

  factory ReturnResult.fromJson(Map<String, dynamic> json) => ReturnResult(
        loanId: (json['loan_id'] as num).toInt(),
        studentId: json['student_id'] as String,
        bikeNo: json['bike_no'] as String,
        returnedAt: _parseTime(json['returned_at'])!,
        isLate: json['is_late'] as bool? ?? false,
        condition: ReturnCondition.fromDb(json['condition'] as String?) ??
            ReturnCondition.normal,
      );

  final int loanId;
  final String studentId;
  final String bikeNo;
  final DateTime returnedAt;
  final bool isLate;
  final ReturnCondition condition;
}

/// ผลค้นประวัติของนิสิต 1 คน
class StudentHistory {
  const StudentHistory({
    required this.studentId,
    required this.fullName,
    required this.lateCount,
    required this.loans,
  });

  final String studentId;
  final String fullName;
  final int lateCount;

  /// เรียงล่าสุดก่อน
  final List<GuardLoan> loans;
}

import '../utils/json_utils.dart';

/// สถานะรายการยืม (`loans.status`)
enum LoanStatus {
  borrowing('borrowing', 'กำลังยืม'),
  overdue('overdue', 'เกินเวลา'),
  returned('returned', 'คืนแล้ว');

  const LoanStatus(this.dbValue, this.labelTh);
  final String dbValue;
  final String labelTh;

  static LoanStatus fromDb(String value) => values.firstWhere(
    (s) => s.dbValue == value,
    orElse: () => throw FormatException('loans.status ไม่รู้จัก: $value'),
  );
}

/// ผลตรวจสภาพตอนรับคืน (`loans.condition`)
enum LoanCondition {
  normal('normal', 'ปกติ'),
  damaged('damaged', 'ชำรุด');

  const LoanCondition(this.dbValue, this.labelTh);
  final String dbValue;
  final String labelTh;

  static LoanCondition fromDb(String value) => values.firstWhere(
    (s) => s.dbValue == value,
    orElse: () => throw FormatException('loans.condition ไม่รู้จัก: $value'),
  );
}

/// แถวของตาราง `loans`
class Loan {
  const Loan({
    required this.loanId,
    required this.studentId,
    required this.bikeNo,
    required this.borrowedAt,
    required this.dueAt,
    this.returnedAt,
    this.receivedBy,
    this.condition,
    required this.status,
    this.isLate = false,
  });

  final int loanId;
  final String studentId;
  final String bikeNo;
  final DateTime borrowedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final String? receivedBy;
  final LoanCondition? condition;
  final LoanStatus status;
  final bool isLate;

  /// เกินเวลาแล้วหรือยัง (ฐานข้อมูลอาจยังเป็น `borrowing` อยู่จนกว่า `mark_overdue_loans` จะรัน)
  bool isOverdueAt(DateTime now) =>
      returnedAt == null &&
      (status == LoanStatus.overdue || now.isAfter(dueAt));

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    loanId: (json['loan_id'] as num).toInt(),
    studentId: json['student_id'] as String,
    bikeNo: json['bike_no'] as String,
    borrowedAt: parseDateTime(json['borrowed_at']),
    dueAt: parseDateTime(json['due_at']),
    returnedAt: parseDateTimeOrNull(json['returned_at']),
    receivedBy: json['received_by'] as String?,
    condition: json['condition'] == null
        ? null
        : LoanCondition.fromDb(json['condition'] as String),
    status: LoanStatus.fromDb(json['status'] as String),
    isLate: (json['is_late'] as bool?) ?? false,
  );
}

/// ผลของ `borrow_bike` / `get_my_active_loan` · มีรหัสล็อก
/// **ห้ามเก็บลงเครื่อง/ไฟล์/log** ดึงใหม่จาก `get_my_active_loan` ทุกครั้งที่จะแสดง
class ActiveLoan {
  const ActiveLoan({
    required this.loanId,
    required this.bikeNo,
    required this.lockCode,
    required this.borrowedAt,
    required this.dueAt,
    this.status = LoanStatus.borrowing,
  });

  final int loanId;
  final String bikeNo;
  final String lockCode;
  final DateTime borrowedAt;
  final DateTime dueAt;

  /// `borrow_bike` ไม่ส่งมา จึงใช้ `borrowing` เป็นค่าเริ่มต้น
  final LoanStatus status;

  bool isOverdueAt(DateTime now) =>
      status == LoanStatus.overdue || now.isAfter(dueAt);

  factory ActiveLoan.fromJson(Map<String, dynamic> json) => ActiveLoan(
    loanId: (json['loan_id'] as num).toInt(),
    bikeNo: json['bike_no'] as String,
    lockCode: json['lock_code'] as String,
    borrowedAt: parseDateTime(json['borrowed_at']),
    dueAt: parseDateTime(json['due_at']),
    status: json['status'] == null
        ? LoanStatus.borrowing
        : LoanStatus.fromDb(json['status'] as String),
  );

  // ไม่ override toString เพื่อไม่ให้รหัสล็อกหลุดลง log โดยไม่ตั้งใจ
}

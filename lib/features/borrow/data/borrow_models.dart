// โมเดลฝั่งนิสิต (process 2.0 / 3.0) · ชื่อฟิลด์ตาม docs/database.md
// ทำไว้ในโฟลเดอร์ borrow เองก่อน เพราะ lib/core/models/ ของคนที่ 1 ยังว่างอยู่

/// สถานะจักรยานที่แสดงให้นิสิต (bikes.status)
enum BikeAvailability {
  available('ว่าง'),
  borrowed('ถูกยืม'),
  broken('ชำรุด');

  const BikeAvailability(this.label);
  final String label;

  static BikeAvailability fromDb(String? value) => switch (value) {
        'borrowed' => BikeAvailability.borrowed,
        'broken' => BikeAvailability.broken,
        _ => BikeAvailability.available,
      };
}

class BorrowBike {
  const BorrowBike({
    required this.bikeNo,
    required this.status,
    this.station,
  });

  factory BorrowBike.fromJson(Map<String, dynamic> json) => BorrowBike(
        bikeNo: json['bike_no'] as String,
        status: BikeAvailability.fromDb(json['status'] as String?),
        station: json['station'] as String?,
      );

  final String bikeNo;
  final BikeAvailability status;
  final String? station;
}

/// ข้อมูลนิสิตเจ้าของบัญชีที่ล็อกอิน ใช้แสดงในหน้ายืนยัน (อ่านอย่างเดียว ห้ามให้พิมพ์เอง)
class StudentProfile {
  const StudentProfile({
    required this.studentId,
    required this.fullName,
    this.building,
    this.room,
    this.phone,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        studentId: json['student_id'] as String,
        fullName: json['full_name'] as String,
        building: json['building'] as String?,
        room: json['room'] as String?,
        phone: json['phone'] as String?,
      );

  StudentProfile withPhone(String phone) => StudentProfile(
        studentId: studentId,
        fullName: fullName,
        building: building,
        room: room,
        phone: phone,
      );

  final String studentId;
  final String fullName;
  final String? building;
  final String? room;
  final String? phone;
}

/// รายการที่ตัวเองยืมค้าง (ผลของ borrow_bike / get_my_active_loan)
/// มีรหัสล็อก: เก็บในหน่วยความจำเท่านั้น ห้ามเขียนลงไฟล์/log/SharedPreferences
class MyLoan {
  const MyLoan({
    required this.loanId,
    required this.bikeNo,
    required this.lockCode,
    required this.borrowedAt,
    required this.dueAt,
  });

  factory MyLoan.fromJson(Map<String, dynamic> json) => MyLoan(
        loanId: (json['loan_id'] as num).toInt(),
        bikeNo: json['bike_no'] as String,
        lockCode: json['lock_code'] as String?,
        borrowedAt: DateTime.parse(json['borrowed_at'] as String).toLocal(),
        dueAt: DateTime.parse(json['due_at'] as String).toLocal(),
      );

  final int loanId;
  final String bikeNo;
  final String? lockCode;
  final DateTime borrowedAt;
  final DateTime dueAt;

  /// เวลาที่เหลือคำนวณจาก due_at เสมอ ไม่นับถอยหลังจากตัวเลขในเครื่อง
  Duration remaining(DateTime now) => dueAt.difference(now);

  bool isOverdue(DateTime now) => !dueAt.isAfter(now);

  // ไม่พิมพ์รหัสล็อกเวลา toString / log
  @override
  String toString() => 'MyLoan(loanId: $loanId, bikeNo: $bikeNo)';
}

enum BorrowOutcome { success, failed }

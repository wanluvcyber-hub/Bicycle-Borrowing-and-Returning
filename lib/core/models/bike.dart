/// สถานะจักรยาน (`bikes.status`)
enum BikeStatus {
  available('available', 'ว่าง'),
  borrowed('borrowed', 'ถูกยืม'),
  broken('broken', 'ชำรุด');

  const BikeStatus(this.dbValue, this.labelTh);
  final String dbValue;
  final String labelTh;

  static BikeStatus fromDb(String value) => values.firstWhere(
    (s) => s.dbValue == value,
    orElse: () => throw FormatException('bikes.status ไม่รู้จัก: $value'),
  );
}

/// แถวของตาราง `bikes` · **ไม่มีรหัสล็อก** (อยู่ใน `bike_locks` แยกต่างหาก)
class Bike {
  const Bike({
    required this.bikeNo,
    required this.qrCode,
    this.station,
    required this.status,
    this.note,
  });

  final String bikeNo;
  final String qrCode;
  final String? station;
  final BikeStatus status;
  final String? note;

  factory Bike.fromJson(Map<String, dynamic> json) => Bike(
    bikeNo: json['bike_no'] as String,
    qrCode: json['qr_code'] as String,
    station: json['station'] as String?,
    status: BikeStatus.fromDb(json['status'] as String),
    note: json['note'] as String?,
  );
}

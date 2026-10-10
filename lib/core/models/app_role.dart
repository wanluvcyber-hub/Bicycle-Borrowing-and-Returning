/// บทบาทของผู้ใช้ในแอป: เจ้าหน้าที่ดูจาก `staff.role` ส่วนนิสิตคือคนที่ผูกบัญชีหอในได้
enum AppRole {
  student('นิสิต'),
  guard('ป้อมยาม'),
  admin('ผู้ดูแลระบบ');

  const AppRole(this.labelTh);
  final String labelTh;

  /// ค่า `staff.role`: `guard` หรือ `admin`
  static AppRole fromStaffRole(String value) => switch (value) {
    'guard' => AppRole.guard,
    'admin' => AppRole.admin,
    _ => throw FormatException('staff.role ไม่รู้จัก: $value'),
  };
}

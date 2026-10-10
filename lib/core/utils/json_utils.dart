/// เวลาใน JSON เป็น ISO 8601 (UTC) แปลงเป็นเวลาในเครื่องก่อนแสดง
DateTime parseDateTime(Object? value) =>
    DateTime.parse(value as String).toLocal();

DateTime? parseDateTimeOrNull(Object? value) =>
    value == null ? null : parseDateTime(value);

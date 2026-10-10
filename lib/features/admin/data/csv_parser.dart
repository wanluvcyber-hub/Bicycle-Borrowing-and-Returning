/// แยก CSV (RFC 4180 แบบย่อ): รองรับเครื่องหมายคำพูด, คอมมาในช่อง, ขึ้นบรรทัดใหม่ในช่อง, CRLF, BOM
/// คืนทุกแถวรวมแถวหัวคอลัมน์ · ข้ามบรรทัดว่างล้วน
List<List<String>> parseCsv(String input) {
  final text = input.startsWith('﻿') ? input.substring(1) : input;
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var fieldStarted =
      false; // เห็นอะไรในแถวนี้แล้วหรือยัง (กันนับบรรทัดว่างเป็นแถว)

  void endField() {
    row.add(field.toString());
    field.clear();
    fieldStarted = true;
  }

  void endRow() {
    if (fieldStarted || field.isNotEmpty) {
      endField();
      if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
    }
    row = <String>[];
    fieldStarted = false;
  }

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
      fieldStarted = true;
    } else if (c == ',') {
      endField();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
    } else {
      field.write(c);
      fieldStarted = true;
    }
  }
  endRow();
  return rows;
}

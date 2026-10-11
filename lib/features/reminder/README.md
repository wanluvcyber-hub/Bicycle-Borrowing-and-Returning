# features/reminder · คนที่ 4
Process 4.0 แจ้งเตือนเวลาคืน + สถานะเกินเวลา · รายละเอียดงานอยู่ที่ docs/person-4-reminder-test-docs.md

| ไฟล์ | หน้าที่ |
|---|---|
| `data/reminder_schedule.dart` | logic ล้วน: คำนวณเวลาเตือน (30/10), id คงที่, ช่วง normal/soon/urgent/overdue |
| `data/notification_gateway.dart` | ด่านเดียวที่คุยกับ plugin (ตั้ง/โชว์/ยกเลิก) |
| `data/reminder_service.dart` | `scheduleForLoan` · `cancelAll` · `syncWithServer` |
| `data/active_loan_source.dart` | เรียก `get_my_active_loan()` |
| `state/reminder_provider.dart` | ถือรายการที่ยืมค้าง + `refresh` / `startLoan` / `clear` |
| `presentation/loan_countdown_card.dart` | การ์ดนับถอยหลังเดินทุกวินาที |
| `presentation/overdue_banner.dart` | แถบ "เกินเวลา" กลาง (นิสิต + ป้อมรปภ.) |
| `presentation/reminder_lifecycle.dart` | ซิงก์ตอนเปิดหน้า/กลับจากพื้นหลัง |

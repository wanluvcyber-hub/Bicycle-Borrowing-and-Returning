# ระบบยืม-คืนจักรยานหอใน (bike_loan)

แอปพลิเคชันมือถือสำหรับนิสิตหอพักในมหาวิทยาลัยนเรศวร ใช้ยืมจักรยานของหอพักด้วยตนเองผ่านการสแกน QR บนตัวจักรยาน
และคืนที่ป้อมยามซึ่งมีโปรแกรมสำหรับตรวจสภาพและบันทึกการรับคืน

โปรเจกต์รายวิชา Mobile Application · พัฒนาด้วย Flutter และ Supabase

## ฟังก์ชันหลัก

**นิสิต**
- ดูจำนวนจักรยานว่างและสถานะแต่ละคัน (อัปเดตสดเมื่อมีการยืม/คืน)
- สแกน QR (หรือพิมพ์เลขคัน) เพื่อยืม · ยืมได้ครั้งละ 1 คัน
- รับรหัสล็อกล้อและดูเวลานับถอยหลังถึงกำหนดคืน 21:00 น. (ปิดแอปแล้วเปิดใหม่ข้อมูลยังอยู่)
- แจ้งเตือนก่อนถึงกำหนดคืน 30 และ 10 นาที, เตือนเมื่อเกินเวลา และมีแถบนับถอยหลังในแถบแจ้งเตือน

**ป้อมยาม**
- แดชบอร์ดสรุปสถานะจักรยานทุกคัน พร้อมรายการที่เกินเวลาและข้อมูลผู้ยืม
- รับคืนและตรวจสภาพ (ปกติ/ชำรุด พร้อมหมายเหตุ) โดยเห็นข้อมูลผู้ยืมก่อนยืนยัน
- ค้นประวัติการยืมด้วยรหัสนิสิต

**ผู้ดูแลระบบ**
- แดชบอร์ดภาพรวม: สถานะฝูงจักรยาน อัตราหมุนเวียน รายการเกินเวลา และสถิติประจำวัน
- นำเข้ารายชื่อนิสิตหอในจากไฟล์ CSV
- จัดการจักรยาน รหัสล็อก และงานซ่อม

กฎของระบบ (ยืมได้ก่อน 21:00 น., ยืมได้ครั้งละ 1 คัน, คืนสายนับจำนวนครั้ง ฯลฯ) ถูกบังคับที่ฐานข้อมูล
แอปทำหน้าที่แสดงผลและส่งคำขอ

## เทคโนโลยี

| ส่วน | ใช้ |
|---|---|
| แอป | Flutter 3.47 (Dart 3.13), Material 3 |
| State | provider |
| นำทาง | go_router |
| ฐานข้อมูล/ล็อกอิน/Realtime | Supabase (PostgreSQL + Row Level Security) |
| สแกน QR | mobile_scanner |
| แจ้งเตือน | flutter_local_notifications, timezone |
| อื่นๆ | intl, file_picker |
| ฟอนต์ | Prompt, Noto Sans Thai (ฝังในแอป) |

## การติดตั้งและรัน

ต้องมี Flutter 3.47.x (ตรวจด้วย `flutter --version`)

```bash
git clone <ลิงก์ repo>
cd bike_loan
flutter pub get
cp env.example.json env.json       # ใส่ Supabase URL และ anon key
flutter run --dart-define-from-file=env.json
```

- `env.json` อยู่ใน `.gitignore` ไม่ต้อง commit
- VS Code: กด F5 ได้ (`.vscode/launch.json` โหลด `env.json` ให้)
- Android Studio: Run → Edit Configurations → Additional run args ใส่ `--dart-define-from-file=env.json`

### ตั้งค่า Supabase

1. สร้างโปรเจกต์ที่ supabase.com
2. ใน SQL Editor รัน `supabase/migrations/001_init.sql` แล้วรัน `supabase/seed.sql` (ข้อมูลทดสอบ จักรยาน 10 คัน นิสิต 20 คน)
3. สร้างผู้ใช้ทดสอบใน Authentication → Users แล้วรัน `seed.sql` อีกครั้งเพื่อผูกบัญชีเจ้าหน้าที่
4. คัดลอก Project URL และ anon key ไปใส่ใน `env.json`

รายละเอียดทั้งหมดอยู่ใน [docs/database.md](docs/database.md) (ตาราง, ฟังก์ชัน, สิทธิ์, รหัสข้อผิดพลาด)

บัญชีทดสอบ (ตั้งตามขั้นตอนใน database.md): `test01@example.com` (นิสิต), `guard01@example.com` (ป้อมยาม), `admin01@example.com` (ผู้ดูแลระบบ)

## การทดสอบ

```bash
flutter analyze
flutter test
```

- เทสต์อยู่ใน `test/` แบ่งตามฟีเจอร์ ไฟล์ `test/core/schema_sync_test.dart` ตรวจว่า SQL, โค้ด และ `docs/database.md` ตรงกัน
- ทดลองระบบแจ้งเตือนโดยไม่ต้องใช้ Supabase: `flutter run -t lib/features/reminder/demo/reminder_demo.dart`
- ดูหน้าของแต่ละฝั่งด้วยข้อมูลจำลอง: `lib/features/borrow/borrow_preview.dart`, `lib/features/guard/guard_preview.dart`
- ผลทดสอบและเช็กลิสต์ทดสอบรวม: [docs/test-results.md](docs/test-results.md)

## โครงสร้างโปรเจกต์

```
lib/
├─ main.dart
├─ core/              โค้ดที่ใช้ร่วมกัน: config, supabase, models, errors, router, theme, widgets, utils
└─ features/
   ├─ auth/           ล็อกอินและตรวจสิทธิ์
   ├─ admin/          หน้าผู้ดูแลระบบ
   ├─ borrow/         แอปนิสิต: ดูจักรยาน สแกน ยืม รหัสล็อก
   ├─ guard/          โปรแกรมป้อมยาม: แดชบอร์ด รับคืน ค้นประวัติ
   └─ reminder/       แจ้งเตือนก่อนถึงเวลาคืนและสถานะเกินเวลา
        (แต่ละฟีเจอร์แบ่งเป็น data/ เรียก Supabase · state/ Provider · presentation/ หน้าจอ)
test/                 เทสต์ แบ่งตามฟีเจอร์
supabase/             migrations และข้อมูลทดสอบ
assets/               ฟอนต์ ไอคอน โลโก้
docs/                 เอกสารฐานข้อมูล แผนระบบ ผลทดสอบ
```

## ผู้พัฒนา

| ผู้พัฒนา | ส่วนที่รับผิดชอบ |
|---|---|
| คนที่ 1 | ฐานข้อมูล, ล็อกอินและยืนยันสิทธิ์หอใน, หน้าผู้ดูแลระบบ, โค้ดกลาง (`core/`) |
| คนที่ 2 | แอปนิสิต: แสดงจักรยานว่าง, สแกน QR ยืม, รหัสล็อกและนับถอยหลัง |
| คนที่ 3 | โปรแกรมป้อมยาม: รับคืนและตรวจสภาพ, สรุปสถานะ, ค้นประวัติ |
| คนที่ 4 | แจ้งเตือนเวลาคืนและสถานะเกินเวลา, การทดสอบ, เอกสาร |

เอกสารแบ่งงานรายคนอยู่ใน `docs/person-*.md`

## แนวทางการทำงานร่วมกัน

- แตก branch ของงานตัวเอง (เช่น `feat/p2-scan-qr`) แล้วเปิด Pull Request ก่อนรวมเข้า `main`
- การเปลี่ยนฐานข้อมูลทำผ่านไฟล์ใหม่ใน `supabase/migrations/` และแก้ `docs/database.md` ใน PR เดียวกัน
- ก่อนเปิด PR รัน `flutter analyze` และ `flutter test` ให้ผ่าน
- ห้าม commit ความลับ: `env.json`, `service_role` key, รหัสผ่าน

## การตั้งค่า native ที่เกี่ยวข้อง

- Android: เปิด core library desugaring (ที่ `flutter_local_notifications` ต้องใช้), `minSdk = 24` (สำหรับ `mobile_scanner`), สิทธิ์ INTERNET, CAMERA, POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED และตัวรับแจ้งเตือนของ `flutter_local_notifications` ใน `AndroidManifest.xml`
- iOS: คำอธิบายการใช้กล้องใน `Info.plist`

## เอกสารเพิ่มเติม

- [docs/database.md](docs/database.md) ฐานข้อมูลและรหัสข้อผิดพลาด
- [docs/bike-system-plan.html](docs/bike-system-plan.html) แผนระบบ (Flow, DFD, Data Dictionary)
- [docs/test-results.md](docs/test-results.md) ผลการทดสอบ

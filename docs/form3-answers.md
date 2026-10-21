# ข้อมูลสำหรับกรอก Form 3: Advance Submission Sheet (MAD 1/2569)

> สร้างจากข้อมูลในโปรเจกต์เมื่อ 21 ต.ค. 2569 ช่องที่ขึ้นต้นด้วย ⬜ คือต้องกรอกเอง (ระบบหาให้ไม่ได้)
> เส้นตายส่ง: พุธ 21 ต.ค. 2569 เวลา 23:59 · ห้ามใส่ชื่อคน ใช้รหัสนักศึกษา 8 หลักเท่านั้น · ห้ามใส่รหัสผ่าน/key จริง

## ส่วนที่ 1: ข้อมูลกลุ่ม
- **Project name:** `bike_loan` (ระบบยืม-คืนจักรยานหอใน)
- **Student ID ผู้กรอก:** ⬜

## ส่วนที่ 2: Repository
- **GitHub repository link:** https://github.com/wanluvcyber-hub/Bicycle-Borrowing-and-Returning
  - ⬜ ตรวจว่า repo เป็น public หรือเพิ่มอาจารย์เป็น collaborator แล้ว
- **Commit hash:** `895de5f5196c90772490b653622cc733d5bbf959`
  - อยู่บน branch `เพิ่มเติมตรงเบอร์` (push ขึ้น origin แล้ว) ยังไม่ merge เข้า `main`
  - ⬜ ถ้ามีงานค้าง (ไฟล์ `.metadata`, `analysis_options.yaml` แก้ค้าง, `web/` และ `devtools_options.yaml` ยังไม่ commit) ให้ commit + push ก่อน แล้วดึง hash ใหม่ด้วย `git log -1 --format=%H`
- **Tag name:** (ไม่มี ข้ามได้)
- **Flutter version:** `Flutter 3.47.2 • channel stable • https://github.com/flutter/flutter.git`
- **Installation and run steps:**
  ```
  1. ติดตั้ง Flutter 3.47.x (ตรวจด้วย flutter --version)
  2. git clone https://github.com/wanluvcyber-hub/Bicycle-Borrowing-and-Returning.git && cd Bicycle-Borrowing-and-Returning
  3. git checkout 895de5f5196c90772490b653622cc733d5bbf959
  4. flutter pub get
  5. cp env.example.json env.json แล้วใส่ SUPABASE_URL และ SUPABASE_ANON_KEY (env.json อยู่ใน .gitignore ไม่ถูก commit)
  6. ตั้งค่า Supabase: สร้างโปรเจกต์ → SQL Editor รัน supabase/migrations/001_init.sql, 002_require_student_phone.sql, 002_student_profile.sql, 003_update_my_phone.sql ตามลำดับ → รัน supabase/seed.sql
  7. สร้างผู้ใช้ใน Authentication → Users: test01..test20@example.com (นิสิต), guard01@example.com (ป้อมรปภ.), admin01@example.com (ผู้ดูแล) แล้วรัน seed.sql อีกครั้งเพื่อผูกบัญชีเจ้าหน้าที่ (รายละเอียด docs/database.md)
  8. flutter run --dart-define-from-file=env.json
  ```
  - ⬜ ยืนยันลำดับไฟล์ migration (`002_*` มี 2 ไฟล์) ว่ารันตามนี้แล้วไม่ error บน Supabase เปล่า
- **Test accounts:** `test01@example.com` (นิสิต, รหัส 66000001), `guard01@example.com` (ป้อมรปภ.), `admin01@example.com` (ผู้ดูแล) · ข้อมูลตั้งต้น: จักรยาน 10 คัน นิสิต 20 คน จาก `supabase/seed.sql`
  - ⬜ รหัสผ่านบัญชีทดสอบ ส่งผ่านช่องทางส่วนตัว อย่าเขียนในฟอร์ม
- **Secure channel ส่ง key:** ⬜ (เช่น อีเมล/LINE ส่วนตัวของคนกรอก)

## ส่วนที่ 3: ฟีเจอร์ที่ผู้ใช้ขอ (R1–R5)

> ⬜ **R1–R5 ต้องเป็นรายการที่ผู้ใช้ขอจริงจาก Form 2** ผมไม่มีข้อมูลนี้ ด้านล่างเป็นร่างจากฟีเจอร์หลักของแอป ให้เทียบกับ Form 2 แล้วแก้ชื่อ/ลำดับให้ตรง
> รูปแบบ: `ฟีเจอร์ | เส้นทางเข้าถึง | ไฟล์หลัก | รหัสผู้รับผิดชอบ | สถานะ`

```
R1 ดูจักรยานว่างและสถานะสด | ล็อกอินนิสิต → หน้าแรก /borrow | lib/features/borrow/presentation/borrow_home_page.dart, bike_list_section.dart | ⬜รหัส | ⬜complete
R2 สแกน QR / พิมพ์เลขคันเพื่อยืม รับรหัสล็อก | /borrow → สแกน → ยืนยัน | lib/features/borrow/presentation/scan_page.dart, confirm_borrow_page.dart | ⬜รหัส | ⬜complete
R3 นับถอยหลังและแจ้งเตือนก่อนคืน (30/10 นาที, เกินเวลา) | การ์ดยืมค้างหน้า /borrow | lib/features/reminder/ (reminder_service.dart, loan_countdown_card.dart) | ⬜รหัส | ⬜partial (ยังไม่ทดสอบบนเครื่องจริง)
R4 ป้อมรปภ.: รับคืน ตรวจสภาพ ค้นประวัติ | ล็อกอิน guard01 → /guard | lib/features/guard/presentation/return_page.dart, history_page.dart, dashboard_page.dart | ⬜รหัส | ⬜complete
R5 ผู้ดูแล: แดชบอร์ด นำเข้านิสิต CSV จัดการจักรยาน/ล็อก/ซ่อม | ล็อกอิน admin01 → /admin | lib/features/admin/presentation/ (admin_dashboard_page.dart, import_students_page.dart, bikes_page.dart, locks_page.dart, repairs_page.dart) | ⬜รหัส | ⬜complete
```

- **ที่ยังไม่เสร็จ/ตัดออก:** ⬜ ตัวอย่างที่มีในเอกสาร: แจ้งเตือนเป็น local notification เท่านั้น (ไม่มี push/FCM) ถ้าคืนแล้วไม่เปิดแอปอาจยังเตือน · ยังไม่ได้ทดสอบแจ้งเตือนบนเครื่องจริง (docs/report-draft.md ข้อ 3, 6) · ถ้าไม่มีให้เขียน `none`

## ส่วนที่ 4: Change log จากฟีดแบ็กผู้ใช้ (A1)

> ⬜ ต้องมาจาก Form 2 จริง (รอบ, ผู้ใช้ขออะไร, แก้อะไร, รหัสคนแก้, ลิงก์หลักฐาน) ด้านล่างคือ commit ที่น่าจะเกี่ยวข้อง ใช้เป็นหลักฐานได้ถ้าตรงกับฟีดแบ็ก
> ลิงก์ commit รูปแบบ `https://github.com/wanluvcyber-hub/Bicycle-Borrowing-and-Returning/commit/<hash>`

```
⬜รอบ | ⬜ผู้ใช้ขอ: ต้องกรอกเบอร์โทรนิสิต | เพิ่มบังคับกรอกเบอร์ + เปลี่ยนชื่อป้อมรปภ. | ⬜รหัส | commit 26d4561
⬜รอบ | ⬜ผู้ใช้ขอ: แก้เบอร์โทรของตัวเองได้ | นิสิตแก้เบอร์ได้ในแอป + migration 003 | ⬜รหัส | commit 895de5f
⬜รอบ | ⬜ผู้ใช้ขอ: ปรับ UI ให้ใช้ง่ายขึ้น | ปรับ UX/UI ตามดีไซน์ Stitch, แดชบอร์ดผู้ดูแล | ⬜รหัส | commit a73899f, 062e454
```

## ส่วนที่ 5: เครื่องมือและการตัดสินใจทางเทคนิค (A3)

**Packages / services** (`⬜รหัส` = รหัสคนที่ใช้/รับผิดชอบ)
```
supabase_flutter ^2.18.2 | ฐานข้อมูล PostgreSQL, ล็อกอิน, Realtime | บังคับกฎ (ยืมก่อน 21:00, ครั้งละ 1 คัน) ที่ DB ด้วย RLS/ฟังก์ชัน และอัปเดตสถานะสด | ⬜รหัส
provider ^6.1.5+1 | state management | เรียบง่าย เหมาะขนาดโปรเจกต์ และทดสอบ state แยกจาก UI ได้ | ⬜รหัส
go_router ^18.0.2 | นำทางและ redirect ตามบทบาท | แยกหน้านิสิต/ป้อมรปภ./ผู้ดูแล และกันเข้าผิดสิทธิ์ | ⬜รหัส
mobile_scanner ^7.4.2 | สแกน QR บนจักรยาน | ยืมโดยไม่ต้องพิมพ์เลขคัน | ⬜รหัส
flutter_local_notifications ^22.3.1 + timezone ^0.11.1 + flutter_timezone ^5.1.1 | แจ้งเตือนก่อนครบกำหนดคืน | ทำงานในเครื่องโดยไม่ต้องมีเซิร์ฟเวอร์ push | ⬜รหัส
file_picker ^13.1.0 | เลือกไฟล์ CSV นำเข้ารายชื่อนิสิต | แอดมินนำเข้ารายชื่อหอในทีเดียว | ⬜รหัส
intl ^0.20.3 | จัดรูปแบบวันเวลา | แสดงเวลาคืน/นับถอยหลัง | ⬜รหัส
Google Fonts: Prompt, Noto Sans Thai (ฝังในแอป) | ฟอนต์ | ตามดีไซน์ รองรับภาษาไทย | ⬜รหัส
```

**Technical decisions (4 บรรทัด)**
```
State management: provider (ChangeNotifier แยกต่อฟีเจอร์ใน state/) | เพราะแต่ละหน้าต้องแสดงสถานะยืม/จักรยานร่วมกัน และต้องทดสอบ logic โดยไม่พึ่ง UI
Data storage: Supabase PostgreSQL + RLS, กฎธุรกิจอยู่ที่ฟังก์ชันฐานข้อมูล | เพราะกฎ (ครั้งละ 1 คัน, ก่อน 21:00) ต้องถูกบังคับแม้มีหลายเครื่องยืมพร้อมกัน; ปิด-เปิดแอปข้อมูลยังอยู่
Async processing: Future/async-await เรียก Supabase ผ่าน repository + Realtime stream อัปเดตสถานะจักรยานสด | เพื่อให้ฝั่งนิสิตและป้อมรปภ.เห็นสถานะตรงกันทันที
Error handling & in-progress: AppError จับรหัส error จาก DB แปลงเป็นข้อความไทย (เช่น already_borrowing, bike_not_available), มีสถานะ loading/error ในหน้า และกันกดยืมซ้ำตอนกำลังส่งคำขอ | เพราะเน็ตหลุด/กดรัวต้องไม่ยืมซ้ำ
```

## ส่วนที่ 6: แบ่งงาน (B1, B2)

> ⬜ ต้องกรอกรหัสนักศึกษา, % (รวม 100), และงานที่จะนำเสนอของทุกคน · ต้องมีใบรับรองสัดส่วนที่ทุกคนเซ็น
> ใน git มีผู้เขียน commit 3 บัญชี (dekchaiwan 14, NatchaSiriruang 4, rlitksrly 1) แต่ README แบ่งงาน 4 คน ใช้เป็นข้อมูลอ้างอิงเท่านั้น ไม่ใช่สัดส่วนจริง

| สมาชิก | ขอบเขตที่ README ระบุ | ไฟล์/หน้าจอ (ใช้ตอบข้อ scope) | รหัส | % |
|---|---|---|---|---|
| 1 | ฐานข้อมูล, ล็อกอินและตรวจสิทธิ์หอใน, หน้าผู้ดูแล, โค้ดกลาง | `supabase/migrations/`, `lib/core/`, `lib/features/auth/`, `lib/features/admin/` | ⬜ | ⬜ |
| 2 | แอปนิสิต: จักรยานว่าง, สแกน QR ยืม, รหัสล็อก, นับถอยหลัง | `lib/features/borrow/` (borrow_home_page, scan_page, confirm_borrow_page, active_loan_card, edit_phone_dialog) | ⬜ | ⬜ |
| 3 | ป้อมรปภ.: รับคืนและตรวจสภาพ, สรุปสถานะ, ค้นประวัติ | `lib/features/guard/` (dashboard_page, return_page, history_page, qr_scan_page) | ⬜ | ⬜ |
| 4 | แจ้งเตือนเวลาคืน, การทดสอบ, เอกสาร | `lib/features/reminder/`, `test/`, `docs/` | ⬜ | ⬜ |

- **Self-presented work:** ⬜ ของแต่ละคน (ลิงก์ถ้ามีของภายนอก) เอาจาก `docs/person-*.md`
- **Share confirmation:** ติ๊กได้เมื่อทุกคนตกลงจริง
- **Link ใบรับรองที่เซ็น:** ⬜
- **รหัสคนที่ไม่เห็นด้วย:** ⬜ (ไม่บังคับ)

## ส่วนที่ 7: ทดสอบและไฟล์แนบ

**Test results** (รูปแบบ: `รายการ | ขั้นตอน | คาดหวัง | ผลจริง | ผ่าน/ไม่ผ่าน | รหัสผู้ทดสอบ`)

ผลที่ตรวจแล้วจริงเมื่อวันนี้ (รันบนเครื่องนี้):
```
flutter test | รัน flutter test ที่โฟลเดอร์โปรเจกต์ | ผ่านทุกข้อ | All tests passed (116 เทสต์) | ผ่าน | ⬜รหัส
flutter analyze | รัน flutter analyze | ไม่มี issue | ⬜ยังไม่ได้รันซ้ำวันนี้ (docs/test-results.md บันทึกว่าไม่มี issue) | ⬜ | ⬜รหัส
flutter build apk --debug | build | สำเร็จ | ตามบันทึก docs/test-results.md รอบที่ 1 (ยังไม่ได้รันซ้ำวันนี้) | ผ่าน | ⬜รหัส
```
ทดสอบบนเครื่องจริง: `docs/test-results.md` ระบุว่า **15 ข้อยังไม่ได้ทดสอบบนเครื่องจริง** (⬜ ทั้งหมด) ห้ามเขียนว่าผ่านถ้ายังไม่ได้ลอง ให้ทดสอบจริงบน Supabase + มือถือ แล้วเติมที่นี่ ตัวอย่างข้อ: ล็อกอิน test01 เห็นจักรยานว่าง 10 คัน · ยืม B01 เห็นรหัสล็อก · ยืมคันที่สองต้องถูกปฏิเสธ · guard รับคืนปกติ/ชำรุด · แจ้งเตือน 20:30/20:50 เด้ง

- **Install/trial link:** ⬜ (เช่น APK จาก `flutter build apk` อัปขึ้น Drive/GitHub Releases) ต้องสร้างจาก commit เดียวกับส่วนที่ 2
- **Pre-submission checks ก่อนติ๊ก:**
  - ⬜ clone ใหม่แล้ว checkout commit นี้รันได้
  - ✅ ไม่มี key จริงใน repo: `env.json` ถูก ignore, ใน git มีแค่ `env.example.json` และ `lib/core/config/env.dart` (ยังไม่ได้ไล่ค้นประวัติ git ทั้งหมด ⬜ ควรเช็ก)
  - ⬜ มี Form 2 อย่างน้อย 1 ชุดต่อผู้ใช้ (นิสิต / ป้อมรปภ. / ผู้ดูแล)
  - ⬜ แอปที่ให้ทดลองตรงกับที่เดโม

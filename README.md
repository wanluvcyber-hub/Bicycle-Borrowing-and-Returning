# ระบบยืม-คืนจักรยานหอใน (bike_loan)

แอปมือถือ (Flutter + Supabase) ให้นิสิตหอในยืมจักรยานเองด้วยการสแกน QR และคืนที่ป้อมยามซึ่งมีโปรแกรมไว้ตรวจสอบ
รายวิชา Mobile Application · มหาวิทยาลัยนเรศวร · ทีม 4 คน

**อ่านตามลำดับนี้:** README นี้ → ไฟล์ของตัวเองใน `docs/person-X-...md` → `docs/database.md` (ทุกคนต้องอ่าน)
แผนระบบเต็ม (Flow, DFD, Data Dictionary) เปิดดูที่ `docs/bike-system-plan.html`

## ใครทำอะไร

| คน | งาน | Process | โฟลเดอร์ที่เป็นเจ้าของ | เอกสารงาน |
|---|---|---|---|---|
| คนที่ 1 | ตั้งโปรเจกต์/ฐานข้อมูล, ล็อกอิน+ยืนยันหอใน, หน้าผู้ดูแลระบบ, โค้ดกลาง `core/` | 1.0, 7.0 | `lib/core/` `lib/features/auth/` `lib/features/admin/` `supabase/` | [person-1-auth-admin.md](docs/person-1-auth-admin.md) |
| คนที่ 2 | แสดงจักรยานว่าง, สแกน QR ยืม, รหัสล็อก+นับถอยหลัง (แอปนิสิต) | 2.0, 3.0 | `lib/features/borrow/` | [person-2-borrow.md](docs/person-2-borrow.md) |
| คนที่ 3 | โปรแกรมป้อมยาม: รับคืน+ตรวจสภาพ, สรุป/สถานะทุกคัน, ค้นประวัติ | 5.0, 6.0 | `lib/features/guard/` | [person-3-guard.md](docs/person-3-guard.md) |
| คนที่ 4 | แจ้งเตือนก่อนถึงเวลาคืน, สถานะเกินเวลา, ทดสอบ, ดูแลเอกสาร | 4.0 + ทดสอบ + เอกสาร | `lib/features/reminder/` `test/` `docs/` | [person-4-reminder-test-docs.md](docs/person-4-reminder-test-docs.md) |
| ทุกคน | ฐานข้อมูล: ตาราง ฟังก์ชัน สิทธิ์ รหัส error | — | `supabase/` | [database.md](docs/database.md) |

เส้นหลักที่ต้องใช้งานได้ก่อนอย่างอื่น: **สแกนยืม → ได้รหัสล็อก → ป้อมยามรับคืน**

## เริ่มรันโปรเจกต์ (ทุกคน)

ต้องการ Flutter **3.47.x** (Dart 3.13.x) ตรวจด้วย `flutter --version` ให้ตรงกันทั้งทีม

```bash
git clone <ลิงก์ repo>
cd bike_loan
flutter pub get
cp env.example.json env.json      # แล้วใส่ URL กับ anon key ที่คนที่ 1 ส่งให้ทางแชตส่วนตัว
flutter run --dart-define-from-file=env.json
```
- VS Code: กด F5 ได้เลย (มี `.vscode/launch.json` โหลด `env.json` ให้)
- Android Studio: Run → Edit Configurations → Additional run args ใส่ `--dart-define-from-file=env.json`
- `env.json` ถูก `.gitignore` ไว้แล้ว **ห้าม commit**
- แอปเชื่อม Supabase และล็อกอินได้แล้ว (ฝั่งนิสิต/ป้อมยามยังเป็นหน้า placeholder ใน `lib/core/router/feature_routes.dart` ให้คนที่ 2/3 แทนที่ด้วย route ของตัวเอง)

## โครงโฟลเดอร์

```
bike_loan/
├─ lib/
│  ├─ main.dart                  จุดเริ่มต้น (คนที่ 1 เติม)
│  ├─ core/                      โค้ดที่ทุกคนใช้ร่วมกัน (คนที่ 1 เขียนก่อน แล้วแก้ผ่าน PR เล็กๆ เท่านั้น)
│  │  ├─ config/  supabase/  models/  errors/  router/  theme/  widgets/  utils/
│  └─ features/                  แยกตามฟีเจอร์ 1 โฟลเดอร์ = 1 เจ้าของ
│     ├─ auth/       คนที่ 1   ┐
│     ├─ admin/      คนที่ 1   │ แต่ละฟีเจอร์แบ่งเป็น
│     ├─ borrow/     คนที่ 2   │   data/          เรียก Supabase
│     ├─ guard/      คนที่ 3   │   state/         Provider (ChangeNotifier)
│     └─ reminder/   คนที่ 4   ┘   presentation/  หน้าจอและ widget
├─ test/                         เทสต์ (คนที่ 4 ดูแล แต่ละคนเขียนเทสต์ของตัวเองใน test/features/<ฟีเจอร์>/)
├─ supabase/
│  ├─ migrations/001_init.sql    ตาราง + กฎสิทธิ์ + ฟังก์ชัน (แก้ผ่านไฟล์ใหม่เท่านั้น)
│  └─ seed.sql                   ข้อมูลทดสอบ
├─ docs/                         เอกสารทีม + แผนระบบ
├─ android/ ios/                 ตั้งค่า native แล้ว (ดูด้านล่าง)
├─ env.example.json              แบบของ env.json
└─ pubspec.yaml                  รายการ package (เติมไว้ให้แล้ว)
```
ทุกโฟลเดอร์ที่ยังว่างมีไฟล์ `.gitkeep` เพื่อให้ git เก็บโครงไว้ ลบทิ้งได้เมื่อมีไฟล์จริงในนั้น

## กติกาทีม (ข้อนี้คือสิ่งที่กันโปรเจกต์ล่ม)

1. **ห้าม push ตรงเข้า `main`** ทุกงานเริ่มจาก branch ตั้งชื่อ `feat/<คนที่>-<งาน>` เช่น `feat/p2-scan-qr` แล้วเปิด Pull Request ให้เพื่อนอย่างน้อย 1 คนดูก่อน merge
   (ถ้า GitHub ตั้ง branch protection ใน repo private แผนฟรีไม่ได้ ให้ถือเป็นกติกาที่ตกลงกันเอง)
2. **แก้เฉพาะโฟลเดอร์ของตัวเอง** ไฟล์ที่ทุกคนพึ่ง คือ `pubspec.yaml`, `lib/main.dart`, `lib/core/**`, `supabase/**`, `android/**`, `ios/**` ให้แก้ผ่าน PR เล็กๆ (เปลี่ยนเรื่องเดียว) และ **แจ้งในกลุ่มก่อน merge** เพราะเป็นจุดที่ conflict บ่อยสุด
3. **ก่อนเริ่มงานทุกวัน:** `git checkout main && git pull` แล้วค่อยแตก branch / merge `main` เข้า branch ตัวเองอย่างน้อยวันละครั้ง ยิ่งค้างนาน conflict ยิ่งใหญ่
4. **PR เล็ก เปลี่ยนเรื่องเดียว** ดีกว่า PR ใหญ่ครั้งเดียวตอนใกล้ส่ง ตั้งชื่อ commit ให้อ่านรู้เรื่อง เช่น `borrow: เพิ่มหน้าสแกน QR`
5. **ชื่อฟิลด์ ค่าสถานะ รหัส error ใช้ตาม `docs/database.md` เท่านั้น** จะเปลี่ยนต้องแจ้งทุกคนก่อน
6. **ห้ามแก้ฐานข้อมูลใน Supabase Dashboard** แก้ผ่านไฟล์ใน `supabase/migrations/` (วิธีอยู่ใน database.md หัวข้อ 9)
7. **ห้าม commit ความลับ:** `env.json`, `service_role` key, รหัสผ่าน, รหัสล็อกจริง
8. ก่อนเปิด PR ต้องรัน `flutter analyze` ให้ **ไม่มี issue** และ `flutter test` ผ่าน
   (ตอนนี้ยังไม่มีไฟล์เทสต์เลย `flutter test` จึงขึ้น error "does not appear to contain any test files" เป็นเรื่องปกติ จนกว่าคนที่ 4 หรือใครสักคนจะเพิ่มไฟล์ `*_test.dart` ไฟล์แรกใน `test/`)
9. ติดปัญหากับงานของคนอื่น (เช่น รอ `core/` ของคนที่ 1) ให้ถามในกลุ่มทันที อย่ารอ และอย่าแก้โค้ดของเขาเอง

### PR checklist (ก๊อปไปใส่ในคำอธิบาย PR)
- [ ] แก้เฉพาะโฟลเดอร์ของตัวเอง (ถ้าแตะไฟล์ร่วม บอกในกลุ่มแล้ว)
- [ ] `flutter analyze` ไม่มี issue, `flutter test` ผ่าน
- [ ] ลองรันบนเครื่อง/emulator จริงแล้ว (ไม่ใช่แค่คอมไพล์ผ่าน)
- [ ] ไม่มี key/รหัสผ่านใน diff
- [ ] ถ้าแตะฐานข้อมูล: มีไฟล์ migration ใหม่ + แก้ `docs/database.md` ใน PR เดียวกัน

## เริ่ม repo ครั้งแรก (คนที่ 1)

```bash
cd bike_loan
git init -b main
git add .
git commit -m "Initial project structure"
git remote add origin <ลิงก์ repo ที่สร้างบน GitHub>
git push -u origin main
```
จากนั้นเชิญเพื่อนที่ GitHub → Settings → Collaborators

## สิ่งที่ตั้งค่าไว้แล้ว (อย่าลบ)

- **Package ที่เติมไว้ใน `pubspec.yaml`:** `supabase_flutter` (ฐานข้อมูล+ล็อกอิน), `provider` (state ตามที่เรียนในวิชา), `go_router` (นำทาง — ถ้าทีมอยากใช้ `Navigator` ธรรมดาตาม lab ให้คนที่ 1 ลบออกใน PR แรก), `mobile_scanner` (สแกน QR), `flutter_local_notifications` + `timezone` + `flutter_timezone` (แจ้งเตือน), `intl` (วันที่/เวลา)
- **Android** (`android/app/build.gradle.kts`, `AndroidManifest.xml`): เปิด core library desugaring (จำเป็นสำหรับ `flutter_local_notifications` ไม่งั้น build ล่ม) · `minSdk = 24` (จำเป็นสำหรับ `mobile_scanner`) · สิทธิ์ INTERNET, CAMERA, POST_NOTIFICATIONS
- **iOS** (`Info.plist`): คำอธิบายการใช้กล้อง
- ถ้าเพิ่ม package ที่ต้องตั้งค่า native เพิ่ม ให้เปิด PR แยกแล้วแจ้งทีม และทดสอบ `flutter build apk --debug` ก่อน merge

## ลิงก์

- แผนระบบ: `docs/bike-system-plan.html` (เปิดด้วยเบราว์เซอร์)
- ฐานข้อมูล: `docs/database.md`

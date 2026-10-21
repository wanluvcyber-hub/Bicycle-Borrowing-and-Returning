-- =====================================================================
-- 006 · เลิกเก็บเบอร์โทรนิสิต: ลบฟังก์ชัน update_my_phone และคอลัมน์ students.phone
-- รันซ้ำได้ (if exists) · ไม่แตะตาราง/แถวอื่น
-- ข้อมูลเบอร์ที่มีอยู่จะหายถาวร จึงรันเมื่อยืนยันแล้วว่าไม่ใช้เบอร์อีก
-- =====================================================================

drop function if exists public.update_my_phone(text);

alter table public.students
  drop constraint if exists students_phone_not_blank;

alter table public.students
  drop column if exists phone;

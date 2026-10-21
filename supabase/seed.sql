-- =====================================================================
-- ข้อมูลทดสอบ · supabase/seed.sql
-- รันหลัง supabase/migrations/001_init.sql · รันซ้ำได้ (on conflict do nothing)
-- ข้อมูลทั้งหมดเป็นของปลอม ห้ามเอาไปใช้กับระบบจริง
-- =====================================================================

-- จักรยาน 10 คัน: B01 ... B10 (qr_code = เลขคัน) รหัสล็อกทดสอบ 0111, 0222, ...
insert into public.bikes (bike_no, qr_code, station)
select 'B' || lpad(i::text, 2, '0'), 'B' || lpad(i::text, 2, '0'), 'ป้อมB2 หอพักนิสิต'
from generate_series(1, 10) as i
on conflict (bike_no) do nothing;

insert into public.bike_locks (bike_no, lock_code)
select 'B' || lpad(i::text, 2, '0'), lpad((i * 111)::text, 4, '0')
from generate_series(1, 10) as i
on conflict (bike_no) do nothing;

-- นิสิตทดสอบ 20 คน: รหัส 66000001..66000020 · อีเมล test01@example.com .. test20@example.com
insert into public.students (student_id, full_name, building, room, email, semester, verified)
select
  '6600' || lpad(i::text, 4, '0'),
  'นิสิตทดสอบ ' || lpad(i::text, 2, '0'),
  'อาคาร ' || ((i - 1) % 5 + 1),
  (100 + i)::text,
  'test' || lpad(i::text, 2, '0') || '@example.com',
  '1/2569',
  false
from generate_series(1, 20) as i
on conflict (student_id) do nothing;

-- เจ้าหน้าที่ทดสอบ: จะมีผลก็ต่อเมื่อสร้างผู้ใช้ใน Authentication > Users ด้วยอีเมลเหล่านี้แล้ว
-- (สร้างผู้ใช้เสร็จ แล้วรันไฟล์นี้อีกรอบ)
--   guard01@example.com  → ป้อมรปภ.
--   admin01@example.com  → ผู้ดูแลระบบ
insert into public.staff (user_id, full_name, role)
select id, 'ป้อมรปภ.ทดสอบ', 'guard' from auth.users where email = 'guard01@example.com'
on conflict (user_id) do nothing;

insert into public.staff (user_id, full_name, role)
select id, 'ผู้ดูแลระบบทดสอบ', 'admin' from auth.users where email = 'admin01@example.com'
on conflict (user_id) do nothing;

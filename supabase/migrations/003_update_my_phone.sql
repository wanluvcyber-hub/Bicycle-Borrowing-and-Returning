-- =====================================================================
-- 003 · เบอร์มือถือของนิสิต: มีคอลัมน์แน่นอน + นิสิตแก้เบอร์ของตัวเองได้
-- รันซ้ำได้ ไม่ลบตาราง/แถวใด และไม่แตะแถวที่มีเบอร์อยู่แล้ว
-- รวมผลของ 002_require_student_phone.sql ไว้ด้วย (รันไฟล์นี้ไฟล์เดียวพอ)
-- =====================================================================

-- 1. ฐานข้อมูลที่สร้างมาก่อนมีคอลัมน์นี้ ให้เพิ่มเข้าไป
alter table public.students
  add column if not exists phone text;

-- 2. แถวเดิมที่เบอร์ว่าง เติมเบอร์ทดสอบ 0800000001, 0800000002, ... (แบบเดียวกับ seed.sql)
--    นิสิตแก้เป็นเบอร์จริงเองได้ในแอป
with blank as (
  select student_id, row_number() over (order by student_id) as n
    from public.students
   where phone is null or length(btrim(phone)) = 0
)
update public.students s
   set phone = '08' || lpad(blank.n::text, 8, '0')
  from blank
 where s.student_id = blank.student_id;

-- 3. บังคับห้ามว่าง
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.students'::regclass
      and conname = 'students_phone_not_blank'
  ) then
    alter table public.students
      add constraint students_phone_not_blank
      check (length(btrim(phone)) > 0);
  end if;
end;
$$;

alter table public.students
  alter column phone set not null;

-- 4. นิสิตแก้เบอร์มือถือของตัวเอง (แก้ได้คอลัมน์เดียว แถวเดียว) คืนเบอร์ที่บันทึกจริง
--    รับขีด/ช่องว่างได้ แต่ต้องเหลือ 10 หลักขึ้นต้นด้วย 0
create or replace function public.update_my_phone(p_phone text)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  v_phone text := regexp_replace(coalesce(p_phone, ''), '[[:space:]-]', '', 'g');
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if v_phone !~ '^0[0-9]{9}$' then
    raise exception 'invalid_phone';
  end if;

  update public.students
     set phone = v_phone
   where auth_user_id = auth.uid() and verified;
  if not found then
    raise exception 'not_verified';
  end if;

  return v_phone;
end;
$$;

revoke all on function public.update_my_phone(text) from public, anon;
grant execute on function public.update_my_phone(text) to authenticated;

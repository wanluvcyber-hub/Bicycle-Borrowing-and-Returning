-- =====================================================================
-- ระบบยืม-คืนจักรยานหอใน · 001_init.sql
--
-- วิธีใช้: Supabase Dashboard > SQL Editor > New query > วางทั้งไฟล์ > Run
-- รันซ้ำได้ ไม่ทำให้ข้อมูลหาย (ใช้ if not exists / create or replace)
-- รันไฟล์นี้ก่อน แล้วค่อยรัน supabase/seed.sql
--
-- คำอธิบายละเอียดของทุกตารางและทุกฟังก์ชันอยู่ที่ docs/database.md
-- ใครจะแก้ schema ให้แก้ผ่านไฟล์ในโฟลเดอร์นี้ (ผ่าน PR) ห้ามไปกดแก้ใน Dashboard
-- =====================================================================


-- =====================================================================
-- 1. ตาราง
-- =====================================================================

-- D1 · ข้อมูลนิสิตหอใน
create table if not exists public.students (
  student_id   text        primary key,                 -- รหัสนิสิต เช่น 66000001
  full_name    text        not null,
  building     text,                                    -- อาคาร
  room         text,                                    -- ห้อง
  phone        text,
  email        text,                                    -- อีเมลมหาลัย ใช้จับคู่ตอนล็อกอินครั้งแรก
  semester     text        not null,                    -- ภาคเรียนที่มีสิทธิ์ เช่น '1/2569'
  verified     boolean     not null default false,      -- ยืนยันหอในแล้วหรือยัง
  late_count   integer     not null default 0 check (late_count >= 0),
  auth_user_id uuid        unique references auth.users (id) on delete set null,
  created_at   timestamptz not null default now()
);
-- อีเมลห้ามซ้ำ (ไม่สนตัวพิมพ์เล็ก-ใหญ่) เพราะใช้จับคู่บัญชีล็อกอินกับนิสิต
create unique index if not exists students_email_key
  on public.students (lower(email));

-- เจ้าหน้าที่ (ป้อมยาม / ผู้ดูแลระบบ) · ไม่อยู่ใน Data Dictionary เดิม แต่จำเป็นสำหรับ received_by และสิทธิ์
create table if not exists public.staff (
  user_id   uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  role      text not null check (role in ('guard', 'admin'))
);

-- D2 · ข้อมูลจักรยาน (ส่วนที่เปิดเผยได้)
create table if not exists public.bikes (
  bike_no text primary key,                             -- หมายเลขจักรยาน เช่น B01
  qr_code text not null unique,                         -- ค่าใน QR (เก็บแค่เลขคัน)
  station text,                                         -- จุดจอด
  status  text not null default 'available'
          check (status in ('available', 'borrowed', 'broken')),   -- ว่าง / ถูกยืม / ชำรุด
  note    text                                          -- หมายเหตุความเสียหาย
);

-- D2 · รหัสล็อกล้อ แยกเป็นอีกตาราง เพื่อไม่ให้รั่วผ่าน select / realtime ของตาราง bikes
-- นิสิตจะได้รหัสผ่านฟังก์ชัน borrow_bike() และ get_my_active_loan() เท่านั้น
create table if not exists public.bike_locks (
  bike_no   text primary key references public.bikes (bike_no) on delete cascade,
  lock_code text not null
);

-- D3 · ข้อมูลการยืม-คืน
create table if not exists public.loans (
  loan_id     bigint      generated always as identity primary key,
  student_id  text        not null references public.students (student_id),
  bike_no     text        not null references public.bikes (bike_no),
  borrowed_at timestamptz not null default now(),
  due_at      timestamptz not null,                     -- กำหนดคืน (21.00 น.)
  returned_at timestamptz,
  received_by uuid        references public.staff (user_id) on delete set null,
  condition   text        check (condition in ('normal', 'damaged')),   -- ปกติ / ชำรุด
  status      text        not null default 'borrowing'
              check (status in ('borrowing', 'overdue', 'returned')),   -- กำลังยืม / เกินเวลา / คืนแล้ว
  is_late     boolean     not null default false,
  -- คืนแล้ว <=> มี returned_at
  check ((returned_at is null) = (status <> 'returned')),
  check (returned_at is null or returned_at >= borrowed_at)
);

-- ห้ามมีรายการค้างซ้อน: นิสิต 1 คนยืมได้ครั้งละ 1 คัน และจักรยาน 1 คันถูกยืมได้ทีละ 1 คน
-- (กันกรณีกดยืมซ้ำสองครั้งพร้อมกัน ให้ฐานข้อมูลเป็นคนตัดสิน)
create unique index if not exists loans_one_active_per_student
  on public.loans (student_id) where returned_at is null;
create unique index if not exists loans_one_active_per_bike
  on public.loans (bike_no) where returned_at is null;
create index if not exists loans_student_idx    on public.loans (student_id, borrowed_at desc);
create index if not exists loans_bike_idx       on public.loans (bike_no, borrowed_at desc);


-- =====================================================================
-- 2. ฟังก์ชันช่วยเช็กสิทธิ์
--    security definer = รันด้วยสิทธิ์เจ้าของ ข้าม RLS ได้ จึงไม่วนลูปตอนใช้ใน policy
-- =====================================================================

create or replace function public.is_staff()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.staff where user_id = auth.uid());
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.staff where user_id = auth.uid() and role = 'admin');
$$;


-- =====================================================================
-- 3. Row Level Security
--    หลักการ: นิสิตเห็นแค่ข้อมูลตัวเอง · เจ้าหน้าที่เห็นทั้งหมด · ผู้ดูแลแก้ข้อมูลพื้นฐานได้
--    ตาราง loans ห้ามเขียนตรง ต้องผ่านฟังก์ชัน borrow_bike / return_bike เท่านั้น
-- =====================================================================

alter table public.students   enable row level security;
alter table public.staff      enable row level security;
alter table public.bikes      enable row level security;
alter table public.bike_locks enable row level security;
alter table public.loans      enable row level security;

-- students
drop policy if exists students_select_own   on public.students;
drop policy if exists students_select_staff on public.students;
drop policy if exists students_admin_all    on public.students;
create policy students_select_own   on public.students for select to authenticated
  using (auth_user_id = auth.uid());
create policy students_select_staff on public.students for select to authenticated
  using (public.is_staff());
create policy students_admin_all    on public.students for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- staff (อ่านได้แค่แถวตัวเอง ผู้ดูแลอ่านได้ทั้งหมด · การเพิ่มเจ้าหน้าที่ทำผ่าน SQL Editor)
drop policy if exists staff_select on public.staff;
create policy staff_select on public.staff for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- bikes (ทุกคนที่ล็อกอินแล้วดูสถานะได้ · ผู้ดูแลเพิ่ม/แก้/ลบ)
drop policy if exists bikes_select_all  on public.bikes;
drop policy if exists bikes_admin_write on public.bikes;
create policy bikes_select_all  on public.bikes for select to authenticated using (true);
create policy bikes_admin_write on public.bikes for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- bike_locks (เจ้าหน้าที่อ่านได้ · ผู้ดูแลแก้ได้ · นิสิตอ่านตรงไม่ได้เลย)
drop policy if exists bike_locks_staff_select on public.bike_locks;
drop policy if exists bike_locks_admin_write  on public.bike_locks;
create policy bike_locks_staff_select on public.bike_locks for select to authenticated
  using (public.is_staff());
create policy bike_locks_admin_write  on public.bike_locks for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- loans (นิสิตเห็นของตัวเอง · เจ้าหน้าที่เห็นทั้งหมด · ไม่มี policy เขียน)
drop policy if exists loans_select_own   on public.loans;
drop policy if exists loans_select_staff on public.loans;
create policy loans_select_own on public.loans for select to authenticated
  using (exists (
    select 1 from public.students s
    where s.student_id = loans.student_id and s.auth_user_id = auth.uid()
  ));
create policy loans_select_staff on public.loans for select to authenticated
  using (public.is_staff());

-- ปิดสิทธิ์ระดับตารางซ้ำอีกชั้น (defense in depth)
revoke all on public.students, public.staff, public.bikes, public.bike_locks, public.loans from anon;
revoke insert, update, delete on public.loans from authenticated;


-- =====================================================================
-- 4. ฟังก์ชันธุรกิจ (เรียกจากแอปด้วย supabase.rpc('ชื่อฟังก์ชัน', params: {...}))
--    ทุกตัวโยน exception เป็นรหัสข้อความสั้นๆ เช่น 'already_borrowing'
--    ดูตารางรหัสทั้งหมดใน docs/database.md
-- =====================================================================

-- 1.0 · ผูกบัญชีที่ล็อกอินเข้ากับรายชื่อหอใน (จับคู่ด้วยอีเมล) แล้วตั้ง verified = true
create or replace function public.claim_student_profile()
returns public.students
language plpgsql security definer set search_path = ''
as $$
declare
  v_student public.students;
  v_email   text := lower(auth.jwt() ->> 'email');
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_student from public.students where auth_user_id = auth.uid();
  if found then
    return v_student;                       -- เคยผูกแล้ว คืนแถวเดิม
  end if;

  update public.students
     set auth_user_id = auth.uid(), verified = true
   where lower(email) = v_email and auth_user_id is null
   returning * into v_student;
  if not found then
    raise exception 'not_in_dorm_list';     -- อีเมลนี้ไม่อยู่ในรายชื่อหอใน
  end if;

  return v_student;
end;
$$;

-- 3.0 · ยืมจักรยาน (นิสิตเรียก) คืน jsonb: loan_id, bike_no, lock_code, borrowed_at, due_at
create or replace function public.borrow_bike(p_qr_code text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_student public.students;
  v_bike    public.bikes;
  v_lock    text;
  v_due     timestamptz;
  v_loan_id bigint;
begin
  -- ล็อกแถวนิสิตไว้ กันกดยืมซ้ำพร้อมกัน
  select * into v_student from public.students where auth_user_id = auth.uid() for update;
  if not found or not v_student.verified then
    raise exception 'not_verified';
  end if;

  if exists (select 1 from public.loans l
              where l.student_id = v_student.student_id and l.returned_at is null) then
    raise exception 'already_borrowing';
  end if;

  select * into v_bike from public.bikes b where b.qr_code = p_qr_code for update;
  if not found then
    raise exception 'bike_not_found';
  end if;
  if v_bike.status <> 'available' then
    raise exception 'bike_not_available';
  end if;

  select bl.lock_code into v_lock from public.bike_locks bl where bl.bike_no = v_bike.bike_no;
  if v_lock is null then
    raise exception 'no_lock_code';
  end if;

  -- กำหนดคืน = 21.00 น. (เวลาไทย) ของวันนี้ ถ้าเลยเวลานี้แล้วจะยืมไม่ได้
  v_due := ((now() at time zone 'Asia/Bangkok')::date + time '21:00') at time zone 'Asia/Bangkok';
  if v_due <= now() then
    raise exception 'after_hours';
  end if;

  insert into public.loans (student_id, bike_no, borrowed_at, due_at, status)
  values (v_student.student_id, v_bike.bike_no, now(), v_due, 'borrowing')
  returning loan_id into v_loan_id;

  update public.bikes set status = 'borrowed' where bike_no = v_bike.bike_no;

  return jsonb_build_object(
    'loan_id',     v_loan_id,
    'bike_no',     v_bike.bike_no,
    'lock_code',   v_lock,
    'borrowed_at', now(),
    'due_at',      v_due
  );
end;
$$;

-- 3.0/4.0 · ดูรายการที่ยืมค้างของตัวเอง (พร้อมรหัสล็อก) คืน null ถ้าไม่มี
--          status จะเป็น 'overdue' ทันทีที่เลย due_at แม้ยังไม่ได้รัน mark_overdue_loans()
create or replace function public.get_my_active_loan()
returns jsonb
language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'loan_id',     l.loan_id,
    'bike_no',     l.bike_no,
    'lock_code',   bl.lock_code,
    'borrowed_at', l.borrowed_at,
    'due_at',      l.due_at,
    'status',      case when l.due_at < now() then 'overdue' else l.status end
  )
  from public.loans l
  join public.students s on s.student_id = l.student_id
  left join public.bike_locks bl on bl.bike_no = l.bike_no
  where s.auth_user_id = auth.uid() and l.returned_at is null
  limit 1;
$$;

-- 5.0 · รับคืน + ตรวจสภาพ (เจ้าหน้าที่เรียก)
--       p_condition: 'normal' | 'damaged' · ถ้า damaged ต้องใส่ p_note
create or replace function public.return_bike(
  p_bike_no   text,
  p_condition text,
  p_note      text default null
)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_loan public.loans;
  v_late boolean;
begin
  if not public.is_staff() then
    raise exception 'staff_only';
  end if;
  if p_condition not in ('normal', 'damaged') then
    raise exception 'invalid_condition';
  end if;
  if p_condition = 'damaged' and coalesce(btrim(p_note), '') = '' then
    raise exception 'note_required';
  end if;

  select * into v_loan from public.loans
   where bike_no = p_bike_no and returned_at is null
   for update;
  if not found then
    raise exception 'no_active_loan';
  end if;

  v_late := now() > v_loan.due_at;

  update public.loans
     set returned_at = now(),
         received_by = auth.uid(),
         condition   = p_condition,
         status      = 'returned',
         is_late     = v_late
   where loan_id = v_loan.loan_id;

  update public.bikes
     set status = case when p_condition = 'damaged' then 'broken' else 'available' end,
         note   = case when p_condition = 'damaged' then btrim(p_note) else note end
   where bike_no = p_bike_no;

  if v_late then
    update public.students set late_count = late_count + 1
     where student_id = v_loan.student_id;
  end if;

  return jsonb_build_object(
    'loan_id',     v_loan.loan_id,
    'student_id',  v_loan.student_id,
    'bike_no',     p_bike_no,
    'returned_at', now(),
    'is_late',     v_late,
    'condition',   p_condition
  );
end;
$$;

-- 4.0 · ตั้งสถานะ 'overdue' ให้รายการที่เลย due_at คืนจำนวนที่อัปเดต (เรียกซ้ำได้ ไม่เสียหาย)
create or replace function public.mark_overdue_loans()
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_count integer;
begin
  update public.loans
     set status = 'overdue'
   where returned_at is null and status = 'borrowing' and due_at < now();
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- ให้เฉพาะผู้ที่ล็อกอินแล้วเรียกฟังก์ชันได้
revoke all on function
  public.is_staff(), public.is_admin(), public.claim_student_profile(),
  public.borrow_bike(text), public.get_my_active_loan(),
  public.return_bike(text, text, text), public.mark_overdue_loans()
from public, anon;
grant execute on function
  public.is_staff(), public.is_admin(), public.claim_student_profile(),
  public.borrow_bike(text), public.get_my_active_loan(),
  public.return_bike(text, text, text), public.mark_overdue_loans()
to authenticated;


-- =====================================================================
-- 5. Realtime (2.0 · จำนวนจักรยานว่างและสถานะอัปเดตทันที)
--    ไม่ใส่ bike_locks เพราะมีรหัสล็อก
-- =====================================================================
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.bikes;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.loans;
    exception when duplicate_object then null;
    end;
  end if;
end
$$;


-- =====================================================================
-- 6. (ไม่บังคับ) ตั้งให้ฐานข้อมูลเปลี่ยนสถานะ overdue เองทุก 5 นาที
--    ต้องเปิด extension pg_cron ก่อน (Dashboard > Database > Extensions)
--    ถ้าไม่เปิด แอปยังทำงานได้ เพราะ get_my_active_loan() คำนวณ overdue จาก due_at อยู่แล้ว
-- =====================================================================
-- select cron.schedule('mark-overdue', '*/5 * * * *', $$select public.mark_overdue_loans()$$);

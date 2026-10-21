-- =====================================================================
-- 004 · ยืมได้ทุกเวลา (ปลดข้อจำกัด "ยืมได้ก่อน 21.00 น.")
-- แทนที่ฟังก์ชัน borrow_bike() เท่านั้น ไม่แตะตาราง/ข้อมูลใด รันซ้ำได้
-- กำหนดคืน = 21.00 น. (เวลาไทย) ของวันนี้ ถ้าเลยเวลานี้แล้วให้เป็น 21.00 น. ของวันถัดไป
-- =====================================================================
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

  -- กำหนดคืน = 21.00 น. (เวลาไทย) ของวันนี้ · เลยเวลานั้นแล้วเลื่อนเป็นพรุ่งนี้ ไม่ปฏิเสธการยืม
  v_due := ((now() at time zone 'Asia/Bangkok')::date + time '21:00') at time zone 'Asia/Bangkok';
  if v_due <= now() then
    v_due := v_due + interval '1 day';
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

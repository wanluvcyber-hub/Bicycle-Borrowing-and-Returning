-- Require a non-blank mobile number for every student profile.
do $$
begin
  if exists (
    select 1
    from public.students
    where phone is null or length(btrim(phone)) = 0
  ) then
    raise exception 'Cannot require students.phone: fill in mobile numbers for all existing students first';
  end if;

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

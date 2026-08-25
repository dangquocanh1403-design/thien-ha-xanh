-- Chạy toàn bộ file này MỘT LẦN trong Supabase SQL Editor.

create table if not exists public.duty_schedules (
  id uuid primary key default gen_random_uuid(),
  duty_type text not null check (duty_type in ('hospital','donation_site')),
  location text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  capacity integer not null check (capacity between 1 and 200),
  note text not null default '',
  created_by uuid not null references public.manager_profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create table if not exists public.duty_registrations (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null references public.duty_schedules(id) on delete cascade,
  user_id uuid not null references public.manager_profiles(user_id) on delete cascade,
  display_name text not null,
  role text not null check (role in ('leader','deputy','member')),
  created_at timestamptz not null default now(),
  unique (schedule_id, user_id)
);

alter table public.duty_schedules enable row level security;
alter table public.duty_registrations enable row level security;
grant select, insert, update, delete on public.duty_schedules to authenticated;
grant select on public.duty_registrations to authenticated;

create or replace function private.is_duty_manager()
returns boolean language sql stable security definer set search_path='' as $$
  select exists(
    select 1 from public.manager_profiles
    where user_id=(select auth.uid()) and status='approved' and role in ('leader','deputy')
  );
$$;

drop policy if exists "Approved accounts read duty schedules" on public.duty_schedules;
create policy "Approved accounts read duty schedules" on public.duty_schedules for select to authenticated
using ((select private.is_approved_account()));
drop policy if exists "Leaders create duty schedules" on public.duty_schedules;
create policy "Leaders create duty schedules" on public.duty_schedules for insert to authenticated
with check ((select private.is_duty_manager()) and created_by=(select auth.uid()));
drop policy if exists "Leaders update duty schedules" on public.duty_schedules;
create policy "Leaders update duty schedules" on public.duty_schedules for update to authenticated
using ((select private.is_duty_manager())) with check ((select private.is_duty_manager()));
drop policy if exists "Leaders delete duty schedules" on public.duty_schedules;
create policy "Leaders delete duty schedules" on public.duty_schedules for delete to authenticated
using ((select private.is_duty_manager()));
drop policy if exists "Approved accounts read registrations" on public.duty_registrations;
create policy "Approved accounts read registrations" on public.duty_registrations for select to authenticated
using ((select private.is_approved_account()));

create or replace function public.register_for_duty(p_schedule_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare p public.manager_profiles; maximum integer; registered integer;
begin
  select * into p from public.manager_profiles where user_id=(select auth.uid()) and status='approved' and role in ('leader','deputy','member');
  if p.user_id is null then raise exception 'Tài khoản không có quyền đăng ký'; end if;
  select capacity into maximum from public.duty_schedules where id=p_schedule_id and ends_at>now() for update;
  if maximum is null then raise exception 'Lịch trực không tồn tại hoặc đã kết thúc'; end if;
  select count(*) into registered from public.duty_registrations where schedule_id=p_schedule_id;
  if registered>=maximum then raise exception 'Lịch trực đã đủ người'; end if;
  insert into public.duty_registrations(schedule_id,user_id,display_name,role)
  values(p_schedule_id,p.user_id,p.display_name,p.role) on conflict(schedule_id,user_id) do nothing;
end; $$;

create or replace function public.cancel_duty_registration(p_schedule_id uuid)
returns void language sql security definer set search_path='' as $$
  delete from public.duty_registrations where schedule_id=p_schedule_id and user_id=(select auth.uid());
$$;

revoke all on function public.register_for_duty(uuid) from public;
revoke all on function public.cancel_duty_registration(uuid) from public;
grant execute on function public.register_for_duty(uuid) to authenticated;
grant execute on function public.cancel_duty_registration(uuid) to authenticated;

-- Yêu cầu PostgREST cập nhật ngay các bảng và hàm vừa tạo.
notify pgrst, 'reload schema';

-- Chạy toàn bộ file này MỘT LẦN trong Supabase SQL Editor.

alter table public.members add column if not exists student_id text not null default '';
alter table public.members alter column student_id drop default;
alter table public.manager_profiles drop constraint if exists manager_profiles_role_check;
alter table public.manager_profiles add constraint manager_profiles_role_check check (role in ('admin','leader','deputy','member'));
alter table public.manager_profiles drop constraint if exists manager_profiles_requested_role_check;
alter table public.manager_profiles add constraint manager_profiles_requested_role_check check (requested_role in ('leader','deputy','member'));

create or replace function private.is_approved_account()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.manager_profiles where user_id=(select auth.uid()) and role in ('admin','leader','deputy','member') and status='approved');
$$;

drop policy if exists "Own profile or admin reads" on public.manager_profiles;
create policy "Own profile or admin reads" on public.manager_profiles for select to authenticated using ((select auth.uid())=user_id or (select private.is_admin()) or (status='approved' and role in ('leader','deputy') and (select private.is_approved_account())));
drop policy if exists "Approved managers read members" on public.members;
create policy "Approved managers read members" on public.members for select to authenticated using ((select private.is_approved_account()));

alter table public.members add column if not exists auth_user_id uuid unique references auth.users(id) on delete set null;
alter table public.members add column if not exists invite_code text unique;
update public.members set invite_code=upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)) where invite_code is null;
alter table public.members alter column invite_code set not null;

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null, content text not null,
  type text not null check (type in ('hospital_shift','donation_site','general')),
  location text, event_time timestamptz,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create or replace function public.create_pending_manager_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
declare requested text := new.raw_user_meta_data->>'requested_role';
declare code text := upper(nullif(new.raw_user_meta_data->>'invite_code',''));
declare linked_count integer := 0;
begin
  if requested in ('leader','deputy','member') then
    insert into public.manager_profiles(user_id,display_name,email,role,requested_role,status)
    values(new.id,coalesce(nullif(new.raw_user_meta_data->>'display_name',''),'Người dùng'),new.email,requested,requested,case when requested='member' then 'approved' else 'pending' end)
    on conflict(user_id) do nothing;
  end if;

  if requested='member' then
    if code is not null then
      update public.members set auth_user_id=new.id where invite_code=code and auth_user_id is null;
      get diagnostics linked_count = row_count;
      if linked_count=0 then raise exception 'Mã liên kết không hợp lệ hoặc đã được sử dụng'; end if;
    else
      insert into public.members(id,name,student_id,role,membership,class_name,faculty,phone,photo,auth_user_id,invite_code,updated_by)
      values(new.id,coalesce(nullif(new.raw_user_meta_data->>'display_name',''),'Thành viên'),coalesce(new.raw_user_meta_data->>'student_id',''),'member','volunteer',coalesce(new.raw_user_meta_data->>'class_name',''),coalesce(new.raw_user_meta_data->>'faculty',''),coalesce(new.raw_user_meta_data->>'phone',''),null,new.id,upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),new.id);
    end if;
  end if;
  return new;
end; $$;

drop policy if exists "Members update own profile" on public.members;
create policy "Members update own profile" on public.members for update to authenticated
using (auth_user_id=(select auth.uid()) and (select private.is_approved_account()))
with check (auth_user_id=(select auth.uid()) and (select private.is_approved_account()));

create or replace function public.protect_member_managed_fields()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_approved_manager() then
    if new.role is distinct from old.role or new.membership is distinct from old.membership
       or (new.auth_user_id is distinct from old.auth_user_id and old.auth_user_id is not null)
       or new.invite_code is distinct from old.invite_code then
      raise exception 'Thành viên không được thay đổi vai trò, đối tượng hoặc liên kết tài khoản';
    end if;
  end if;
  return new;
end; $$;
drop trigger if exists protect_member_managed_fields_trigger on public.members;
create trigger protect_member_managed_fields_trigger before update on public.members
for each row execute function public.protect_member_managed_fields();

alter table public.announcements enable row level security;
revoke all on public.announcements from anon, authenticated;
grant select, insert, delete on public.announcements to authenticated;
drop policy if exists "Approved accounts read announcements" on public.announcements;
drop policy if exists "Managers create announcements" on public.announcements;
drop policy if exists "Managers delete announcements" on public.announcements;
create policy "Approved accounts read announcements" on public.announcements for select to authenticated using ((select private.is_approved_account()));
create policy "Managers create announcements" on public.announcements for insert to authenticated with check ((select private.is_approved_manager()) and created_by=(select auth.uid()));
create policy "Managers delete announcements" on public.announcements for delete to authenticated using ((select private.is_approved_manager()));

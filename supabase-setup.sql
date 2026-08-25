create schema if not exists private;

create table if not exists public.manager_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null, email text,
  role text not null check (role in ('admin', 'leader', 'deputy', 'member')),
  requested_role text check (requested_role in ('leader', 'deputy', 'member')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'locked')),
  reviewed_by uuid references auth.users(id), reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key, name text not null, student_id text not null,
  role text not null check (role in ('leader', 'deputy', 'member')),
  membership text not null check (membership in ('volunteer', 'association')),
  class_name text not null, faculty text not null, phone text not null, photo text,
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create or replace function private.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.manager_profiles where user_id=(select auth.uid()) and role='admin' and status='approved');
$$;
create or replace function private.is_approved_manager() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.manager_profiles where user_id=(select auth.uid()) and role in ('admin','leader','deputy') and status='approved');
$$;
create or replace function private.is_approved_account() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.manager_profiles where user_id=(select auth.uid()) and role in ('admin','leader','deputy','member') and status='approved');
$$;

create or replace function public.create_pending_manager_profile() returns trigger language plpgsql security definer set search_path = '' as $$
declare requested text := new.raw_user_meta_data->>'requested_role';
begin
  if requested in ('leader','deputy','member') then
    insert into public.manager_profiles(user_id,display_name,email,role,requested_role,status)
    values(new.id,coalesce(nullif(new.raw_user_meta_data->>'display_name',''),'Người dùng'),new.email,requested,requested,case when requested='member' then 'approved' else 'pending' end)
    on conflict(user_id) do nothing;
  end if;
  return new;
end; $$;
drop trigger if exists on_manager_user_created on auth.users;
create trigger on_manager_user_created after insert on auth.users for each row execute function public.create_pending_manager_profile();

alter table public.manager_profiles enable row level security;
alter table public.members enable row level security;
revoke all on table public.manager_profiles from anon, authenticated;
revoke all on table public.members from anon, authenticated;
grant select, update on table public.manager_profiles to authenticated;
grant select, insert, update, delete on table public.members to authenticated;

drop policy if exists "Managers read own profile" on public.manager_profiles;
drop policy if exists "Own profile or admin reads" on public.manager_profiles;
drop policy if exists "Admin updates profiles" on public.manager_profiles;
create policy "Own profile or admin reads" on public.manager_profiles for select to authenticated using ((select auth.uid())=user_id or (select private.is_admin()) or (status='approved' and role in ('leader','deputy') and (select private.is_approved_account())));
create policy "Admin updates profiles" on public.manager_profiles for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

drop policy if exists "Managers read members" on public.members;
drop policy if exists "Managers add members" on public.members;
drop policy if exists "Managers update members" on public.members;
drop policy if exists "Managers delete members" on public.members;
drop policy if exists "Approved managers read members" on public.members;
drop policy if exists "Approved managers add members" on public.members;
drop policy if exists "Approved managers update members" on public.members;
drop policy if exists "Approved managers delete members" on public.members;
create policy "Approved managers read members" on public.members for select to authenticated using ((select private.is_approved_account()));
create policy "Approved managers add members" on public.members for insert to authenticated with check ((select private.is_approved_manager()));
create policy "Approved managers update members" on public.members for update to authenticated using ((select private.is_approved_manager())) with check ((select private.is_approved_manager()));
create policy "Approved managers delete members" on public.members for delete to authenticated using ((select private.is_approved_manager()));

-- TẠO ADMIN ĐẦU TIÊN: tạo user trong Authentication > Users, rồi thay 3 giá trị dưới đây và chạy lệnh.
-- insert into public.manager_profiles(user_id,display_name,email,role,status)
-- values('UUID_ADMIN','Tên quản trị viên','admin@email.com','admin','approved');

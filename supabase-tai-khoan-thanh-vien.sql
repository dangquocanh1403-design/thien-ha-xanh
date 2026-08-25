-- Chạy toàn bộ file này MỘT LẦN trong Supabase SQL Editor.

-- 1. Thêm mã sinh viên vào danh sách hiện có.
alter table public.members add column if not exists student_id text not null default '';
alter table public.members alter column student_id drop default;

-- 2. Cho phép vai trò tài khoản thành viên.
alter table public.manager_profiles drop constraint if exists manager_profiles_role_check;
alter table public.manager_profiles add constraint manager_profiles_role_check
  check (role in ('admin','leader','deputy','member'));
alter table public.manager_profiles drop constraint if exists manager_profiles_requested_role_check;
alter table public.manager_profiles add constraint manager_profiles_requested_role_check
  check (requested_role in ('leader','deputy','member'));

-- 3. Thành viên đã đăng ký được đọc dữ liệu, nhưng không được thêm/sửa/xóa.
create or replace function private.is_approved_account()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(
    select 1 from public.manager_profiles
    where user_id=(select auth.uid())
      and role in ('admin','leader','deputy','member')
      and status='approved'
  );
$$;

-- 4. Tự tạo hồ sơ: thành viên duyệt ngay; trưởng/phó vẫn chờ admin.
create or replace function public.create_pending_manager_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
declare requested text := new.raw_user_meta_data->>'requested_role';
begin
  if requested in ('leader','deputy','member') then
    insert into public.manager_profiles(user_id,display_name,email,role,requested_role,status)
    values(
      new.id,
      coalesce(nullif(new.raw_user_meta_data->>'display_name',''),'Người dùng'),
      new.email,
      requested,
      requested,
      case when requested='member' then 'approved' else 'pending' end
    ) on conflict(user_id) do nothing;
  end if;
  return new;
end; $$;

drop policy if exists "Own profile or admin reads" on public.manager_profiles;
create policy "Own profile or admin reads" on public.manager_profiles
for select to authenticated using (
  (select auth.uid())=user_id
  or (select private.is_admin())
  or (status='approved' and role in ('leader','deputy') and (select private.is_approved_account()))
);

drop policy if exists "Approved managers read members" on public.members;
create policy "Approved managers read members" on public.members
for select to authenticated using ((select private.is_approved_account()));

-- Các policy thêm/sửa/xóa cũ vẫn dùng is_approved_manager(),
-- vì vậy tài khoản thành viên chỉ có quyền xem.

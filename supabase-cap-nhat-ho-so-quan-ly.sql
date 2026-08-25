-- Chạy toàn bộ file này MỘT LẦN trong Supabase SQL Editor.
-- Cho phép nhóm trưởng/nhóm phó tự cập nhật hồ sơ nhưng không thể tự đổi vai trò hoặc trạng thái duyệt.

alter table public.manager_profiles add column if not exists student_id text not null default '';
alter table public.manager_profiles add column if not exists class_name text not null default '';
alter table public.manager_profiles add column if not exists faculty text not null default '';
alter table public.manager_profiles add column if not exists phone text not null default '';
alter table public.manager_profiles add column if not exists photo text;
alter table public.manager_profiles add column if not exists membership text not null default 'volunteer';

alter table public.manager_profiles drop constraint if exists manager_profiles_membership_check;
alter table public.manager_profiles add constraint manager_profiles_membership_check
  check (membership in ('volunteer', 'association'));

create or replace function public.update_own_manager_profile(
  p_display_name text,
  p_student_id text,
  p_class_name text,
  p_faculty text,
  p_phone text,
  p_photo text,
  p_membership text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_membership not in ('volunteer', 'association') then
    raise exception 'Đối tượng không hợp lệ';
  end if;

  update public.manager_profiles
  set display_name = left(trim(p_display_name), 60),
      student_id = left(trim(coalesce(p_student_id, '')), 30),
      class_name = left(trim(coalesce(p_class_name, '')), 30),
      faculty = left(trim(coalesce(p_faculty, '')), 60),
      phone = left(trim(coalesce(p_phone, '')), 15),
      photo = p_photo,
      membership = p_membership
  where user_id = (select auth.uid())
    and status = 'approved'
    and role in ('leader', 'deputy');

  if not found then
    raise exception 'Tài khoản không có quyền cập nhật hồ sơ quản lý';
  end if;
end;
$$;

revoke all on function public.update_own_manager_profile(text,text,text,text,text,text,text) from public;
grant execute on function public.update_own_manager_profile(text,text,text,text,text,text,text) to authenticated;


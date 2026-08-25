-- Chạy file này một lần trong Supabase SQL Editor.
-- Cho phép tài khoản quản lý đã duyệt xem tên/vai trò của trưởng và phó đã duyệt.
drop policy if exists "Own profile or admin reads" on public.manager_profiles;

create policy "Own profile or admin reads"
on public.manager_profiles
for select
to authenticated
using (
  (select auth.uid()) = user_id
  or (select private.is_admin())
  or (
    status = 'approved'
    and role in ('leader', 'deputy')
    and (select private.is_approved_manager())
  )
);

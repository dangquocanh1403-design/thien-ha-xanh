-- Chỉ dùng file này nếu bạn đã chạy phiên bản supabase-setup.sql cũ.
alter table public.manager_profiles drop constraint if exists manager_profiles_role_check;
alter table public.manager_profiles add constraint manager_profiles_role_check check (role in ('admin','leader','deputy'));
alter table public.manager_profiles add column if not exists email text;
alter table public.manager_profiles add column if not exists requested_role text check (requested_role in ('leader','deputy'));
alter table public.manager_profiles add column if not exists status text not null default 'pending' check (status in ('pending','approved','rejected','locked'));
alter table public.manager_profiles add column if not exists reviewed_by uuid references auth.users(id);
alter table public.manager_profiles add column if not exists reviewed_at timestamptz;

-- Hai tài khoản trưởng/phó đã tồn tại được giữ lại và tự động công nhận.
update public.manager_profiles p
set status='approved', requested_role=p.role, email=u.email
from auth.users u
where p.user_id=u.id and p.role in ('leader','deputy');

-- Sau lệnh này, chạy tiếp toàn bộ file supabase-setup.sql mới.

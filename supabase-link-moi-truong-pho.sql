-- Chạy toàn bộ file này MỘT LẦN trong Supabase SQL Editor.
create table if not exists public.manager_invites (
  token text primary key,
  role text not null check (role in ('leader','deputy')),
  created_by uuid not null references auth.users(id),
  used_by uuid references auth.users(id),
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table public.manager_invites enable row level security;
revoke all on public.manager_invites from anon, authenticated;
grant select, insert on public.manager_invites to authenticated;
drop policy if exists "Admin reads manager invites" on public.manager_invites;
drop policy if exists "Admin creates manager invites" on public.manager_invites;
create policy "Admin reads manager invites" on public.manager_invites for select to authenticated using ((select private.is_admin()));
create policy "Admin creates manager invites" on public.manager_invites for insert to authenticated with check ((select private.is_admin()) and created_by=(select auth.uid()));

create or replace function public.create_pending_manager_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
declare requested text := new.raw_user_meta_data->>'requested_role';
declare code text := upper(nullif(new.raw_user_meta_data->>'invite_code',''));
declare manager_token text := nullif(new.raw_user_meta_data->>'manager_invite_token','');
declare linked_count integer := 0;
declare approved_status text := 'pending';
begin
  if requested in ('leader','deputy') and manager_token is not null then
    update public.manager_invites set used_by=new.id
    where token=manager_token and role=requested and used_by is null and expires_at>now();
    get diagnostics linked_count = row_count;
    if linked_count=0 then raise exception 'Link mời không hợp lệ, đã dùng hoặc đã hết hạn'; end if;
    approved_status := 'approved';
  elsif requested='member' then
    approved_status := 'approved';
  end if;

  if requested in ('leader','deputy','member') then
    insert into public.manager_profiles(user_id,display_name,email,role,requested_role,status)
    values(new.id,coalesce(nullif(new.raw_user_meta_data->>'display_name',''),'Người dùng'),new.email,requested,requested,approved_status)
    on conflict(user_id) do nothing;
  end if;

  if requested='member' then
    linked_count := 0;
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

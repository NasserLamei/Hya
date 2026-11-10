-- شغّلي الملف ده مرة لو المشروع اتعمل قبل إضافة السن والصورة وأسبوع الحمل.
alter table public.profiles add column if not exists mother_age int;
alter table public.profiles add column if not exists photo_url text;
alter table public.community_stories add column if not exists pregnancy_week int;
alter table public.community_stories add column if not exists mother_age int;

create or replace function public.email_is_registered(check_email text)
returns boolean
language sql
security definer
set search_path = auth, public
as $$
  select exists (
    select 1
    from auth.users
    where lower(email) = lower(trim(check_email))
  );
$$;

revoke all on function public.email_is_registered(text) from public;
grant execute on function public.email_is_registered(text) to anon, authenticated;

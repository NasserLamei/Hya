-- هي / Hya
-- شغّلي الملف ده في SQL Editor داخل مشروع Supabase.
-- الجداول مربوطة بحساب كل مستخدمة، ومحدش يقدر يشوف بيانات غيرها.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  current_mode text not null default 'pregnant'
    check (current_mode in ('ttc', 'pregnant', 'postpartum')),
  last_period_date date,
  cycle_length int not null default 28 check (cycle_length between 20 and 45),
  expected_due_date date,
  baby_name text,
  baby_birth_date date,
  delivery_type text check (delivery_type in ('natural', 'cesarean')),
  mother_age int check (mother_age is null or (mother_age between 14 and 60)),
  photo_url text,
  hospital_checks text[] not null default '{}',
  vaccine_checks text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists mother_age int;
alter table public.profiles add column if not exists photo_url text;

create table if not exists public.daily_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  log_date date not null,
  mood text,
  symptoms jsonb not null default '[]'::jsonb,
  bb_temperature numeric(4, 2),
  kicks int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, log_date)
);

create table if not exists public.time_capsules (
  id uuid primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null default '',
  message_text text not null,
  unlock_date date not null,
  created_at timestamptz not null default now()
);

create table if not exists public.baby_logs (
  id uuid primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  log_type text not null
    check (log_type in ('feed_left', 'feed_right', 'diaper', 'sleep', 'pump')),
  note text,
  logged_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.daily_logs enable row level security;
alter table public.time_capsules enable row level security;
alter table public.baby_logs enable row level security;

drop policy if exists profiles_own on public.profiles;
create policy profiles_own on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists daily_logs_own on public.daily_logs;
create policy daily_logs_own on public.daily_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists capsules_own on public.time_capsules;
create policy capsules_own on public.time_capsules
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists baby_logs_own on public.baby_logs;
create policy baby_logs_own on public.baby_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated on public.profiles;
create trigger profiles_updated
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists daily_logs_updated on public.daily_logs;
create trigger daily_logs_updated
  before update on public.daily_logs
  for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- تجارب الأمهات (حكاوي عامة + تجربتي)
create table if not exists public.community_stories (
  id uuid primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  display_name text not null default 'ماما',
  title text not null default '',
  body text not null,
  topic text not null default 'حمل',
  pregnancy_week int check (pregnancy_week is null or (pregnancy_week between 1 and 45)),
  pregnancy_number int check (pregnancy_number is null or (pregnancy_number between 1 and 20)),
  mother_age int check (mother_age is null or (mother_age between 14 and 60)),
  show_name boolean not null default false,
  is_public boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.community_stories add column if not exists pregnancy_week int;
alter table public.community_stories add column if not exists pregnancy_number int;
alter table public.community_stories add column if not exists mother_age int;
alter table public.community_stories add column if not exists show_name boolean not null default false;

create index if not exists community_stories_public_created_idx
  on public.community_stories (created_at desc)
  where is_public = true;

create index if not exists community_stories_user_idx
  on public.community_stories (user_id, created_at desc);

alter table public.community_stories enable row level security;

drop policy if exists community_stories_read on public.community_stories;
create policy community_stories_read on public.community_stories
  for select using (is_public = true or auth.uid() = user_id);

drop policy if exists community_stories_insert on public.community_stories;
create policy community_stories_insert on public.community_stories
  for insert with check (auth.uid() = user_id);

drop policy if exists community_stories_update on public.community_stories;
create policy community_stories_update on public.community_stories
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists community_stories_delete on public.community_stories;
create policy community_stories_delete on public.community_stories
  for delete using (auth.uid() = user_id);

-- نسيت كلمة السر:
-- Authentication → URL Configuration
-- Site URL: hya://auth-callback
-- Redirect URLs: أضيفي hya://auth-callback
-- (اللينك القديم كان بيروح localhost:3000 وده سبب ERR_CONNECTION_REFUSED على الموبايل)

-- التحقق إن الإيميل متسجل قبل ما نعمل حساب جديد
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

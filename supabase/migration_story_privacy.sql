-- خصوصية التجارب + رقم الحمل
alter table public.community_stories
  add column if not exists show_name boolean not null default false;

alter table public.community_stories
  add column if not exists pregnancy_number int;

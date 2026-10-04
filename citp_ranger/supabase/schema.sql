-- Temporary shared database for the Ranger App demo.
-- Run this in the Supabase SQL editor, then run seed.sql.
-- The anon key can read and write these tables. Delete the project after the demo.

create table if not exists public.sites (
  id uuid primary key,
  ranger_name text not null,
  species text not null check (
    species in (
      'rubbervine',
      'sicklepod',
      'lantana',
      'gamba_grass',
      'giant_rats_tail',
      'olive_hymenachne'
    )
  ),
  latitude double precision,
  longitude double precision,
  notes text not null default '',
  photo_url text,
  status text not null check (status in ('draft', 'pending', 'open', 'rejected')),
  source text not null default 'ranger',
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table if not exists public.treatments (
  id uuid primary key,
  site_id uuid not null references public.sites (id) on delete cascade,
  ranger_name text not null,
  treated_at timestamptz not null,
  notes text not null default '',
  next_check_due timestamptz not null
);

alter table public.sites enable row level security;
alter table public.treatments enable row level security;

drop policy if exists demo_all_sites on public.sites;
create policy demo_all_sites on public.sites
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists demo_all_treatments on public.treatments;
create policy demo_all_treatments on public.treatments
  for all
  to anon, authenticated
  using (true)
  with check (true);

grant select, insert, update, delete on public.sites to anon, authenticated;
grant select, insert, update, delete on public.treatments to anon, authenticated;

insert into storage.buckets (id, name, public)
values ('site-photos', 'site-photos', true)
on conflict (id) do nothing;

drop policy if exists demo_read_photos on storage.objects;
create policy demo_read_photos on storage.objects
  for select
  to anon, authenticated
  using (bucket_id = 'site-photos');

drop policy if exists demo_insert_photos on storage.objects;
create policy demo_insert_photos on storage.objects
  for insert
  to anon, authenticated
  with check (bucket_id = 'site-photos');

drop policy if exists demo_update_photos on storage.objects;
create policy demo_update_photos on storage.objects
  for update
  to anon, authenticated
  using (bucket_id = 'site-photos');

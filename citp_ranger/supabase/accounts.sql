-- Accounts for the demo, plus public reports that wait for approval.
-- Run once against the linked Supabase project.

create extension if not exists pgcrypto with schema extensions;

alter table public.sites drop constraint if exists sites_status_check;
alter table public.sites
  add constraint sites_status_check
  check (status in ('draft', 'pending', 'open', 'rejected'));

alter table public.sites add column if not exists source text not null default 'ranger';

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  password_hash text not null,
  role text not null check (role in ('admin', 'ranger')),
  display_name text not null
);

alter table public.accounts enable row level security;

create or replace function public.sign_in(p_email text, p_password text)
returns table (id uuid, display_name text, role text)
language sql
security definer
set search_path = public, extensions
as $$
  select a.id, a.display_name, a.role
  from public.accounts a
  where a.email = lower(trim(p_email))
    and a.password_hash = crypt(p_password, a.password_hash);
$$;

grant execute on function public.sign_in(text, text) to anon, authenticated;

insert into public.accounts (email, password_hash, role, display_name)
values
  ('admin@lamalama.test', extensions.crypt('Admin1234', extensions.gen_salt('bf')), 'admin', 'Admin'),
  ('ranger@lamalama.test', extensions.crypt('Ranger1234', extensions.gen_salt('bf')), 'ranger', 'Ranger')
on conflict (email) do nothing;

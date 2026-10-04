-- Demo sites. Same ids as the copy created on a fresh phone.
-- Points are fictional and sit in a small box near Port Stewart so the map has something to show.

insert into public.sites (
  id, ranger_name, species, latitude, longitude, notes, status, created_at, updated_at
) values
  (
    '11111111-1111-4111-8111-111111111101',
    'Alex', 'rubbervine', -14.35210, 143.67120,
    'Demo point for the prototype. Not a surveyed infestation.',
    'open', now() - interval '18 days', now() - interval '18 days'
  ),
  (
    '11111111-1111-4111-8111-111111111102',
    'Sam', 'sicklepod', -14.36080, 143.68940,
    'Demo point for the prototype. Not a surveyed infestation.',
    'open', now() - interval '45 days', now() - interval '45 days'
  ),
  (
    '11111111-1111-4111-8111-111111111103',
    'Jo', 'lantana', -14.37120, 143.67650,
    'Demo point for the prototype. Not a surveyed infestation.',
    'open', now() - interval '12 days', now() - interval '12 days'
  ),
  (
    '11111111-1111-4111-8111-111111111104',
    'Alex', 'gamba_grass', -14.34760, 143.70110,
    'Demo point for the prototype. Not a surveyed infestation.',
    'open', now() - interval '9 days', now() - interval '9 days'
  ),
  (
    '11111111-1111-4111-8111-111111111105',
    'Sam', 'giant_rats_tail', -14.37840, 143.70880,
    'Demo point for the prototype. Not a surveyed infestation.',
    'open', now() - interval '6 days', now() - interval '6 days'
  ),
  (
    '11111111-1111-4111-8111-111111111106',
    'Jo', 'olive_hymenachne', -14.35690, 143.65870,
    'Demo point for the prototype. Not a surveyed infestation.',
    'open', now() - interval '4 days', now() - interval '4 days'
  )
on conflict (id) do nothing;

insert into public.treatments (
  id, site_id, ranger_name, treated_at, notes, next_check_due
) values
  (
    '22222222-2222-4222-8222-222222222202',
    '11111111-1111-4111-8111-111111111102',
    'Sam', now() - interval '40 days', 'Demo spray record.',
    now() - interval '10 days'
  ),
  (
    '22222222-2222-4222-8222-222222222203',
    '11111111-1111-4111-8111-111111111103',
    'Jo', now() - interval '10 days', 'Demo spray record.',
    now() + interval '20 days'
  ),
  (
    '22222222-2222-4222-8222-222222222206',
    '11111111-1111-4111-8111-111111111106',
    'Jo', now() - interval '2 days', 'Demo spray record.',
    now() + interval '28 days'
  )
on conflict (id) do nothing;

-- =====================================================================
-- Salon Booking — Supabase (PostgreSQL) schema
-- Run this whole file in: Supabase Dashboard → SQL Editor → New query
-- =====================================================================

create extension if not exists btree_gist;   -- needed for the no-double-booking constraint

-- ---------- Types ----------
do $$ begin
  create type appointment_status as enum ('confirmed', 'cancelled', 'completed');
exception when duplicate_object then null; end $$;

-- ---------- Tables ----------
create table if not exists profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  phone       text,
  created_at  timestamptz not null default now()
);

create table if not exists salons (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  address      text not null,
  city         text,
  phone        text,
  description  text,
  image_url    text,
  open_time    time not null default '09:00',
  close_time   time not null default '19:00',
  created_at   timestamptz not null default now(),
  check (close_time > open_time)
);

create table if not exists services (
  id                uuid primary key default gen_random_uuid(),
  salon_id          uuid not null references salons(id) on delete cascade,
  name              text not null,
  description       text,
  duration_minutes  int  not null check (duration_minutes > 0),
  price             numeric(12,2) not null check (price >= 0)
);

create table if not exists stylists (
  id          uuid primary key default gen_random_uuid(),
  salon_id    uuid not null references salons(id) on delete cascade,
  name        text not null,
  bio         text,
  avatar_url  text
);

create table if not exists appointments (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  salon_id    uuid not null references salons(id)   on delete cascade,
  service_id  uuid not null references services(id) on delete restrict,
  stylist_id  uuid not null references stylists(id) on delete restrict,
  starts_at   timestamptz not null,
  ends_at     timestamptz not null,
  status      appointment_status not null default 'confirmed',
  notes       text,
  created_at  timestamptz not null default now(),
  check (ends_at > starts_at),
  -- A stylist cannot have two confirmed appointments that overlap in time.
  constraint no_double_booking
    exclude using gist (
      stylist_id with =,
      tstzrange(starts_at, ends_at) with &&
    ) where (status = 'confirmed')
);

create index if not exists idx_services_salon       on services(salon_id);
create index if not exists idx_stylists_salon       on stylists(salon_id);
create index if not exists idx_appointments_user    on appointments(user_id, starts_at);
create index if not exists idx_appointments_stylist on appointments(stylist_id, starts_at);

-- ---------- Auto-create a profile when someone signs up ----------
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name')
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ---------- Row Level Security ----------
alter table profiles     enable row level security;
alter table salons       enable row level security;
alter table services     enable row level security;
alter table stylists     enable row level security;
alter table appointments enable row level security;

-- Anyone can browse salons / services / stylists
create policy "salons are public"   on salons   for select using (true);
create policy "services are public" on services for select using (true);
create policy "stylists are public" on stylists for select using (true);

-- Profiles: users see and edit only their own
create policy "own profile read"   on profiles for select using (id = auth.uid());
create policy "own profile update" on profiles for update using (id = auth.uid());

-- Appointments: users can only READ their own.
-- All writes go through the functions below (so rules can't be bypassed).
create policy "own appointments read" on appointments for select using (user_id = auth.uid());

-- ---------- Functions (called from the app via .rpc()) ----------

-- Busy time ranges for one stylist (no personal data leaked, just times)
create or replace function get_busy_slots(p_stylist uuid, p_from timestamptz, p_to timestamptz)
returns table (starts_at timestamptz, ends_at timestamptz)
language sql stable security definer set search_path = public as $$
  select a.starts_at, a.ends_at
  from appointments a
  where a.stylist_id = p_stylist
    and a.status = 'confirmed'
    and a.starts_at < p_to
    and a.ends_at   > p_from;
$$;

-- Book an appointment (validates everything server-side)
create or replace function book_appointment(
  p_service uuid, p_stylist uuid, p_starts_at timestamptz, p_notes text default null
) returns appointments
language plpgsql security definer set search_path = public as $$
declare
  v_service services;
  v_row     appointments;
begin
  if auth.uid() is null then
    raise exception 'You must be signed in to book.';
  end if;

  select * into v_service from services where id = p_service;
  if not found then raise exception 'Service not found.'; end if;

  perform 1 from stylists where id = p_stylist and salon_id = v_service.salon_id;
  if not found then raise exception 'This stylist does not work at that salon.'; end if;

  if p_starts_at <= now() then
    raise exception 'You cannot book a time in the past.';
  end if;

  insert into appointments (user_id, salon_id, service_id, stylist_id, starts_at, ends_at, notes)
  values (
    auth.uid(), v_service.salon_id, p_service, p_stylist, p_starts_at,
    p_starts_at + make_interval(mins => v_service.duration_minutes), p_notes
  )
  returning * into v_row;

  return v_row;
exception
  when exclusion_violation then
    raise exception 'That time was just taken. Please choose another slot.';
end $$;

-- Cancel one of your own upcoming appointments
create or replace function cancel_appointment(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update appointments
     set status = 'cancelled'
   where id = p_id
     and user_id = auth.uid()
     and status = 'confirmed'
     and starts_at > now();
  if not found then
    raise exception 'This appointment cannot be cancelled.';
  end if;
end $$;

revoke all on function book_appointment(uuid, uuid, timestamptz, text) from public, anon;
revoke all on function cancel_appointment(uuid)                        from public, anon;
grant execute on function book_appointment(uuid, uuid, timestamptz, text) to authenticated;
grant execute on function cancel_appointment(uuid)                        to authenticated;
grant execute on function get_busy_slots(uuid, timestamptz, timestamptz) to authenticated;

-- =====================================================================
-- Sample data (delete if you don't want it)
-- =====================================================================
insert into salons (name, address, city, phone, description, open_time, close_time) values
  ('Nomin Hair Studio',   'Peace Avenue 12, Sukhbaatar District', 'Ulaanbaatar', '+976 7011 1234',
   'Cuts, colour and styling in the city centre.', '10:00', '20:00'),
  ('Gobi Barber & Beauty','Baga Toiruu 45, Chingeltei District',  'Ulaanbaatar', '+976 7022 5678',
   'Modern barbershop and beauty salon.',          '09:00', '19:00');

insert into services (salon_id, name, duration_minutes, price)
select s.id, v.name, v.dur, v.price
from salons s
join (values
  ('Nomin Hair Studio',   'Women''s haircut',  60,  35000),
  ('Nomin Hair Studio',   'Men''s haircut',    30,  20000),
  ('Nomin Hair Studio',   'Hair colouring',   120,  90000),
  ('Nomin Hair Studio',   'Blow-dry & style',  45,  25000),
  ('Gobi Barber & Beauty','Classic haircut',   30,  18000),
  ('Gobi Barber & Beauty','Beard trim',        30,  12000),
  ('Gobi Barber & Beauty','Haircut + beard',   60,  28000)
) as v(salon, name, dur, price) on v.salon = s.name;

insert into stylists (salon_id, name, bio)
select s.id, v.name, v.bio
from salons s
join (values
  ('Nomin Hair Studio',   'Nomin',      'Senior stylist, 10 years experience'),
  ('Nomin Hair Studio',   'Anu',        'Colour specialist'),
  ('Gobi Barber & Beauty','Temuulen',   'Master barber'),
  ('Gobi Barber & Beauty','Bat-Erdene', 'Fades and beard design')
) as v(salon, name, bio) on v.salon = s.name;

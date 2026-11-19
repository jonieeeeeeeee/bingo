-- ============================================================
-- Prednáškové bingo – kompletná schéma pre Supabase
-- Spusti raz v Supabase: SQL Editor → New query → Run
-- ============================================================

-- 1) TABUĽKY ------------------------------------------------
create table if not exists rooms (
  code       text primary key,
  name       text not null,
  host       uuid not null references auth.users(id) on delete cascade,
  phrases    text[] not null default '{}',
  round      int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists players (
  room       text not null references rooms(code) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  name       text not null default 'Hráč',
  avatar     text not null default '🦊',
  marks      boolean[] not null default array_fill(false, array[16]),
  updated_at timestamptz not null default now(),
  primary key (room, user_id)
);

create table if not exists teachers (
  id         uuid primary key default gen_random_uuid(),
  owner      uuid not null references auth.users(id) on delete cascade,
  name       text not null,
  phrases    text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  name       text,
  avatar     text,
  created_at timestamptz not null default now()
);

-- 2) RLS ----------------------------------------------------
alter table rooms    enable row level security;
alter table players  enable row level security;
alter table teachers enable row level security;
alter table profiles enable row level security;

-- rooms: čítať môže každý prihlásený (aj anoným), zapisovať len vlastník
drop policy if exists "rooms read"        on rooms;
drop policy if exists "rooms host insert" on rooms;
drop policy if exists "rooms host update" on rooms;
drop policy if exists "rooms host delete" on rooms;

create policy "rooms read" on rooms for select to authenticated using (true);

create policy "rooms host insert" on rooms for insert to authenticated
  with check (host = auth.uid()
    and coalesce((auth.jwt()->>'is_anonymous')::boolean,false) = false);

create policy "rooms host update" on rooms for update to authenticated
  using (host = auth.uid())
  with check (host = auth.uid());

create policy "rooms host delete" on rooms for delete to authenticated
  using (host = auth.uid());

-- players: čítať všetci v miestnosti, zapisovať len svoj riadok
drop policy if exists "players read"   on players;
drop policy if exists "players insert" on players;
drop policy if exists "players update" on players;
drop policy if exists "players delete" on players;

create policy "players read"   on players for select to authenticated using (true);
create policy "players insert" on players for insert to authenticated with check (user_id = auth.uid());
create policy "players update" on players for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "players delete" on players for delete to authenticated using (user_id = auth.uid());

-- teachers: čítať všetci, zapisovať len vlastník a len registrovaní
drop policy if exists "teachers read"      on teachers;
drop policy if exists "teachers own write" on teachers;

create policy "teachers read" on teachers for select to authenticated using (true);
create policy "teachers own write" on teachers for all to authenticated
  using (owner = auth.uid())
  with check (owner = auth.uid()
    and coalesce((auth.jwt()->>'is_anonymous')::boolean,false) = false);

-- profiles
drop policy if exists "profiles read"   on profiles;
drop policy if exists "profiles own"    on profiles;

create policy "profiles read" on profiles for select to authenticated using (true);
create policy "profiles own"  on profiles for all    to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- 3) REALTIME -----------------------------------------------
alter publication supabase_realtime add table rooms;
alter publication supabase_realtime add table players;

-- 4) ČISTENIE STARÝCH MIESTNOSTÍ ---------------------------
create or replace function cleanup_rooms() returns void
language sql security definer set search_path = public as $f$
  delete from rooms r
  where greatest(
    r.created_at,
    coalesce((select max(p.updated_at) from players p where p.room = r.code), r.created_at)
  ) < now() - interval '2 hours';
$f$;

create extension if not exists pg_cron;

select cron.schedule(
  'bingo-cleanup', '*/15 * * * *',
  $job$
    select cleanup_rooms();
    delete from auth.users where is_anonymous
      and created_at < now() - interval '7 days';
  $job$
);

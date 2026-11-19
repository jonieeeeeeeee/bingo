-- Spusti v Supabase: SQL Editor -> New query -> Run
create table profiles (id uuid primary key references auth.users on delete cascade, name text, avatar text);
create table teachers (id uuid primary key default gen_random_uuid(), owner uuid not null references auth.users on delete cascade, name text not null, phrases text[] not null default '{}', created_at timestamptz default now());
create table rooms (code text primary key, name text not null, host uuid not null references auth.users on delete cascade, phrases text[] not null default '{}', round int not null default 0, created_at timestamptz default now());
create table players (room text references rooms(code) on delete cascade, user_id uuid references auth.users on delete cascade, name text, avatar text, marks boolean[] default '{}', updated_at timestamptz default now(), primary key (room, user_id));

alter table profiles enable row level security; alter table teachers enable row level security; alter table rooms enable row level security; alter table players enable row level security;

create policy "profiles read" on profiles for select to authenticated using (true);
create policy "profiles own write" on profiles for all to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "teachers read" on teachers for select to authenticated using (true);
create policy "teachers own write" on teachers for all to authenticated using (owner = auth.uid()) with check (owner = auth.uid());
create policy "rooms read" on rooms for select to authenticated using (true);
create policy "rooms host write" on rooms for all to authenticated using (host = auth.uid()) with check (host = auth.uid());
create policy "players read" on players for select to authenticated using (true);
create policy "players own write" on players for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

alter publication supabase_realtime add table rooms, players;

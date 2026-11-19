-- AKTUALIZÁCIA: hostia bez účtu + automatické mazanie neaktívnych miestností.
-- Spusti raz v Supabase: SQL Editor -> New query -> Run.
drop policy if exists "rooms host write" on rooms;
drop policy if exists "rooms host insert" on rooms;
drop policy if exists "rooms host update" on rooms;
drop policy if exists "rooms host delete" on rooms;
create policy "rooms host insert" on rooms for insert to authenticated
  with check (host = auth.uid() and coalesce((auth.jwt()->>'is_anonymous')::boolean,false) = false);
create policy "rooms host update" on rooms for update to authenticated using (host = auth.uid()) with check (host = auth.uid());
create policy "rooms host delete" on rooms for delete to authenticated using (host = auth.uid());
drop policy if exists "teachers own write" on teachers;
create policy "teachers own write" on teachers for all to authenticated using (owner = auth.uid())
  with check (owner = auth.uid() and coalesce((auth.jwt()->>'is_anonymous')::boolean,false) = false);

-- miestnosť bez aktivity 2 hodiny sa zmaže (hráči sa zmažú s ňou)
create or replace function cleanup_rooms() returns void language sql security definer set search_path = public as $f$
  delete from rooms r
  where greatest(r.created_at, coalesce((select max(p.updated_at) from players p where p.room = r.code), r.created_at)) < now() - interval '2 hours';
$f$;
create extension if not exists pg_cron;
select cron.schedule('bingo-cleanup', '*/15 * * * *',
  $job$select cleanup_rooms(); delete from auth.users where is_anonymous and created_at < now() - interval '7 days'$job$);

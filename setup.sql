-- Benchmark Log: database setup
-- Paste all of this into Supabase → SQL Editor → New query, change the email on the
-- "insert into public.crew" line to yours, then press Run. Safe to run again.

-- Who is allowed in. Add one row per crew member (lowercase email).
create table if not exists public.crew (email text primary key);
insert into public.crew (email) values ('you@example.com') on conflict do nothing;

-- All app data: benchmark points, plus each person's saved handwriting samples.
create table if not exists public.docs (
  collection text not null,
  id         text not null,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (collection, id)
);
alter table public.docs replica identity full;
alter table public.docs enable row level security;
alter table public.crew enable row level security;

create or replace function public.is_crew() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.crew where email = lower(auth.jwt() ->> 'email'));
$$;

-- Points: only crew members can see, add, change or delete them.
drop policy if exists "crew reads points"   on public.docs;
drop policy if exists "crew adds points"    on public.docs;
drop policy if exists "crew edits points"   on public.docs;
drop policy if exists "crew deletes points" on public.docs;
drop policy if exists "own handwriting"     on public.docs;
create policy "crew reads points"   on public.docs for select to authenticated using (collection = 'points' and public.is_crew());
create policy "crew adds points"    on public.docs for insert to authenticated with check (collection = 'points' and public.is_crew());
create policy "crew edits points"   on public.docs for update to authenticated using (collection = 'points' and public.is_crew()) with check (collection = 'points' and public.is_crew());
create policy "crew deletes points" on public.docs for delete to authenticated using (collection = 'points' and public.is_crew());
-- Handwriting samples: each person sees only their own.
create policy "own handwriting" on public.docs for all to authenticated
  using (collection = 'data/users/' || auth.uid()) with check (collection = 'data/users/' || auth.uid());

drop policy if exists "crew sees crew list" on public.crew;
create policy "crew sees crew list" on public.crew for select to authenticated using (public.is_crew());

-- Live updates, so new points appear on everyone's phone without refreshing.
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;

-- Private photo storage for crew members.
insert into storage.buckets (id, name, public) values ('photos', 'photos', false) on conflict do nothing;
drop policy if exists "crew views photos"   on storage.objects;
drop policy if exists "crew uploads photos" on storage.objects;
create policy "crew views photos"   on storage.objects for select to authenticated using (bucket_id = 'photos' and public.is_crew());
create policy "crew uploads photos" on storage.objects for insert to authenticated with check (bucket_id = 'photos' and public.is_crew());
-- Benchmark Log: crew join code
-- Change CHANGE-ME below to your crew's code, then Run. Run again any time to change the code.
create table if not exists public.crew_settings (
  id int primary key default 1 check (id = 1),
  join_code text not null
);
alter table public.crew_settings enable row level security;  -- no one can read the code through the website
insert into public.crew_settings (id, join_code) values (1, 'CHANGE-ME')
  on conflict (id) do update set join_code = excluded.join_code;

-- Adds the signed-in person to the crew when their code matches.
create or replace function public.join_crew(code text) returns boolean
language plpgsql security definer set search_path = public as $$
declare ok boolean;
begin
  if auth.uid() is null then return false; end if;
  select exists (select 1 from crew_settings where upper(trim(join_code)) = upper(trim(code))) into ok;
  if ok then
    insert into crew (email) values (lower(auth.jwt() ->> 'email')) on conflict do nothing;
  else
    perform pg_sleep(1);  -- slows down anyone guessing codes
  end if;
  return ok;
end $$;
revoke all on function public.join_crew(text) from public, anon;
grant execute on function public.join_crew(text) to authenticated;
grant execute on function public.is_crew() to authenticated;

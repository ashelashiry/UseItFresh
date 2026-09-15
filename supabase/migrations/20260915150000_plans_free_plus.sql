-- =============================================================================
-- Migration 10 — Plans: free or Plus on every account (owner, 15 Sep 2026)
--
-- Plus features show a lock screen on free accounts. Today nothing is on sale:
-- test accounts are set to Plus by hand (see the bottom), and later a real
-- purchase (RevenueCat / App Store) sets the same columns from the server.
--
--   profiles.plan             'free' (default) or 'plus'
--   profiles.plan_source      where Plus came from: 'test', 'app_store', ...
--   profiles.plan_expires_at  when Plus ends; empty = no end date
--
-- Only the server may change a plan. People can still update their own
-- profile (name, photo, units), but a trigger keeps plan, plan_source and
-- plan_expires_at unchanged when the change comes from the app (roles
-- authenticated / anon). The SQL editor, service role and server functions
-- are not affected.
--
-- Safe to run more than once. The last query lists plans and how many
-- accounts are on each.
-- =============================================================================

alter table public.profiles
  add column if not exists plan text not null default 'free',
  add column if not exists plan_source text,
  add column if not exists plan_expires_at timestamptz;

do $$
begin
  alter table public.profiles
    add constraint profiles_plan_check check (plan in ('free', 'plus'));
exception when duplicate_object then null;
end $$;

create or replace function app_private.guard_profile_plan()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.plan := 'free';
      new.plan_source := null;
      new.plan_expires_at := null;
    else
      new.plan := old.plan;
      new.plan_source := old.plan_source;
      new.plan_expires_at := old.plan_expires_at;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard_plan on public.profiles;
create trigger profiles_guard_plan
  before insert or update on public.profiles
  for each row execute function app_private.guard_profile_plan();

-- Check: every account and its plan.
select plan, count(*) as accounts
from public.profiles
group by plan
order by plan;

-- -----------------------------------------------------------------------------
-- To make test accounts Plus, run this separately with your own addresses
-- (kept out of this file on purpose — the repository is public):
--
--   update public.profiles
--   set plan = 'plus', plan_source = 'test', plan_expires_at = null
--   where id in (select id from auth.users where email in ('...', '...'));
--
-- And back to free:
--
--   update public.profiles
--   set plan = 'free', plan_source = null, plan_expires_at = null
--   where id in (select id from auth.users where email = '...');
-- -----------------------------------------------------------------------------

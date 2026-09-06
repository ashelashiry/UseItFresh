-- =============================================================================
-- UseItFresh — migration 4: the urgency / status engine  (backlog item I3)
--
-- Implements spec §10 (the 9 user-facing statuses) under the §5 food-safety
-- rules, which are mandatory and outrank convenience.
--
-- THREE DESIGN DECISIONS, and why:
--
-- 1. Server-side, not in the client.
--    Inventory lists sort by urgency, so the status must exist where the
--    sorting happens. It is also safety logic: a modified client must not be
--    able to talk itself into "fresh".
--
-- 2. A VIEW, not a stored column.
--    Status depends on TODAY. "Use by tomorrow" becomes "use today" overnight
--    with no write. A stored column would need a nightly job and would be
--    wrong between runs; a view is correct the instant it is read.
--
-- 3. Rules as DATA, in food_care_guides.
--    Shelf lives are a curation problem, not a code problem. Editing a number
--    in a row must not require a migration.
--
-- The view NEVER claims certainty. It returns the evidence it used
-- (status_basis) and whether anything was assumed (has_unknowns) so the UI can
-- say so, per §5.4 and §5.9.
--
-- Safe to re-run. Run in: Supabase dashboard -> SQL Editor -> paste -> Run.
-- =============================================================================

-- 1. Numeric rules alongside the human-readable guidance -----------------------

alter table public.food_care_guides
  add column if not exists opened_days        integer,
  add column if not exists default_shelf_days integer,
  add column if not exists use_soon_days      integer;

comment on column public.food_care_guides.opened_days is
  'Days of life remaining AFTER opening. The conservative cap from §5.3 — it '
  'overrides a later printed date, because opening restarts the clock.';
comment on column public.food_care_guides.default_shelf_days is
  'Fallback shelf life when there is no printed date. An ESTIMATE (§5.2), '
  'never presented as a manufacturer date.';
comment on column public.food_care_guides.use_soon_days is
  'How many days ahead of expiry this category starts nagging. Tighter for '
  'high-risk food.';

update public.food_care_guides set
  opened_days        = v.opened_days,
  default_shelf_days = v.default_shelf_days,
  use_soon_days      = v.use_soon_days
from (values
  -- category,            opened, shelf, use_soon
  ('dairy',                  3,     7,     2),
  ('meat_poultry',           1,     2,     1),   -- §5.3 high risk
  ('seafood',                1,     2,     1),   -- §5.3 high risk
  ('eggs',                   7,    28,     3),
  ('cooked_leftovers',       2,     3,     1),   -- §5.3 cooked rice/pasta
  ('fruit',                  3,     7,     2),
  ('vegetables',             3,     7,     2),
  ('bread_bakery',           3,     4,     2),
  ('pantry_dry',            90,   180,     7),
  ('frozen',                30,   180,     7),
  ('condiments_sauces',     60,   180,     7),
  ('infant_food',            1,     2,     1)    -- §5.7 strictest, no extension
) as v(category, opened_days, default_shelf_days, use_soon_days)
where public.food_care_guides.category = v.category;


-- 2. The rule engine ----------------------------------------------------------
--
-- Returns the §10 status plus the evidence behind it. Deliberately pure and
-- deterministic: same inputs, same answer, no hidden state.

create or replace function app_private.food_status(
  p_status              text,
  p_printed_date        date,
  p_printed_date_type   text,
  p_opened_at           timestamptz,
  p_frozen_at           timestamptz,
  p_estimated_expiry_at timestamptz,
  p_created_at          timestamptz,
  p_location_type       text,
  p_is_high_risk        boolean,
  p_opened_days         integer,
  p_default_shelf_days  integer,
  p_use_soon_days       integer
)
returns table (
  status        text,
  urgency_rank  smallint,
  days_left     integer,
  status_basis  text,
  has_unknowns  boolean
)
language plpgsql
immutable
as $$
declare
  v_today        date := current_date;
  v_opened_limit date;
  v_effective    date;
  v_basis        text;
  v_unknown      boolean := false;
  v_soon         integer := coalesce(p_use_soon_days, 2);
  v_days         integer;
begin
  -- (a) Terminal states the user set by hand. Never recomputed.
  if p_status in ('consumed', 'discarded') then
    return query select p_status,
      (case p_status when 'consumed' then 7 else 8 end)::smallint,
      null::integer, 'set by you'::text, false;
    return;
  end if;

  -- (b) Frozen stops the clock (§5). Either explicitly, or by living in a freezer.
  if p_frozen_at is not null or p_location_type = 'freezer' then
    return query select 'frozen'::text, 5::smallint, null::integer,
      (case when p_frozen_at is not null then 'frozen on a date you set'
            else 'kept in a freezer' end)::text,
      false;
    return;
  end if;

  -- (c) Opening restarts the clock, and can only ever SHORTEN life (§5.3).
  if p_opened_at is not null and p_opened_days is not null then
    v_opened_limit := (p_opened_at at time zone 'UTC')::date + p_opened_days;
  end if;

  -- (d) Pick the binding date: the EARLIEST credible limit wins.
  if p_printed_date is not null then
    v_effective := p_printed_date;
    v_basis     := 'the printed ' || coalesce(replace(p_printed_date_type, '_', '-'), 'date');
  end if;

  if v_opened_limit is not null
     and (v_effective is null or v_opened_limit < v_effective) then
    v_effective := v_opened_limit;
    v_basis     := 'when you opened it';
  end if;

  if v_effective is null and p_estimated_expiry_at is not null then
    v_effective := (p_estimated_expiry_at at time zone 'UTC')::date;
    v_basis     := 'an estimate, not a printed date';
    v_unknown   := true;
  end if;

  -- (e) Nothing to go on but the category's typical shelf life. Estimate, and
  --     say so (§5.2, §5.4) rather than inventing confidence.
  if v_effective is null and p_default_shelf_days is not null then
    v_effective := (p_created_at at time zone 'UTC')::date + p_default_shelf_days;
    v_basis     := 'a typical shelf life for this category — no date recorded';
    v_unknown   := true;
  end if;

  if v_effective is null then
    return query select 'unknown'::text, 6::smallint, null::integer,
      'no date recorded'::text, true;
    return;
  end if;

  v_days := v_effective - v_today;

  -- (f) High-risk food gets the tighter of its own threshold and 1 day (§5.3).
  if coalesce(p_is_high_risk, false) then
    v_soon := least(v_soon, 2);
  end if;

  -- (g) Past the limit. WHICH kind of limit decides safety vs quality (§5.2).
  if v_days < 0 then
    -- An expired OPENED window is a safety matter regardless of the printed
    -- date type: the food has been exposed, and for high-risk items we do not
    -- soften that. §5.3, and §5.7 for infant food.
    if v_basis = 'when you opened it' and coalesce(p_is_high_risk, false) then
      return query select 'past_use_by'::text, 0::smallint, v_days,
        ('open too long — ' || v_basis)::text, v_unknown;
      return;
    end if;

    if p_printed_date_type = 'use_by' then
      return query select 'past_use_by'::text, 0::smallint, v_days,
        ('past ' || v_basis)::text, v_unknown;
      return;
    end if;

    if p_printed_date_type in ('best_before', 'sell_by') then
      return query select 'past_best_before'::text, 2::smallint, v_days,
        ('past ' || v_basis || ' — quality, not safety')::text, v_unknown;
      return;
    end if;

    -- Unknown date type, or a purely estimated window: do not guess that it is
    -- merely a quality issue. Flag it as unknown and let the user decide (§5.4).
    return query select 'unknown'::text, 6::smallint, v_days,
      ('past ' || v_basis || ', but the kind of date was not recorded')::text,
      true;
    return;
  end if;

  -- (h) Still in date.
  if v_days = 0 then
    return query select 'use_today'::text, 1::smallint, v_days,
      ('today is the limit — ' || v_basis)::text, v_unknown;
  elsif v_days <= v_soon then
    return query select 'use_soon'::text, 3::smallint, v_days,
      ('based on ' || v_basis)::text, v_unknown;
  else
    return query select 'fresh'::text, 4::smallint, v_days,
      ('based on ' || v_basis)::text, v_unknown;
  end if;
end;
$$;

revoke all on function app_private.food_status(
  text, date, text, timestamptz, timestamptz, timestamptz, timestamptz,
  text, boolean, integer, integer, integer) from public;
grant execute on function app_private.food_status(
  text, date, text, timestamptz, timestamptz, timestamptz, timestamptz,
  text, boolean, integer, integer, integer) to authenticated;


-- 3. The view the app actually reads ------------------------------------------
--
-- security_invoker = true is essential: without it the view would run as its
-- owner and bypass every RLS policy on food_items. With it, the existing
-- household scoping applies unchanged.

drop view if exists public.food_items_status;

create view public.food_items_status
with (security_invoker = true)
as
select
  f.*,
  loc.name          as location_name,
  loc.location_type as location_type,
  g.display_name    as category_display_name,
  g.is_high_risk    as is_high_risk,
  g.storage_tips    as storage_tips,
  g.safety_notes    as safety_notes,
  s.status          as computed_status,
  s.urgency_rank    as urgency_rank,
  s.days_left       as days_left,
  s.status_basis    as status_basis,
  s.has_unknowns    as has_unknowns
from public.food_items f
left join public.storage_locations loc on loc.id = f.storage_location_id
left join public.food_care_guides  g   on g.category = f.category
cross join lateral app_private.food_status(
  f.status, f.printed_date, f.printed_date_type, f.opened_at, f.frozen_at,
  f.estimated_expiry_at, f.created_at, loc.location_type,
  g.is_high_risk, g.opened_days, g.default_shelf_days, g.use_soon_days
) s
where f.archived_at is null;

comment on view public.food_items_status is
  'food_items with the §10 status computed live against today''s date. Sort by '
  'urgency_rank ASC for "use first". status_basis and has_unknowns exist so the '
  'UI can show WHY, and admit what it does not know (§5.4, §5.9).';

grant select on public.food_items_status to authenticated;


-- 4. Verification -------------------------------------------------------------
--
--   select name, computed_status, days_left, status_basis, has_unknowns
--   from public.food_items_status
--   order by urgency_rank, days_left nulls last;
--
-- urgency_rank: 0 past-use-by · 1 use-today · 2 past-best-before · 3 use-soon
--               4 fresh · 5 frozen · 6 unknown · 7 consumed · 8 discarded
--
-- NOTE: run this from the SQL Editor and you will see every household's rows,
-- because the editor connects as a superuser. From the app, RLS applies.
-- =============================================================================

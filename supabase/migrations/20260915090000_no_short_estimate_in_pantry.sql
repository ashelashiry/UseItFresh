-- =============================================================================
-- Migration 9 - no invented one-day estimate for food kept in the pantry.
--
-- Hybrid design review, 15 Sep (P0): canned tuna in the Pantry showed
-- "1 day left" under Seafood. With no printed date, the engine fell back to the
-- category's typical shelf life (seafood: 2 days), right for fresh fish in a
-- fridge and wrong for a sealed can in a cupboard. The brief: do not substitute
-- a new guessed duration; when information is missing, show uncertainty.
--
-- The only change to app_private.food_status (copied from migration 3, the
-- urgency engine): step (e) skips the category estimate for a food kept in the
-- pantry whose category's typical shelf life is two weeks or less. Such food
-- shows "no date recorded" until a date is added. Printed dates, opened dates,
-- frozen food and everything in a fridge are untouched.
--
-- Safe to run more than once. Run it all in the Supabase SQL editor. The last
-- query should return one row with 'unknown'.
-- =============================================================================

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
  --     Except a short-lived category kept in the pantry (15 Sep): that is
  --     almost always a can, jar or packet the estimate does not describe, so
  --     say the date is not recorded rather than inventing one.
  if v_effective is null and p_default_shelf_days is not null
     and not (p_location_type = 'pantry' and p_default_shelf_days <= 14) then
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

-- Check: seafood with no date, kept in the pantry -> unknown (expect 'unknown')
select status from app_private.food_status(
  'fresh', null, null, null, null, null, now(), 'pantry', true, 1, 2, 1);

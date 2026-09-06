-- =============================================================================
-- UseItFresh — migration 5: human labels for the §10 statuses
--
-- Migration 4 returns machine values ('past_use_by'). The UI needs a label and
-- an icon, and spec §10 is explicit: "Do not rely on colour alone. Always
-- include text and an icon."
--
-- These live in SQL rather than the client for one practical reason: mapping 9
-- statuses to labels per row would be nine nested conditionals in the DSL, in
-- every list that shows an item. One expression here, every screen benefits.
--
-- Only replaces the view. No data change. Safe to re-run.
-- =============================================================================

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
  s.has_unknowns    as has_unknowns,

  -- Wording matters here. "Past use-by" is a disposal instruction; "past best
  -- before" is an invitation to look at it. §5.2 turns on that difference, so
  -- the labels must not blur it.
  case s.status
    when 'fresh'            then 'Fresh'
    when 'use_soon'         then 'Use soon'
    when 'use_today'        then 'Use today'
    when 'past_best_before' then 'Past best before'
    when 'past_use_by'      then 'Past use-by'
    when 'frozen'           then 'Frozen'
    when 'consumed'         then 'Used'
    when 'discarded'        then 'Thrown out'
    else 'Not sure'
  end as status_label,

  -- Material icon names, so the status is never carried by colour alone (§10).
  case s.status
    when 'fresh'            then 'check_circle_outline'
    when 'use_soon'         then 'schedule'
    when 'use_today'        then 'priority_high'
    when 'past_best_before' then 'help_outline'
    when 'past_use_by'      then 'dangerous'
    when 'frozen'           then 'ac_unit'
    when 'consumed'         then 'done_all'
    when 'discarded'        then 'delete_outline'
    else 'help_outline'
  end as status_icon,

  -- A plain-English line for the row, so the list explains itself without the
  -- user opening anything. Days are spelled out rather than shown as a number
  -- next to a colour.
  case
    when s.status = 'past_use_by'      then 'Throw this out'
    when s.status = 'past_best_before' then 'Check it before using'
    when s.status = 'use_today'        then 'Use it today'
    when s.status = 'frozen'           then 'Frozen — clock stopped'
    when s.status = 'consumed'         then 'Used'
    when s.status = 'discarded'        then 'Thrown out'
    when s.status = 'unknown'          then 'No date recorded'
    when s.days_left = 1               then '1 day left'
    when s.days_left > 1               then s.days_left || ' days left'
    else 'Check it'
  end as status_detail

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
  'food_items with the §10 status computed live against today''s date, plus a '
  'label, icon and plain-English detail line. Sort by urgency_rank ASC for '
  '"use first". status_basis and has_unknowns exist so the UI can show WHY, and '
  'admit what it does not know (§5.4, §5.9).';

grant select on public.food_items_status to authenticated;

-- Check:
--   select name, status_label, status_detail, status_icon, status_basis
--   from public.food_items_status order by urgency_rank, days_left nulls last;
-- =============================================================================

-- Run this once in the SQL Editor.
-- Fixes a real gap: is_leader_of() required a national admin's own
-- home chapter to match the chapter being acted on, which defeats
-- the point of "national admin manages every chapter." A plain
-- 'leader' still needs an exact chapter match; a national_admin now
-- passes for any chapter. This one function is used by most of the
-- write policies (meetings, motions, floor_log, profiles), so fixing
-- it here fixes all of them at once.

create or replace function is_leader_of(target_chapter uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from profiles
    where id = auth.uid()
      and role in ('leader', 'national_admin')
      and (chapter_id = target_chapter or role = 'national_admin')
  )
$$;

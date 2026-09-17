-- Run this once (or let it auto-push via the CLI).
--
-- Real finding while building this: PostgreSQL requires a row to be
-- visible under a SELECT policy before it can be targeted by DELETE
-- (it has to "see" the row to identify it). Since shortlist_votes
-- rows are deliberately unreadable by anyone but the voter — that's
-- what makes the ballot genuinely private — no DELETE policy can ever
-- let a leader remove someone else's vote; the two goals conflict at
-- the RLS level, not because of anything wrong with the policy text.
--
-- The fix: a security-definer function is the standard way to allow
-- a narrow, audited exception. It runs with elevated privilege
-- internally, but only after checking the caller is actually a
-- leader/national admin of the motion's chapter — the authorization
-- check still happens, it just isn't expressed as a bare RLS policy.

drop policy if exists "shortlist_votes_leader_delete" on shortlist_votes;

create or replace function reset_shortlist_votes(target_motion uuid) returns int
language plpgsql security definer set search_path = public as $$
declare
  target_chapter uuid;
  affected int;
begin
  select chapter_id into target_chapter from motions where id = target_motion;
  if target_chapter is null then
    raise exception 'Motion not found';
  end if;
  if not is_leader_of(target_chapter) then
    raise exception 'Not authorized to reset votes for this motion';
  end if;
  delete from shortlist_votes where motion_id = target_motion;
  get diagnostics affected = row_count;
  return affected;
end;
$$;

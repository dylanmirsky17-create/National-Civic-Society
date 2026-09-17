-- Run this once (or let it auto-push via the CLI).
-- Lets a chapter's leader/national admin clear the shortlist votes on
-- a motion once voting is done and they're ready to start a fresh
-- round. Individual vote rows were previously only touchable by the
-- voter themselves (by design, for privacy) — this adds a narrow
-- delete-only exception scoped to motions in a chapter they run.

create policy "shortlist_votes_leader_delete" on shortlist_votes for delete
  using (exists(
    select 1 from motions m where m.id = motion_id and is_leader_of(m.chapter_id)
  ));

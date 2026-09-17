-- Run this once (or let it auto-push via the CLI).
--
-- Real bug fix: `shortlist_votes_own` was written as a single "FOR ALL"
-- policy. Combined with the separate leader-delete policy, Postgres's
-- query plan for DELETE came out as `(own OR leader) AND own` — which
-- is mathematically identical to just `own`, silently cancelling out
-- the leader policy entirely. A leader could never actually reset
-- another member's vote no matter what the leader policy said.
--
-- Splitting the "for all" policy into one policy per command removes
-- the ambiguity and lets the leader-delete policy combine correctly.

drop policy if exists "shortlist_votes_own" on shortlist_votes;

create policy "shortlist_votes_own_select" on shortlist_votes for select
  using (voter_id = auth.uid());
create policy "shortlist_votes_own_insert" on shortlist_votes for insert
  with check (voter_id = auth.uid());
create policy "shortlist_votes_own_update" on shortlist_votes for update
  using (voter_id = auth.uid())
  with check (voter_id = auth.uid());
create policy "shortlist_votes_own_delete" on shortlist_votes for delete
  using (voter_id = auth.uid());

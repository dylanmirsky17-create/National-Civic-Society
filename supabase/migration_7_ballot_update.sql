-- Run this once in the SQL Editor.
-- Lets a member change their own live-ballot vote before the stage
-- closes (e.g. tapped "For" then meant "Against"). Without this,
-- only the first vote per stage would ever be allowed to save —
-- casting it again would silently fail.

create policy "ballots_own_update" on ballots for update
  using (voter_id = auth.uid())
  with check (voter_id = auth.uid());

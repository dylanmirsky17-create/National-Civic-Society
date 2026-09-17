-- Run this once in the SQL Editor.
-- Lets a chapter's leader delete one of their own meetings (e.g. to
-- cancel one, or to clean up duplicates). There was no delete policy
-- at all before this, so it silently wasn't possible.

create policy "meetings_leader_delete" on meetings for delete
  using (is_leader_of(chapter_id));

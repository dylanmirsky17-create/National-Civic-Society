-- Run this once (or let it auto-push via the CLI).
--
-- Builds out the real topic lifecycle: submissions open/close,
-- shortlist voting open/close, an announce date for when the
-- shortlisted topics go public, and a chapter-wide switch to turn
-- member voting off entirely (leader picks the topic directly some
-- cycles). Also lets a leader delete a submitted topic outright.

alter table chapters add column sub_open timestamptz;
alter table chapters add column vote_open timestamptz;
alter table chapters add column shortlist_announce_at timestamptz;
alter table chapters add column voting_enabled boolean not null default true;

create policy "motions_leader_delete" on motions for delete
  using (is_leader_of(chapter_id));

-- Reports were failing RLS when a member's chapter changed server-side
-- (e.g. their chapter request got approved) while their browser tab
-- was still open with the old chapter_id cached. The client would
-- then insert a stale chapter_id that no longer matched what
-- my_chapter() computes live, tripping the reports_member_insert
-- check. Defaulting the column to my_chapter() means the database
-- fills it in itself at insert time, always current, so the client
-- no longer needs to (or should) supply it at all.
alter table reports alter column chapter_id set default my_chapter();

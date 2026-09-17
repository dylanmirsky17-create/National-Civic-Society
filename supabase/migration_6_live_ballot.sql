-- Run this once in the SQL Editor.
-- Adds the control the chair uses to open/close the live "before /
-- after" opinion ballot during a meeting. Null = no voting open right
-- now. The `ballots` table and `meeting_ballot_results` view that
-- store and count the actual votes already exist from schema.sql.

alter table meetings add column voting_stage text check (voting_stage in ('before', 'after'));

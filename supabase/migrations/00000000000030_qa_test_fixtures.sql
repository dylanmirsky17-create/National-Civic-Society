-- Temporary QA fixtures for a manual regression pass. Cleaned up by
-- 00000000000031_qa_test_cleanup.sql at the end of the same session.
insert into chapters (name, location, status, is_placeholder, sub_open, sub_close, vote_open, vote_close, voting_enabled, shortlist_announce_at)
values ('QA Test Chapter (closed)', 'Test City, TS', 'founding', false,
  now() - interval '30 days', now() - interval '1 day',
  now() - interval '20 days', now() - interval '1 day',
  true, now() - interval '20 days');

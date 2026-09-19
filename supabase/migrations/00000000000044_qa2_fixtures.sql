-- Second, broader QA regression pass: chapters covering every window
-- state (open, not-yet-open, closed, voting-off), plus multiple
-- members for concurrency/duplicate-vote testing. Cleaned up at the
-- end of the same session.
insert into chapters (name, location, status, is_placeholder, sub_open, sub_close, vote_open, vote_close, voting_enabled, shortlist_announce_at)
values
  ('QA2 Open Chapter', 'Test City, TS', 'founding', false,
    now() - interval '10 days', now() + interval '10 days',
    now() - interval '5 days', now() + interval '10 days',
    true, now() - interval '5 days'),
  ('QA2 NotYetOpen Chapter', 'Test City, TS', 'founding', false,
    now() + interval '5 days', now() + interval '20 days',
    now() + interval '5 days', now() + interval '20 days',
    true, now() + interval '5 days'),
  ('QA2 Closed Chapter', 'Test City, TS', 'founding', false,
    now() - interval '30 days', now() - interval '1 day',
    now() - interval '20 days', now() - interval '1 day',
    true, now() - interval '20 days'),
  ('QA2 VotingOff Chapter', 'Test City, TS', 'founding', false,
    now() - interval '10 days', now() + interval '10 days',
    now() - interval '5 days', now() + interval '10 days',
    false, now() - interval '5 days');

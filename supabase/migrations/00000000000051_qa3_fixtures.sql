-- Third QA regression pass: one normal open chapter with real
-- coordinates (to check the Chapters map pin), used for pool
-- edit/unshortlist/remove, archive, and sign-out coverage.
insert into chapters (name, location, status, is_placeholder, lat, lng, sub_open, sub_close, vote_open, vote_close, voting_enabled, shortlist_announce_at)
values ('QA3 Chapter', 'Portland, OR', 'founding', false, 45.5152, -122.6784,
  now() - interval '10 days', now() + interval '10 days',
  now() - interval '5 days', now() + interval '10 days',
  true, now() - interval '5 days');

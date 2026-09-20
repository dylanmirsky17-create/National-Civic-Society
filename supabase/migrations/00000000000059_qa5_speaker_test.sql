insert into chapters (name, location, status, is_placeholder, sub_open, sub_close, vote_open, vote_close, voting_enabled)
values ('QA5 Speaker Test Chapter', 'Test City, TS', 'founding', false,
  now() - interval '5 days', now() + interval '10 days',
  now() - interval '5 days', now() + interval '10 days', true);

insert into meetings (chapter_id, scheduled_at)
select id, now() + interval '5 days' from chapters where name = 'QA5 Speaker Test Chapter';

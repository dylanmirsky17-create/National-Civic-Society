insert into chapters (name, location, status, is_placeholder, sub_open, sub_close, vote_open, vote_close, voting_enabled)
values ('QA9 Full Regression Chapter', 'Test City, TS', 'founding', false,
  now() - interval '5 days', now() + interval '20 days',
  now() - interval '5 days', now() + interval '20 days', true);

insert into meetings (chapter_id, scheduled_at)
select id, now() + interval '5 days' from chapters where name = 'QA9 Full Regression Chapter';
insert into meetings (chapter_id, scheduled_at)
select id, now() + interval '19 days' from chapters where name = 'QA9 Full Regression Chapter';

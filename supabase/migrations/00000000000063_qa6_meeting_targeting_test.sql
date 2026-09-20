insert into chapters (name, location, status, is_placeholder, sub_open, sub_close, vote_open, vote_close, voting_enabled)
values ('QA6 Meeting Target Chapter', 'Test City, TS', 'founding', false,
  now() - interval '5 days', now() + interval '30 days',
  now() - interval '5 days', now() + interval '30 days', true);

insert into meetings (chapter_id, scheduled_at)
select id, now() + interval '5 days' from chapters where name = 'QA6 Meeting Target Chapter';
insert into meetings (chapter_id, scheduled_at)
select id, now() + interval '19 days' from chapters where name = 'QA6 Meeting Target Chapter';
insert into meetings (chapter_id, scheduled_at)
select id, now() + interval '33 days' from chapters where name = 'QA6 Meeting Target Chapter';

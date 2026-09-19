insert into meetings (chapter_id, scheduled_at)
select id, now() + interval '5 days' from chapters where name = 'QA2 Open Chapter';

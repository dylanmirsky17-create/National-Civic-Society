update auth.users set email_confirmed_at = now() where email = 'qa2-chapreq-reject@testschool.org' and email_confirmed_at is null;
update profiles set chapter_id = (select id from chapters where is_placeholder = true)
  where id in (select id from auth.users where email = 'qa2-chapreq-reject@testschool.org');
insert into chapter_requests (school_name, requested_by_name, requested_by_email, location, status)
values ('QA2 Reject Test School', 'QA2 Reject Test', 'qa2-chapreq-reject@testschool.org', 'Test City, TS', 'pending');

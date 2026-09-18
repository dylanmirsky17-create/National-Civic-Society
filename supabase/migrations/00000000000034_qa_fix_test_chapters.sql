-- Fix QA test accounts' chapter_id (a raw-curl signup in testing sent
-- metadata in the wrong shape, so the handle_new_user trigger never
-- set it — unrelated to any real app bug).
update profiles set chapter_id = (select id from chapters where name = 'Seattle Academy')
where id in (select id from auth.users where email in ('qa-member@testschool.org','qa-leader@testschool.org','qa-natadmin@testschool.org'));

update profiles set chapter_id = (select id from chapters where name = 'QA Test Chapter (closed)')
where id in (select id from auth.users where email = 'qa-member-closed@testschool.org');

-- Confirm QA test accounts (so they can sign in without a real
-- inbox) and assign the roles needed to exercise leader/admin pages.
update auth.users set email_confirmed_at = now()
where email in ('qa-member@testschool.org','qa-member-closed@testschool.org','qa-leader@testschool.org','qa-natadmin@testschool.org')
  and email_confirmed_at is null;

update profiles set role = 'leader' where id in (select id from auth.users where email = 'qa-leader@testschool.org');
update profiles set role = 'national_admin' where id in (select id from auth.users where email = 'qa-natadmin@testschool.org');

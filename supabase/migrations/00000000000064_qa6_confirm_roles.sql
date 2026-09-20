update auth.users set email_confirmed_at = now() where email in ('qa6-member@testschool.org','qa6-leader@testschool.org') and email_confirmed_at is null;
update profiles set role = 'leader' where id in (select id from auth.users where email = 'qa6-leader@testschool.org');

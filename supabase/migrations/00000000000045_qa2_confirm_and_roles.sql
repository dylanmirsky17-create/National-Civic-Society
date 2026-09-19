update auth.users set email_confirmed_at = now()
where email like 'qa2-%@testschool.org' and email_confirmed_at is null;

update profiles set role = 'leader' where id in (select id from auth.users where email = 'qa2-leader@testschool.org');
update profiles set role = 'national_admin' where id in (select id from auth.users where email = 'qa2-natadmin@testschool.org');

update auth.users set email_confirmed_at = now()
where email like 'qa3-%@testschool.org' and email_confirmed_at is null;
update profiles set role = 'leader' where id in (select id from auth.users where email = 'qa3-leader@testschool.org');

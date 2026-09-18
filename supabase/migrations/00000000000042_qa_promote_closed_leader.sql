update profiles set role='leader' where id in (select id from auth.users where email='qa-member-closed@testschool.org');

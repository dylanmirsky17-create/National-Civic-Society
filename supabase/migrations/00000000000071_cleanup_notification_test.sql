delete from reports where id = '00000000-0000-0000-0000-000000000001';
delete from chapter_requests where school_name = 'Live Check High School';
delete from auth.users where email like 'live-check-%@testschool.org';

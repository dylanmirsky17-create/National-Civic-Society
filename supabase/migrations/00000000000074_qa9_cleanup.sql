delete from reports where body like 'QA9 regression report%';
delete from auth.users where email like 'qa9-%@testschool.org';
delete from chapters where name = 'QA9 Full Regression Chapter';

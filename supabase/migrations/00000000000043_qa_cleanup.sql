-- Remove all QA regression-test fixtures created for a manual full-
-- site pass: test accounts, their data, and the temporary closed-
-- window test chapter. Cascades clean up profiles/motions/reports/
-- shortlist_votes tied to these users automatically.
delete from auth.users where email in (
  'qa-member@testschool.org',
  'qa-member-closed@testschool.org',
  'qa-leader@testschool.org',
  'qa-natadmin@testschool.org'
);
delete from auth.users where email like 'qa-chapreq-%@testschool.org';

delete from chapters where name = 'QA Test Chapter (closed)';
delete from chapters where name = 'QA Regression High School';

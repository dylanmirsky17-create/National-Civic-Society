-- Third QA regression pass cleanup: test accounts, the QA3 test
-- chapter (cascades its motions/reports), and any stray
-- chapter_requests/reports left from this pass.
delete from reports where body like 'regression check 3 report%';
delete from auth.users where email like 'qa3-%@testschool.org';
delete from chapters where name = 'QA3 Chapter';
delete from chapter_requests where school_name = 'QA3 Regression School';

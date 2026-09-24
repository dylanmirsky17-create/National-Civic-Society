-- Leftover chapter_requests rows from earlier QA passes that were
-- never cleaned up (chapter_requests has no FK to auth.users, so
-- deleting the test accounts never cascaded these away), plus this
-- session's own live end-to-end verification row. Leaves the
-- historical Seattle Academy request alone since that predates any
-- QA testing and isn't mine to remove.
delete from chapter_requests where school_name in (
  'QA2 Reject Test School',
  'QA Regression High School',
  'Live Check High School'
);
delete from auth.users where email like 'live-check-%@testschool.org';

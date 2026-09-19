-- Full cleanup for the second (deeper) QA regression pass, plus
-- stray test reports that leaked into the real Seattle Academy
-- chapter's inbox across both passes (reports have no reporter link
-- to cascade away when the test accounts are deleted, by design —
-- true anonymity — so they need removing explicitly, by exact body
-- text match).
delete from reports where body in (
  'return=minimal diagnostic test',
  'QA regression test report — please ignore, safe to delete.',
  'post-chapter-switch report test'
);

delete from auth.users where email like 'qa2-%@testschool.org';

delete from chapters where name in (
  'QA2 Open Chapter',
  'QA2 NotYetOpen Chapter',
  'QA2 Closed Chapter',
  'QA2 VotingOff Chapter'
);

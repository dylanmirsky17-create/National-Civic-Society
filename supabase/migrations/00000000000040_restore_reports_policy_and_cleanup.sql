-- Restore the real insert check (00000000000038 temporarily set this
-- to `true` for diagnosis) and drop the diagnostic functions created
-- while chasing what turned out to be a red herring: the RLS error
-- only reproduced when the test harness requested the row back via
-- Prefer: return=representation, which also requires the SELECT
-- policy — and reports intentionally has no member-read policy, by
-- design, for real anonymity. The actual app never requests the row
-- back, so it was never affected by that specific path.
drop policy if exists "reports_member_insert" on reports;
create policy "reports_member_insert" on reports for insert
  with check (chapter_id = my_chapter());

drop function if exists diag_my_chapter();
drop function if exists diag_try_insert();
drop function if exists diag_check_expr();
drop function if exists diag_explain();

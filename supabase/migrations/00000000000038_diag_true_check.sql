drop policy if exists "reports_member_insert" on reports;
create policy "reports_member_insert" on reports for insert
  with check (true);

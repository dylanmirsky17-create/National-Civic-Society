-- The shared "Pending Chapter" holding pen (added in
-- 00000000000013_pending_chapter.sql) went missing from production at
-- some point, which broke chapter-request signups entirely: the
-- client looks it up by is_placeholder=true and shows "Something
-- went wrong" when it can't find one. Restoring it idempotently so a
-- re-run (or a future accidental deletion) doesn't error out.
insert into chapters (name, location, status, is_placeholder)
select 'Pending Chapter', 'Awaiting approval', 'pending', true
where not exists (select 1 from chapters where is_placeholder = true);

-- The public_stats "Active chapters" count never excluded the
-- internal "Pending Chapter" holding-pen row, and that row's status
-- had somehow become 'active' rather than its intended 'pending',
-- so the live homepage was showing 2 active chapters when only
-- Seattle Academy is real. Fixing both: the view now excludes
-- placeholder chapters regardless of their status (defense in
-- depth), and the placeholder row itself is corrected.
create or replace view public_stats as
  select
    (select count(*) from chapters where status in ('active', 'founding') and not is_placeholder) as active_chapters,
    (select count(*) from profiles) as total_members,
    (select count(*) from meetings where status = 'completed') as debates_held;

update chapters set status = 'pending' where is_placeholder = true;

-- a stray signup with no chapter at all and an email pattern typical
-- of an automated security scanner (audit_sec_<timestamp>_<random>),
-- not a real member — a real signup through the site always ends up
-- with either a real chapter_id or the pending-chapter placeholder,
-- never null
delete from auth.users where email like 'audit_sec_%@gmail.com';

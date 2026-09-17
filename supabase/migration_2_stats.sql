-- Run this once in the SQL Editor if you already ran schema.sql before
-- this file existed. (It's now folded into schema.sql for fresh installs.)

create view public_stats as
  select
    (select count(*) from chapters where status in ('active', 'founding')) as active_chapters,
    (select count(*) from profiles) as total_members,
    (select count(*) from meetings where status = 'completed') as debates_held;

grant select on public_stats to authenticated, anon;

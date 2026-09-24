do $$
declare cid uuid;
begin
  select id into cid from chapters where name = 'Seattle Academy';
  insert into reports (id, chapter_id, category, body) values
    ('00000000-0000-0000-0000-000000000001', cid, 'Other', 'Temporary test report to verify email notification delivery. Safe to ignore/delete.');
end $$;

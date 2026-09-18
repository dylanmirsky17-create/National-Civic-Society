create or replace function diag_explain() returns text
language plpgsql security invoker as $$
declare
  rec record;
  out text := '';
begin
  for rec in execute 'explain (verbose, costs off) insert into reports(category, body) values (''other'',''x'')' loop
    out := out || rec."QUERY PLAN" || E'\n';
  end loop;
  return out;
end $$;
grant execute on function diag_explain() to authenticated;

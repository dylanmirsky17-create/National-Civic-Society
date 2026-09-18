create or replace function diag_check_expr() returns json
language plpgsql security invoker as $$
declare
  eq1 boolean;
  eq2 boolean;
  cnt int;
begin
  eq1 := (my_chapter() = my_chapter());
  eq2 := ('ae6a230f-4e01-4764-80e0-b5d1ec126ebf'::uuid = my_chapter());
  select count(*) into cnt from pg_policies where tablename='reports';
  return json_build_object('eq1', eq1, 'eq2', eq2, 'policy_count_pg_policies', cnt);
end $$;
grant execute on function diag_check_expr() to authenticated;

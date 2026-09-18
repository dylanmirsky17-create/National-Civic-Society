create or replace function diag_try_insert() returns json
language plpgsql as $$
declare
  new_id uuid;
  errm text;
begin
  begin
    insert into reports(category, body) values ('other', 'diag insert') returning id into new_id;
  exception when others then
    errm := SQLERRM;
  end;
  return json_build_object(
    'role', current_setting('role', true),
    'jwt_role', current_setting('request.jwt.claim.role', true),
    'uid', auth.uid(),
    'my_chapter', my_chapter(),
    'inserted_id', new_id,
    'error', errm
  );
end $$;
grant execute on function diag_try_insert() to authenticated;

create or replace function diag_my_chapter() returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'uid', auth.uid(),
    'my_chapter', my_chapter(),
    'profile_chapter_id', (select chapter_id from profiles where id = auth.uid()),
    'profile_exists', exists(select 1 from profiles where id = auth.uid())
  )
$$;
grant execute on function diag_my_chapter() to authenticated;

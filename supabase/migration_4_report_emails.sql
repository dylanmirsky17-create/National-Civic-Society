-- Run this once in the SQL Editor.
-- Adds an email column to `profiles` (denormalized from auth.users)
-- so the report-notification function can look up who to email
-- without needing the admin auth API. This does not affect
-- anonymity: `reports` still has no reporter identity anywhere.

alter table profiles add column email text;
update profiles p set email = u.email from auth.users u where u.id = p.id;

create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, chapter_id, full_name, role, email)
  values (
    new.id,
    nullif(new.raw_user_meta_data->>'chapter_id', '')::uuid,
    coalesce(new.raw_user_meta_data->>'full_name', 'New member'),
    'member',
    new.email
  );
  return new;
end;
$$;

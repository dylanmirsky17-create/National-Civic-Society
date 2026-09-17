-- Run this once (or let it auto-push via the CLI).
--
-- Adds a single shared "holding pen" chapter for anyone who registers
-- from a school with no chapter yet. They get a real account and can
-- log in immediately, but see the example schedule/archive (same as
-- a signed-out guest) until a national admin approves their school
-- from the new in-app "Requests" page, which automatically moves
-- them into the real chapter it creates.

alter table chapters add column is_placeholder boolean not null default false;

insert into chapters (name, location, status, is_placeholder)
values ('Pending Chapter', 'Awaiting approval', 'pending', true);

-- remembers which school a pending member said they were from, so
-- approving that school's request knows exactly who to move
alter table profiles add column pending_school_name text;

-- national admins need to update a request's status once acted on
create policy "chapter_requests_admin_update" on chapter_requests for update
  using (my_role() = 'national_admin');

create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, chapter_id, full_name, role, email, pending_school_name)
  values (
    new.id,
    nullif(new.raw_user_meta_data->>'chapter_id', '')::uuid,
    coalesce(new.raw_user_meta_data->>'full_name', 'New member'),
    'member',
    new.email,
    nullif(new.raw_user_meta_data->>'pending_school_name', '')
  );
  return new;
end;
$$;

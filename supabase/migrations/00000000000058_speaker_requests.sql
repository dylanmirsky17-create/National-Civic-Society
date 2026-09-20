-- Optional, pre-meeting signal that a member wants one of the four
-- main speaking positions (Standing Orders 7.1: "members volunteer
-- and the chair selects"). One row per member per meeting; side is
-- a preference, not an assignment — the chair still picks who
-- actually speaks.
create table speaker_requests (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references meetings(id) on delete cascade,
  member_id uuid not null references profiles(id) on delete cascade,
  side text check (side in ('for','against')),
  created_at timestamptz not null default now(),
  unique (meeting_id, member_id)
);

alter table speaker_requests enable row level security;

create policy "speaker_requests_chapter_read" on speaker_requests for select
  using (exists(select 1 from meetings m where m.id = meeting_id and m.chapter_id = my_chapter()));
create policy "speaker_requests_own_insert" on speaker_requests for insert
  with check (member_id = auth.uid() and exists(select 1 from meetings m where m.id = meeting_id and m.chapter_id = my_chapter()));
create policy "speaker_requests_own_update" on speaker_requests for update
  using (member_id = auth.uid())
  with check (member_id = auth.uid());
create policy "speaker_requests_own_delete" on speaker_requests for delete
  using (member_id = auth.uid());

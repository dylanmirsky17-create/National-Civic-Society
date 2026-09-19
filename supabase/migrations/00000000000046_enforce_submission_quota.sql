-- The "2 of 2 submissions used this cycle" counter was purely
-- cosmetic — nothing stopped a 3rd, 4th, or 100th submission, either
-- client-side or via a direct API call. "This cycle" is scoped to
-- the chapter's current sub_open, so an unpicked submission from a
-- past cycle doesn't permanently lock someone out once a leader
-- opens the next submission window.
create or replace function under_submission_quota(target_chapter uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select (
    select count(*) from motions m, chapters c
    where c.id = target_chapter and m.chapter_id = target_chapter
      and m.submitted_by = auth.uid() and m.shortlisted = false
      and (c.sub_open is null or m.created_at >= c.sub_open)
  ) < 2
$$;

drop policy if exists "motions_member_insert" on motions;
create policy "motions_member_insert" on motions for insert
  with check (
    chapter_id = my_chapter() and submitted_by = auth.uid()
    and (
      is_leader_of(chapter_id)
      or (
        under_submission_quota(chapter_id)
        and exists (
          select 1 from chapters c where c.id = chapter_id
            and (c.sub_open is null or now() >= c.sub_open)
            and (c.sub_close is null or now() <= c.sub_close)
        )
      )
    )
  );

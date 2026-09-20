-- Submissions could never target a specific meeting before — every
-- topic went into one undifferentiated pool, and "set as meeting
-- topic" always assumed the very next meeting. Members can now pick
-- which upcoming meeting a topic is for (even one several weeks
-- out) via motions.meeting_id, which already existed but was only
-- ever set later, by a leader. This just adds a defense-in-depth
-- check that a submitted meeting_id actually belongs to the
-- submitter's own chapter.
drop policy if exists "motions_member_insert" on motions;
create policy "motions_member_insert" on motions for insert
  with check (
    chapter_id = my_chapter() and submitted_by = auth.uid()
    and (meeting_id is null or exists(select 1 from meetings mt where mt.id = meeting_id and mt.chapter_id = chapter_id))
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

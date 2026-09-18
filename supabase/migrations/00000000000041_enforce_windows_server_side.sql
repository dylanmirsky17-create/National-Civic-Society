-- The submission and voting windows (and the voting_enabled
-- off-switch) were only ever checked client-side — the Submit page
-- had no closed-state handling at all, and Vote's check could be
-- bypassed by calling the API directly. Enforcing both server-side
-- as the actual source of truth, matching how every other rule in
-- this schema works.

create or replace function shortlist_voting_open(target_motion uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(c.voting_enabled, true)
    and (c.vote_open is null or now() >= c.vote_open)
    and (c.vote_close is null or now() <= c.vote_close)
  from motions m join chapters c on c.id = m.chapter_id
  where m.id = target_motion
$$;

-- leaders are exempt: they add topics straight to the shortlist (the
-- Operations "external topic" tool) through this same insert path,
-- on their own schedule, not the member submission window.
drop policy if exists "motions_member_insert" on motions;
create policy "motions_member_insert" on motions for insert
  with check (
    chapter_id = my_chapter() and submitted_by = auth.uid()
    and (
      is_leader_of(chapter_id)
      or exists (
        select 1 from chapters c where c.id = chapter_id
          and (c.sub_open is null or now() >= c.sub_open)
          and (c.sub_close is null or now() <= c.sub_close)
      )
    )
  );

drop policy if exists "shortlist_votes_own_insert" on shortlist_votes;
create policy "shortlist_votes_own_insert" on shortlist_votes for insert
  with check (voter_id = auth.uid() and shortlist_voting_open(motion_id));

drop policy if exists "shortlist_votes_own_update" on shortlist_votes;
create policy "shortlist_votes_own_update" on shortlist_votes for update
  using (voter_id = auth.uid())
  with check (voter_id = auth.uid() and shortlist_voting_open(motion_id));

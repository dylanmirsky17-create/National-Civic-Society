-- ============================================================
-- The National Civic Society — database schema + permissions
--
-- Run this once in your Supabase project's SQL Editor
-- (Project -> SQL Editor -> New query -> paste this whole file -> Run).
-- Safe to re-run only if the project is empty; it will error on
-- objects that already exist.
-- ============================================================

create extension if not exists "pgcrypto";

create type user_role as enum ('member', 'leader', 'national_admin');
create type chapter_status as enum ('inquiry', 'pending', 'active', 'founding');

-- ------------------------------------------------------------
-- core tables
-- ------------------------------------------------------------

create table chapters (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text,
  status chapter_status not null default 'inquiry',
  room text default 'TBD',
  meeting_length_min int not null default 32,  -- matches the Standing Orders' 32-minute format (29:30 debate + 2:30 buffer)
  sub_open timestamptz,             -- topic-submission window opens
  sub_close timestamptz,            -- topic-submission deadline for the meeting after that
  vote_open timestamptz,            -- shortlist-vote window opens
  vote_close timestamptz,           -- shortlist-vote deadline for the next topic
  shortlist_announce_at timestamptz, -- when the 3 shortlisted topics go public on Home
  voting_enabled boolean not null default true, -- off = leader picks the topic directly, no member vote
  run_sheet jsonb,                 -- customized meeting formats + which one is active; null = built-in defaults
  is_placeholder boolean not null default false,  -- true only for the shared "Pending Chapter" holding pen
  lat double precision,
  lng double precision,
  created_at timestamptz not null default now()
);

-- one row per person, 1:1 with an auth.users row
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  chapter_id uuid references chapters(id),
  full_name text not null,
  role user_role not null default 'member',
  office text,                     -- e.g. 'President', 'Logger'
  email text,                      -- denormalized from auth.users, used only to notify leaders of new reports
  pending_school_name text,        -- set only while chapter_id points at the placeholder chapter
  floor_log_count int not null default 0,
  member_since timestamptz not null default now()
);

create table meetings (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references chapters(id) on delete cascade,
  scheduled_at timestamptz not null,
  room text,
  motion_id uuid,                  -- the confirmed topic, filled in once shortlisted
  status text not null default 'scheduled',
  voting_stage text check (voting_stage in ('before', 'after')),  -- which live ballot stage the chair has open, if any
  created_at timestamptz not null default now()
);

create table motions (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references chapters(id) on delete cascade,
  submitted_by uuid references profiles(id) on delete set null,
  meeting_id uuid references meetings(id) on delete set null,
  claim text not null,
  rationale text,
  shortlisted boolean not null default false,
  created_at timestamptz not null default now()
);

alter table meetings
  add constraint meetings_motion_fk foreign key (motion_id) references motions(id) on delete set null;

-- vote for which submitted motion becomes the next debate topic
create table shortlist_votes (
  id uuid primary key default gen_random_uuid(),
  motion_id uuid not null references motions(id) on delete cascade,
  voter_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (motion_id, voter_id)
);

-- the in-room "before / after" opinion ballot on the night's motion
create type ballot_stage as enum ('before', 'after');
create type ballot_side as enum ('for', 'against', 'undecided');

create table ballots (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references meetings(id) on delete cascade,
  voter_id uuid not null references profiles(id) on delete cascade,
  stage ballot_stage not null,
  side ballot_side not null,
  created_at timestamptz not null default now(),
  unique (meeting_id, voter_id, stage)
);

create table floor_log (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references meetings(id) on delete cascade,
  member_id uuid not null references profiles(id) on delete cascade,
  side text,
  created_at timestamptz not null default now()
);

-- optional, pre-meeting signal that a member wants one of the four
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

-- anonymous by design: no reporter_id column anywhere on this table
create table reports (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references chapters(id) on delete cascade,
  category text not null,
  body text not null,
  status text not null default 'new',
  created_at timestamptz not null default now()
);

create table chapter_requests (
  id uuid primary key default gen_random_uuid(),
  school_name text not null,
  requested_by_name text,
  requested_by_email text,
  notes text,
  location text,               -- e.g. "Spokane, WA", collected from the requester
  lat double precision,        -- geocoded from `location` at request time, if found
  lng double precision,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- helper functions
-- security definer + a fixed search_path let these look up the
-- caller's own profile without tripping the RLS policies on
-- `profiles` itself (which would otherwise recurse).
-- ------------------------------------------------------------

create or replace function my_role() returns user_role
language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid()
$$;

create or replace function my_chapter() returns uuid
language sql stable security definer set search_path = public as $$
  select chapter_id from profiles where id = auth.uid()
$$;

create or replace function is_leader_of(target_chapter uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from profiles
    where id = auth.uid()
      and chapter_id = target_chapter
      and role in ('leader', 'national_admin')
  )
$$;

-- true when a motion's chapter currently has voting on, and (if set)
-- the vote_open/vote_close window includes now — used to keep
-- shortlist_votes writes from succeeding outside what the Vote page
-- already shows as open
create or replace function shortlist_voting_open(target_motion uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(c.voting_enabled, true)
    and (c.vote_open is null or now() >= c.vote_open)
    and (c.vote_close is null or now() <= c.vote_close)
  from motions m join chapters c on c.id = m.chapter_id
  where m.id = target_motion
$$;

-- caller has fewer than 2 not-yet-shortlisted submissions of their
-- own, made since the chapter's current sub_open — "this cycle" is
-- defined as the current submission window, not lifetime, so an
-- unpicked submission from a past cycle doesn't lock someone out
-- once a leader opens the next one
create or replace function under_submission_quota(target_chapter uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select (
    select count(*) from motions m, chapters c
    where c.id = target_chapter and m.chapter_id = target_chapter
      and m.submitted_by = auth.uid() and m.shortlisted = false
      and (c.sub_open is null or m.created_at >= c.sub_open)
  ) < 2
$$;

-- ------------------------------------------------------------
-- new-user trigger — creates the profile row automatically so the
-- client never has to (and never needs an insert policy for it)
-- ------------------------------------------------------------

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

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ------------------------------------------------------------
-- row level security — this is what actually enforces roles.
-- The client cannot bypass these by editing JS; Postgres checks
-- every request against the signed-in user's own row.
-- ------------------------------------------------------------

alter table chapters enable row level security;
alter table profiles enable row level security;
alter table meetings enable row level security;
alter table motions enable row level security;
alter table shortlist_votes enable row level security;
alter table ballots enable row level security;
alter table floor_log enable row level security;
alter table speaker_requests enable row level security;
alter table reports enable row level security;
alter table chapter_requests enable row level security;

-- chapters: public read (site shows the map/directory to guests);
-- only that chapter's leader (or a national admin) can edit it
create policy "chapters_public_read" on chapters for select using (true);
create policy "chapters_leader_update" on chapters for update
  using (is_leader_of(id) or my_role() = 'national_admin');
create policy "chapters_admin_insert" on chapters for insert
  with check (my_role() = 'national_admin');

-- profiles: you can always read/update your own row; a leader can
-- read (and lightly manage) their own chapter's roster; a national
-- admin can read everyone
create policy "profiles_self_read" on profiles for select
  using (id = auth.uid());
create policy "profiles_chapter_read" on profiles for select
  using (chapter_id = my_chapter() and my_role() in ('leader', 'national_admin'));
create policy "profiles_admin_read_all" on profiles for select
  using (my_role() = 'national_admin');
create policy "profiles_self_update" on profiles for update
  using (id = auth.uid());
create policy "profiles_leader_update_chapter" on profiles for update
  using (is_leader_of(chapter_id));

-- meetings: the schedule is public; only that chapter's leader can write it
create policy "meetings_public_read" on meetings for select using (true);
create policy "meetings_leader_write" on meetings for insert
  with check (is_leader_of(chapter_id));
create policy "meetings_leader_update" on meetings for update
  using (is_leader_of(chapter_id));
create policy "meetings_leader_delete" on meetings for delete
  using (is_leader_of(chapter_id));

-- motions: a member can submit to their own chapter; a chapter's
-- own (unshortlisted) submissions are visible only inside the
-- chapter, but a shortlisted/decided motion becomes public (it
-- needs to show up in the Archive)
create policy "motions_read" on motions for select
  using (shortlisted = true or chapter_id = my_chapter());
-- the submission window was only ever checked client-side (the
-- Submit page's label/gating); a direct API call could submit at any
-- time regardless of the chapter's configured window, so it's
-- enforced here too. Leaders are exempt — they add topics straight
-- to the shortlist (the Operations "external topic" tool) through
-- this same insert path, on their own schedule, not the member
-- submission window.
-- the "2 of 2 submissions used this cycle" counter was display-only
-- — nothing stopped a 3rd, 4th, or 100th submission either
-- client-side or here. under_submission_quota() closes that.
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
create policy "motions_leader_update" on motions for update
  using (is_leader_of(chapter_id));
create policy "motions_leader_delete" on motions for delete
  using (is_leader_of(chapter_id));

-- shortlist_votes / ballots: you can only ever touch your own
-- vote row — nobody, including a chapter's own leaders, can read
-- how any individual person voted. Aggregate counts are exposed
-- separately below, through views that never carry a voter_id.
-- one policy per command, deliberately not "for all": PostgreSQL
-- requires a row to pass a SELECT policy before DELETE/UPDATE can
-- target it, so a single combined policy is the only shape that
-- keeps that requirement from silently swallowing other rules.
create policy "shortlist_votes_own_select" on shortlist_votes for select
  using (voter_id = auth.uid());
-- same defense-in-depth as motions_member_insert above: the voting
-- window and the chapter's voting_enabled off-switch were previously
-- only checked client-side (loadVotePage).
create policy "shortlist_votes_own_insert" on shortlist_votes for insert
  with check (voter_id = auth.uid() and shortlist_voting_open(motion_id));
create policy "shortlist_votes_own_update" on shortlist_votes for update
  using (voter_id = auth.uid())
  with check (voter_id = auth.uid() and shortlist_voting_open(motion_id));
create policy "shortlist_votes_own_delete" on shortlist_votes for delete
  using (voter_id = auth.uid());

-- a leader resetting someone else's vote can never be expressed as a
-- plain DELETE policy (see note above: it would also require SELECT
-- access to that person's individual vote, which defeats the point
-- of a private ballot). reset_shortlist_votes() below is the
-- narrow, audited exception instead.
create or replace function reset_shortlist_votes(target_motion uuid) returns int
language plpgsql security definer set search_path = public as $$
declare
  target_chapter uuid;
  affected int;
begin
  select chapter_id into target_chapter from motions where id = target_motion;
  if target_chapter is null then
    raise exception 'Motion not found';
  end if;
  if not is_leader_of(target_chapter) then
    raise exception 'Not authorized to reset votes for this motion';
  end if;
  delete from shortlist_votes where motion_id = target_motion;
  get diagnostics affected = row_count;
  return affected;
end;
$$;

create policy "ballots_own_insert" on ballots for insert
  with check (voter_id = auth.uid());
create policy "ballots_own_read" on ballots for select
  using (voter_id = auth.uid());
create policy "ballots_own_update" on ballots for update
  using (voter_id = auth.uid())
  with check (voter_id = auth.uid());

-- floor_log: chapter members can read it (it drives speaker
-- eligibility); only that chapter's leader can add entries
create policy "floor_log_chapter_read" on floor_log for select
  using (member_id in (select id from profiles where chapter_id = my_chapter()));
create policy "floor_log_leader_write" on floor_log for insert
  with check (exists(
    select 1 from meetings m where m.id = meeting_id and is_leader_of(m.chapter_id)
  ));

-- speaker_requests: any chapter member can volunteer for (or
-- withdraw from) their own request on a meeting in their own
-- chapter; the rest of the chapter can see who has volunteered,
-- same as floor_log, since there's nothing private about wanting to
-- speak — it's meant to help the chair fill the four positions
create policy "speaker_requests_chapter_read" on speaker_requests for select
  using (exists(select 1 from meetings m where m.id = meeting_id and m.chapter_id = my_chapter()));
create policy "speaker_requests_own_insert" on speaker_requests for insert
  with check (member_id = auth.uid() and exists(select 1 from meetings m where m.id = meeting_id and m.chapter_id = my_chapter()));
create policy "speaker_requests_own_update" on speaker_requests for update
  using (member_id = auth.uid())
  with check (member_id = auth.uid());
create policy "speaker_requests_own_delete" on speaker_requests for delete
  using (member_id = auth.uid());

-- reports: any signed-in member can file one for their own
-- chapter; only that chapter's leader (or a national admin) can
-- read them back. There is no reporter identity stored anywhere,
-- so this is real anonymity, not just a hidden name in the UI.
-- chapter_id defaults to my_chapter() rather than trusting a
-- client-supplied value, so a stale cached chapter_id (e.g. after a
-- chapter request gets approved mid-session) can never fail this
-- check — the database fills it in fresh at insert time.
alter table reports alter column chapter_id set default my_chapter();
create policy "reports_member_insert" on reports for insert
  with check (chapter_id = my_chapter());
create policy "reports_leader_read" on reports for select
  using (is_leader_of(chapter_id) or my_role() = 'national_admin');
create policy "reports_leader_update" on reports for update
  using (is_leader_of(chapter_id) or my_role() = 'national_admin');

-- chapter_requests: anyone, signed in or not, can file one;
-- only a national admin reviews them
create policy "chapter_requests_public_insert" on chapter_requests for insert
  with check (true);
create policy "chapter_requests_admin_read" on chapter_requests for select
  using (my_role() = 'national_admin');
create policy "chapter_requests_admin_update" on chapter_requests for update
  using (my_role() = 'national_admin');

-- ------------------------------------------------------------
-- aggregate views — expose vote *counts* without ever exposing
-- who voted which way. Views run with their owner's privileges,
-- so they can read every row of `ballots`/`shortlist_votes` even
-- though the RLS policies above stop everyone else from doing so
-- directly.
-- ------------------------------------------------------------

create view meeting_ballot_results as
  select meeting_id, stage, side, count(*) as votes
  from ballots
  group by meeting_id, stage, side;

create view motion_vote_counts as
  select motion_id, count(*) as votes
  from shortlist_votes
  group by motion_id;

grant select on meeting_ballot_results to authenticated, anon;
grant select on motion_vote_counts to authenticated, anon;

-- sitewide counts for the public homepage — numbers only, no rows,
-- so it's safe to expose even though `profiles` itself is locked down
create view public_stats as
  select
    (select count(*) from chapters where status in ('active', 'founding') and not is_placeholder) as active_chapters,
    (select count(*) from profiles) as total_members,
    (select count(*) from meetings where status = 'completed') as debates_held;

grant select on public_stats to authenticated, anon;

-- ------------------------------------------------------------
-- seed: your founding chapter (edit before running, or update
-- afterwards from the Table Editor)
-- ------------------------------------------------------------

insert into chapters (name, location, status, room, lat, lng)
values ('Seattle Academy', 'Capitol Hill, Seattle', 'founding', 'Room US 211', 47.61, -122.33);

-- the shared holding pen for anyone requesting a chapter that doesn't exist yet
insert into chapters (name, location, status, is_placeholder)
values ('Pending Chapter', 'Awaiting approval', 'pending', true);

-- After running this file: sign up through the site once with your
-- own account, then in Table Editor -> profiles, change your row's
-- `role` to 'leader' (or 'national_admin' if you want cross-chapter
-- access). There is no self-service way to become a leader — that's
-- intentional.

-- Run this once (or let it auto-push via the CLI).
-- Lets a chapter request carry a location (and its geocoded lat/lng)
-- collected from the requester up front, so approving it can place
-- the new chapter on the map immediately instead of the admin having
-- to look up coordinates by hand.

alter table chapter_requests add column location text;
alter table chapter_requests add column lat double precision;
alter table chapter_requests add column lng double precision;

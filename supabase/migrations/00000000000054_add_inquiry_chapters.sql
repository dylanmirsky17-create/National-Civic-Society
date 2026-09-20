-- Real schools where outreach is underway toward founding a chapter.
-- Marked 'inquiry' (not 'active'/'founding'), which the public_stats
-- view deliberately excludes from active_chapters, and with no
-- member accounts attached — nobody has registered there yet, so
-- none should be invented.
insert into chapters (name, location, status, lat, lng) values
  ('Lakeside School', 'Seattle, WA', 'inquiry', 47.7322724, -122.3273073),
  ('Bush School', 'Seattle, WA', 'inquiry', 47.6231001, -122.2883031),
  ('Roosevelt High School', 'Seattle, WA', 'inquiry', 47.6773046, -122.3138071),
  ('Mercer Island High School', 'Mercer Island, WA', 'inquiry', 47.5718919, -122.2193087),
  ('Bellevue High School', 'Bellevue, WA', 'inquiry', 47.6042261, -122.1984343);

-- Run this once in the SQL Editor. Adds storage for the customizable
-- meeting-format run sheets (main format + alternative structures)
-- that leaders edit from Admin. Null until a leader saves changes —
-- the site falls back to its built-in defaults until then.

alter table chapters add column run_sheet jsonb;

-- Run this once in the SQL Editor.
-- Removes the unused school_email_domain column — nothing in the app
-- ever checked it, so it was dead weight rather than a real feature.

alter table chapters drop column school_email_domain;

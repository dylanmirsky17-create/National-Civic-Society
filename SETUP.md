# Getting this live

## 1. Create a Supabase project
1. Go to supabase.com → sign up (free tier is plenty for a club site) → New project.
2. Once it's created, open **SQL Editor** → New query → paste in the entire contents of `supabase/schema.sql` from this repo → Run.
   - Edit the `insert into chapters (...)` line near the bottom first if "Seattle Academy" / your real email domain isn't right.
3. Open **Settings → API**. Copy the **Project URL** and the **anon public** key.
4. Paste them into `config.js` in this folder, replacing the placeholders.

If you already ran an older copy of `schema.sql` before these files existed, run these once each in the SQL Editor (in order — they're small, additive changes, safe to run on an existing project):
- `supabase/migration_2_stats.sql` — adds the homepage's live stats
- `supabase/migration_3_run_sheet.sql` — adds storage for editable meeting-format run sheets
- `supabase/migration_4_report_emails.sql` — adds the email column reports notifications need

## 2. Make your own account a leader or national admin
Since there's no self-service way to get either role (on purpose — that's the permissions boundary), do this once:
1. Open the site, click **Join**, register your own account normally (you'll come in as a `member`).
2. In Supabase, go to **Table Editor → profiles**, find your row, change `role` from `member` to `leader` (runs one chapter) or `national_admin` (runs everything, every chapter).
3. Sign out and back in on the site. A national admin gets a "Viewing as" switch in the top bar to preview the site as an admin or a member without losing their real permissions.

## 3. Email confirmation
By default Supabase requires confirming a new account's email before it can sign in. For a small club that's good practice long-term, but if you want people to be able to sign up and start using it immediately, go to **Authentication → Providers → Email** and turn off "Confirm email."

## 4. Turn on email notifications for anonymous reports
Reports are meant to email the chapter's leader(s) and every national admin the moment one is filed. This needs a small server-side function, since sending email requires a secret API key that can never live in the browser-side code.

1. **Get an email-sending API key.** Sign up free at resend.com and grab an API key from the dashboard. (Their sandbox address `onboarding@resend.dev` works immediately for testing, with no domain setup — switch to your own domain later for the real "from" address.)
2. **Install the Supabase CLI** (one-time): `npm install -g supabase` (or `brew install supabase/tap/supabase` on a Mac).
3. **Link this project to your Supabase project:** from this folder, run `supabase login`, then `supabase link --project-ref ecxsyfopgwlsjkqiivef` (your project ref is the subdomain in your Project URL).
4. **Set the secrets** the function needs:
   ```
   supabase secrets set RESEND_API_KEY=your_resend_key_here
   supabase secrets set NOTIFY_FROM_EMAIL=onboarding@resend.dev
   ```
5. **Deploy the function:** `supabase functions deploy notify-report`

That's it — the code already calls this function every time someone files a report (`supabase/functions/notify-report/index.ts`). If the function isn't deployed yet, reports still save fine; they just won't trigger an email until you finish these steps.

## 5. Host it
This is still a static site (`index.html` + `config.js`), so any static host works:
- **Vercel** or **Netlify**: drag-and-drop the folder or connect the GitHub repo, deploy, then add your custom domain under the project's Domain settings — both walk you through the DNS records.
- **Cloudflare Pages**: same idea, and convenient if you buy the domain through Cloudflare too (one dashboard for both).

## 6. Buy the domain
Any registrar works (Cloudflare, Namecheap, Squarespace Domains). Once bought, point it at whichever host you picked above — they'll give you exact DNS records to add.

---

## What's real now vs. still a demo

**Wired to the database (Supabase), enforced by row-level security:**
- Sign up / sign in / sign out — real accounts, real passwords
- Roles: `member`, `leader`, `national_admin` — checked server-side, not just hidden in the UI; a national admin can preview the site as a lower role without losing real access
- Submitting topics (Submit page) and voting on the shortlist (Vote page)
- Anonymous reports — genuinely anonymous (no reporter identity is ever stored) — and, once you finish step 4 above, they email the chapter's leader(s) and national admins automatically
- Chapter settings: room, meeting length, vote/submission close dates, the 6-meeting schedule, and the meeting-format run sheets (Admin → Meeting formats & run sheet: switch between the main 40-minute debate and four alternative structures, reorder/rename/retime any segment, add or remove segments)
- The homepage's live stats (active chapters, members, debates held)
- Admin's roster (real chapter members) and the Account page (your real name, email, chapter, floor log, and a plain-language list of what your role permits)
- The Chapters page's map and directory (real rows from the `chapters` table)

**Still static or not yet built:**
- The Chair console countdown timer itself is ephemeral by design (a live clock, nothing to save)
- Who's speaking/chairing/logging a specific meeting — the schema doesn't have a "meeting assignments" concept yet; the Home page shows "Not yet assigned" until that's built
- The Archive page's results come from the live in-meeting "before/after" ballot, which has a database table (`ballots`) ready in the schema but no voting UI built yet — that's the natural next step once you're ready to run a real meeting end-to-end

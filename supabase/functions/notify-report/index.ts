// Sends an email to the chapter's leader(s) and every national admin
// whenever a new anonymous report is filed. Runs server-side with the
// service role key, so it can look up recipient emails regardless of
// RLS — but it only ever reads the report by its id, and the
// `reports` table has no reporter identity column to begin with, so
// this cannot and does not unmask who submitted it.
//
// Deploy: supabase functions deploy notify-report
// Secrets needed (supabase secrets set ...):
//   RESEND_API_KEY     — from resend.com (free tier is plenty)
//   NOTIFY_FROM_EMAIL  — e.g. "reports@yourdomain.org", or
//                         "onboarding@resend.dev" while testing
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const FROM_EMAIL = Deno.env.get("NOTIFY_FROM_EMAIL") ?? "onboarding@resend.dev";

// The browser sends a CORS "preflight" OPTIONS request (no body) before
// the real cross-origin POST from the site. Without handling it, that
// empty request hits this handler and crashes trying to parse JSON —
// which fails the preflight and silently blocks the real POST from
// ever being sent. These headers, and the early OPTIONS return below,
// fix that.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    const { report_id } = await req.json();
    if (!report_id) {
      return new Response("Missing report_id", { status: 400, headers: corsHeaders });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: report, error: reportErr } = await supabase
      .from("reports")
      .select("category, body, created_at, chapter_id, chapters(name)")
      .eq("id", report_id)
      .single();
    if (reportErr || !report) {
      return new Response("Report not found", { status: 404, headers: corsHeaders });
    }

    const { data: recipients } = await supabase
      .from("profiles")
      .select("email")
      .not("email", "is", null)
      .or(`role.eq.national_admin,and(role.eq.leader,chapter_id.eq.${report.chapter_id})`);

    const to = [...new Set((recipients ?? []).map((r) => r.email).filter(Boolean))];
    if (!to.length || !RESEND_API_KEY) {
      return new Response("No recipients or RESEND_API_KEY not set", { status: 200, headers: corsHeaders });
    }

    const chapterName = (report as any).chapters?.name ?? "your chapter";
    const subject = `New anonymous report — ${chapterName}`;
    const text =
      `Category: ${report.category}\n\n${report.body}\n\n` +
      `Submitted anonymously — no reporter identity is stored anywhere, ` +
      `so this notification is all the information that exists about who sent it.`;

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ from: FROM_EMAIL, to, subject, text }),
    });

    if (!res.ok) return new Response(await res.text(), { status: 502, headers: corsHeaders });
    return new Response("ok", { status: 200, headers: corsHeaders });
  } catch (e) {
    console.error(e);
    return new Response("error", { status: 500, headers: corsHeaders });
  }
});

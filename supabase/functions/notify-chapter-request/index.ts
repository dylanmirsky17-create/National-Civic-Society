// Sends an email to every national admin whenever someone requests a
// new chapter. Without this, a pending request just sits silently in
// the database until a national admin happens to check the Requests
// page — there was previously no way to know one had come in at all.
//
// Deploy: supabase functions deploy notify-chapter-request
// Secrets needed (supabase secrets set ...):
//   RESEND_API_KEY     — from resend.com (free tier is plenty)
//   NOTIFY_FROM_EMAIL  — e.g. "reports@yourdomain.org", or
//                         "onboarding@resend.dev" while testing
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const FROM_EMAIL = Deno.env.get("NOTIFY_FROM_EMAIL") ?? "onboarding@resend.dev";

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
    const { request_id } = await req.json();
    if (!request_id) {
      return new Response("Missing request_id", { status: 400, headers: corsHeaders });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: reqRow, error: reqErr } = await supabase
      .from("chapter_requests")
      .select("school_name, requested_by_name, requested_by_email, location, created_at")
      .eq("id", request_id)
      .single();
    if (reqErr || !reqRow) {
      return new Response("Request not found", { status: 404, headers: corsHeaders });
    }

    const { data: recipients } = await supabase
      .from("profiles")
      .select("email")
      .eq("role", "national_admin")
      .not("email", "is", null);

    const to = [...new Set((recipients ?? []).map((r) => r.email).filter(Boolean))];
    if (!to.length || !RESEND_API_KEY) {
      return new Response("No recipients or RESEND_API_KEY not set", { status: 200, headers: corsHeaders });
    }

    const subject = `New chapter request: ${reqRow.school_name}`;
    const text =
      `${reqRow.school_name} has requested to start a National Civic Society chapter.\n\n` +
      `Requested by: ${reqRow.requested_by_name || "unknown"} (${reqRow.requested_by_email || "no email given"})\n` +
      `Location: ${reqRow.location || "not given"}\n\n` +
      `Review and approve or dismiss it from the Requests page.`;

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

// Supabase Edge Function: send-invoice-email
//
// Relays invoice emails through your own SMTP server. Credentials are read
// from Supabase secrets (set via `supabase secrets set`) and never ship
// inside the Flutter app. Requires a valid Supabase auth session to invoke
// (default JWT verification — Supabase automatically rejects unauthenticated
// callers before this code runs).
//
// Deploy:   supabase functions deploy send-invoice-email
// Secrets:  supabase secrets set SMTP_HOST=... SMTP_PORT=... SMTP_USER=... \
//             SMTP_PASSWORD=... SMTP_FROM=... SMTP_FROM_NAME=...

import nodemailer from "npm:nodemailer@6.9.16";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface SendInvoiceEmailBody {
  to: string;
  subject: string;
  html: string;
  attachmentBase64?: string;
  attachmentFilename?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { to, subject, html, attachmentBase64, attachmentFilename } =
      (await req.json()) as SendInvoiceEmailBody;

    if (!to || !subject || !html) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: to, subject, html" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const host = Deno.env.get("SMTP_HOST");
    const user = Deno.env.get("SMTP_USER");
    const password = Deno.env.get("SMTP_PASSWORD");
    if (!host || !user || !password) {
      console.error("Missing SMTP_HOST / SMTP_USER / SMTP_PASSWORD secret");
      return new Response(
        JSON.stringify({ error: "Email server is not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const port = Number(Deno.env.get("SMTP_PORT") ?? "587");
    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465, // true = implicit TLS (465); false = STARTTLS (587/25)
      auth: { user, pass: password },
    });

    const fromAddress = Deno.env.get("SMTP_FROM") ?? user;
    const fromName = Deno.env.get("SMTP_FROM_NAME");

    await transporter.sendMail({
      from: fromName ? `"${fromName}" <${fromAddress}>` : fromAddress,
      to,
      subject,
      html,
      attachments: attachmentBase64
        ? [
          {
            filename: attachmentFilename ?? "invoice.pdf",
            content: attachmentBase64,
            encoding: "base64",
          },
        ]
        : [],
    });

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("send-invoice-email error:", err);
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

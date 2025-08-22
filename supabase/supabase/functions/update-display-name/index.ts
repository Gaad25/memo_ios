// Edge Function: update-display-name
// Atualiza user_profiles.display_name do usuário autenticado e retorna { profile }

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    const json = await req.json().catch(() => ({}));
    // Aceita a nova chave e a antiga por compatibilidade
    const displayName = (json.displayName ?? json.new_display_name)?.toString()?.trim();

    if (!displayName || displayName.length < 3 || displayName.length > 15) {
      return new Response(
        JSON.stringify({ error: "displayName inválido" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false },
    });

    // Extrai usuário do JWT vindo do app (Authorization: Bearer <token>)
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "");

    const {
      data: { user },
      error: authErr,
    } = await supabase.auth.getUser(jwt);

    if (authErr || !user) {
      return new Response(JSON.stringify({ error: "Não autenticado" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Atualiza a tabela correta
    const { data, error } = await supabase
      .from("user_profiles") // <<-- confirme o nome da sua tabela
      .update({ display_name: displayName }) // <<-- confirme o nome da coluna
      .eq("id", user.id)
      .select("*")
      .single();

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ profile: data }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

// Arquivo: supabase/functions/proxy-openai/index.ts (Usando o modelo GPT-5-nano)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { subject, level, count } = await req.json();
    const openAIKey = Deno.env.get("OPENAI_API_KEY");

    if (!openAIKey) {
      throw new Error("A chave da API da OpenAI não foi configurada.");
    }

    const systemPrompt = `Você é um assistente de estudos que cria quizzes. Gere ${count} perguntas sobre "${subject}" com dificuldade "${level}". Para cada pergunta, forneça 5 opções de múltipla escolha. Uma opção deve ser a correta e as outras quatro devem ser plausíveis, mas incorretas. Retorne a resposta em um formato JSON válido, seguindo esta estrutura: { "questions": [{ "prompt": "...", "options": [ { "text": "Opção A" }, { "text": "Opção B" }, ... ], "correctAnswerIndex": N }] }, onde 'correctAnswerIndex' é o índice (de 0 a 4) da resposta correta no array 'options'. Não inclua nenhum outro texto fora do JSON.`;
    
    const openAIResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openAIKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        // --- LINHA MODIFICADA ---
        model: "gpt-5-nano", // Usando o modelo mais recente e econômico
        // ------------------------
        messages: [{ role: "system", content: systemPrompt }],
        response_format: { type: "json_object" },
      }),
    });

    if (!openAIResponse.ok) {
      const errorBody = await openAIResponse.text();
      throw new Error(`Erro da API da OpenAI: ${errorBody}`);
    }

    const openAIResult = await openAIResponse.json();
    const content = JSON.parse(openAIResult.choices[0].message.content);
    
    const formattedResponse = {
      items: content.questions.map((q: any) => ({
        id: crypto.randomUUID(),
        prompt: q.prompt,
        options: q.options.map((opt: any) => ({ id: crypto.randomUUID(), text: opt.text })),
        correctAnswerIndex: q.correctAnswerIndex,
      })),
    };

    return new Response(JSON.stringify(formattedResponse), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error("ERRO DETALHADO NA FUNÇÃO:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
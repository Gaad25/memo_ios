// Arquivo: supabase/functions/proxy-openai/index.ts (Sistema de Geração em Lote)

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
    
    // Input validation & clamp
    const trimmedSubject = (subject ?? "").toString().trim();
    const trimmedLevel = (level ?? "Intermediário").toString().trim();
    const n = Math.min(20, Math.max(1, Number(count ?? 5)));

    if (trimmedSubject.length < 2 || trimmedSubject.length > 200) {
      return new Response(
        JSON.stringify({ error: "Subject must be between 2-200 characters" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const openAIKey = Deno.env.get("OPENAI_API_KEY");
    if (!openAIKey) {
      console.error("OPENAI_API_KEY not found");
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Sistema de prompts otimizado para geração em lote
    const systemPrompt = `Você é a Zoe, uma tutora de IA especialista em ENEM e vestibulares.
Sua tarefa é criar um quiz completo sobre o tema: ${trimmedSubject}.

REGRAS ABSOLUTAS:
1. GERE EXATAMENTE ${n} perguntas de múltipla escolha de alta qualidade.
2. GARANTA VARIEDADE MÁXIMA: Cada pergunta DEVE abordar um conceito ou sub-tópico diferente dentro do tema principal. NÃO CRIE perguntas que sejam apenas variações numéricas umas das outras.
3. Para cada pergunta, crie 4 opções plausíveis onde apenas uma está correta.
4. A SUA RESPOSTA DEVE SER UM ÚNICO JSON VÁLIDO contendo um array de objetos, no seguinte formato:
[
  {
    "question": "Texto da pergunta 1...",
    "options": { "A": "primeira opção", "B": "segunda opção", "C": "terceira opção", "D": "quarta opção" },
    "answer": "A"
  },
  {
    "question": "Texto da pergunta 2...",
    "options": { "A": "primeira opção", "B": "segunda opção", "C": "terceira opção", "D": "quarta opção" },
    "answer": "A"
  }
]

IMPORTANTE: 
- O campo "answer" deve indicar qual das opções (A, B, C ou D) está correta
- Foque na QUALIDADE das perguntas e opções (a randomização será feita automaticamente)
- NÃO inclua nenhum texto, explicação ou formatação fora deste array JSON
- A resposta deve começar com '[' e terminar com ']'`;

    const messages = [
      {
        role: "system",
        content: systemPrompt
      }
    ];

    console.log(`🎯 Gerando quiz em lote: ${n} perguntas sobre "${trimmedSubject}" (${trimmedLevel})`);

    const openAIResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openAIKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: messages,
        max_tokens: 4000, // Tokens suficientes para múltiplas perguntas
        temperature: 0.8, // Criatividade alta para variedade
        top_p: 0.9,
      }),
    });

    if (!openAIResponse.ok) {
      const errorText = await openAIResponse.text();
      console.error("OpenAI API error:", openAIResponse.status, errorText);
      return new Response(
        JSON.stringify({ 
          error: "IA temporariamente indisponível. Tente novamente em alguns segundos.",
          details: errorText.substring(0, 200)
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const openAIData = await openAIResponse.json();
    let content = openAIData.choices?.[0]?.message?.content?.trim();

    if (!content) {
      console.error("Empty response from OpenAI");
      return new Response(
        JSON.stringify({ error: "Resposta vazia da IA" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log("🤖 Resposta da IA:", content.substring(0, 200) + "...");

    // Parse e validação do JSON
    let parsedQuestions;
    try {
      // Remove possível formatação markdown
      content = content.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      
      // Se não começar com [, tenta extrair o array
      if (!content.startsWith('[')) {
        const arrayMatch = content.match(/\[[\s\S]*\]/);
        if (arrayMatch) {
          content = arrayMatch[0];
        }
      }

      parsedQuestions = JSON.parse(content);
      
      if (!Array.isArray(parsedQuestions)) {
        throw new Error("Response is not an array");
      }

      // Função para SEMPRE randomizar as respostas (solução definitiva)
      function forceRandomizeAnswers(questions: any[]): any[] {
        const letters = ['A', 'B', 'C', 'D'];
        
        console.log(`🔄 FORÇANDO randomização de ${questions.length} perguntas...`);
        
        return questions.map((q, index) => {
          // Força uma distribuição equilibrada: A, B, C, D, A, B, C, D...
          const targetAnswerLetter = letters[index % 4];
          
          if (!q.options || typeof q.options !== 'object') {
            console.error(`❌ Pergunta ${index} não tem opções válidas:`, q);
            return q;
          }
          
          // Se a resposta já está na posição correta, mantém
          if (q.answer === targetAnswerLetter) {
            console.log(`✅ Pergunta ${index}: resposta já está em ${targetAnswerLetter}`);
            return q;
          }
          
          // Troca o conteúdo das opções
          const originalCorrectContent = q.options[q.answer] || "Resposta correta";
          const targetPositionContent = q.options[targetAnswerLetter] || "Opção alternativa";
          
          const newOptions = { ...q.options };
          newOptions[q.answer] = targetPositionContent;
          newOptions[targetAnswerLetter] = originalCorrectContent;
          
          console.log(`🔄 Pergunta ${index}: ${q.answer} → ${targetAnswerLetter}`);
          
          return {
            ...q,
            options: newOptions,
            answer: targetAnswerLetter
          };
        });
      }

      // SEMPRE aplica a randomização forçada
      const originalDistribution = parsedQuestions.map(q => q.answer).join(',');
      parsedQuestions = forceRandomizeAnswers(parsedQuestions);
      const newDistribution = parsedQuestions.map(q => q.answer).join(',');
      
      console.log(`📊 Distribuição original: [${originalDistribution}]`);
      console.log(`📊 Distribuição final: [${newDistribution}]`);
      
      const finalCounts = {
        A: parsedQuestions.filter(q => q.answer === 'A').length,
        B: parsedQuestions.filter(q => q.answer === 'B').length,
        C: parsedQuestions.filter(q => q.answer === 'C').length,
        D: parsedQuestions.filter(q => q.answer === 'D').length
      };
      console.log(`✅ Contagem final: A=${finalCounts.A}, B=${finalCounts.B}, C=${finalCounts.C}, D=${finalCounts.D}`);

    } catch (parseError) {
      console.error("JSON parse error:", parseError.message);
      console.error("Content:", content);
      
      return new Response(
        JSON.stringify({ error: "Formato de resposta inválido da IA" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Converte para o formato esperado pelo cliente
    const formattedQuestions = parsedQuestions.map((q: any, index: number) => {
      const question = q.question || q.prompt || `Pergunta ${index + 1}`;
      const options = q.options || {};
      
      // Converte opções para array de objetos AIOption
      const optionsArray = [];
      const letters = ['A', 'B', 'C', 'D'];
      for (const letter of letters) {
        if (options[letter]) {
          optionsArray.push({
            id: `${index}-${letter}`, // ID único
            text: options[letter]
          });
        }
      }
      
      // Encontra o índice da resposta correta
      const answerLetter = (q.answer || 'A').toUpperCase();
      const correctAnswerIndex = letters.indexOf(answerLetter);
      
      return {
        id: `quiz-${index}`,
        prompt: question,
        options: optionsArray,
        correctAnswerIndex: Math.max(0, correctAnswerIndex),
        explanation: "" // Mantido vazio por compatibilidade
      };
    });

    console.log(`✅ Quiz gerado com sucesso: ${formattedQuestions.length} perguntas`);

    return new Response(
      JSON.stringify(formattedQuestions),
      { 
        status: 200, 
        headers: { 
          ...corsHeaders, 
          "Content-Type": "application/json",
          "Cache-Control": "no-cache"
        } 
      }
    );

  } catch (error) {
    console.error("Unexpected error:", error.message, error.stack);
    return new Response(
      JSON.stringify({ 
        error: "Erro interno do servidor",
        details: error.message 
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
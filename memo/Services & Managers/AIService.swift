//
//  AIService.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 09/08/25.
//
import Foundation

// Estrutura para uma opção de resposta
struct AIOption: Identifiable, Decodable, Equatable {
    let id: UUID
    let text: String
}
// Define a estrutura de dados para uma pergunta e resposta da IA.
// A conformidade com Identifiable é para uso em listas SwiftUI.
struct AIQuestion: Identifiable, Decodable, Equatable {
    let id: UUID
    let prompt: String
    let options: [AIOption]
    let correctAnswerIndex: Int
}

// Define um protocolo para o serviço de IA.
// Isso permite criar implementações falsas (mocks) para testes no futuro.
protocol AIService {
    func generateQuestions(subject: String, level: String, count: Int) async throws -> [AIQuestion]
}

// Implementação final do serviço que chama o seu backend (Supabase Function).
final class OpenAIService: AIService {
    
    // ATENÇÃO: Substitua esta URL pela URL da sua Supabase Function
    // que você obterá após o deploy no passo 4.
    private let baseURL = URL(string: "https://rrbebclkhexlfkexqrvf.supabase.co/functions/v1")!
    
    // Cria uma instância do RateLimiter.
    // Com esta configuração, todos os usuários terão um limite de 5 usos por dia.
    private let limiter = RateLimiter(maxDaily: 5)

    func generateQuestions(subject: String, level: String, count: Int) async throws -> [AIQuestion] {
        
        // --- MODIFICAÇÃO PRINCIPAL ---
        // A verificação de assinatura foi removida.
        // O limite de uso diário agora é aplicado a todos os usuários.
        let ok = await limiter.consume()
        guard ok else {
            // Se o limite for atingido, lança um erro específico.
            throw AppError.rateLimited
        }
        
        // Monta a URL completa para a função do Supabase.
        var req = URLRequest(url: baseURL.appending(path: "/proxy-openai"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Cria o corpo (body) da requisição com os parâmetros.
        let body = ["subject": subject, "level": level, "count": count] as [String : Any]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Faz a chamada de rede.
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        // Verifica se a resposta do servidor foi bem-sucedida (código 2xx).
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AppError.network("O servidor da IA retornou um erro.")
        }
        
        // Define a estrutura que esperamos receber do nosso backend.
        struct Response: Decodable {
            let items: [AIQuestion]
        }
        
        // Tenta decodificar a resposta JSON.
        do {
            return try JSONDecoder().decode(Response.self, from: data).items
        } catch {
            throw AppError.decoding
        }
    }
}

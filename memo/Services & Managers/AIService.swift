//
//  AIService.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 09/08/25.
//
import Foundation

// Estrutura para uma opção de resposta
struct AIOption: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
}
// Define a estrutura de dados para uma pergunta e resposta da IA.
// A conformidade com Identifiable é para uso em listas SwiftUI.
struct AIQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    let prompt: String
    let options: [AIOption]
    let correctAnswerIndex: Int
    let explanation: String // mantido por compatibilidade, mas não utilizado
}

// Define um protocolo para o serviço de IA.
// Isso permite criar implementações falsas (mocks) para testes no futuro.
protocol AIService {
    func generateQuestions(subject: String, level: String, count: Int) async throws -> [AIQuestion]
    func generateFullQuiz(subject: String, level: String, count: Int) async throws -> [AIQuestion]
}

// Implementação final do serviço que chama o seu backend (Supabase Function).
final class OpenAIService: AIService {
    
    // ATENÇÃO: Substitua esta URL pela URL da sua Supabase Function
    // que você obterá após o deploy no passo 4.
    private let baseURL = URL(string: "https://rrbebclkhexlfkexqrvf.supabase.co/functions/v1")!
    
    // Cria uma instância do RateLimiter.
    // Com esta configuração, todos os usuários terão um limite de 5 usos por dia.
    private let limiter = RateLimiter(maxDaily: 5)
    private let cache = AICache(ttlSeconds: 600)

    func generateQuestions(subject: String, level: String, count: Int) async throws -> [AIQuestion] {
        // 1) Cache de curta duração
        let key = AICache.Key(subject: subject, level: level, count: count)
        if let cached = await cache.get(for: key) {
            return cached
        }

        // 2) Rate limit apenas quando for chamar a API
        let ok = await limiter.consume()
        guard ok else { throw AppError.rateLimited }

        // 3) Monta a URL completa para a função do Supabase.
        var req = URLRequest(url: baseURL.appending(path: "/proxy-openai"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Recomendado: enviar Authorization/apikey quando a função requerer JWT
        // req.setValue("Bearer \(Secrets.$supabaseKey)", forHTTPHeaderField: "Authorization")
        // req.setValue(Secrets.$supabaseKey, forHTTPHeaderField: "apikey")
        
        // 4) Cria o corpo (body) da requisição com os parâmetros.
        let body = ["subject": subject, "level": level, "count": count] as [String : Any]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // 5) Faz a chamada de rede com timeout reduzido
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 30
        let session = URLSession(configuration: config)
        let (data, resp) = try await session.data(for: req)
        
        // 6) Verifica se a resposta do servidor foi bem-sucedida (código 2xx).
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AppError.network("O servidor da IA retornou um erro.")
        }
        
        // 7) Define a estrutura que esperamos receber do nosso backend.
        struct Response: Decodable { let items: [AIQuestion] }
        
        // 8) Tenta decodificar a resposta JSON.
        do {
            // 1) Tenta decodificar diretamente
            if let response = try? JSONDecoder().decode(Response.self, from: data) {
                await cache.set(response.items, for: key)
                return response.items
            }

            // 2) Tenta como string JSON "crua"
            if let asString = String(data: data, encoding: .utf8) {
                if let innerData = asString.data(using: .utf8),
                   let response = try? JSONDecoder().decode(Response.self, from: innerData) {
                    await cache.set(response.items, for: key)
                    return response.items
                }

                // 3) Remove cercas de código, se existirem
                let cleaned = asString
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                if let cleanedData = cleaned.data(using: .utf8),
                   let response = try? JSONDecoder().decode(Response.self, from: cleanedData) {
                    await cache.set(response.items, for: key)
                    return response.items
                }

                // 4) Fallback permissivo: tentar mapear manualmente o JSON
                if let permissive = Self.permissiveParse(fromString: asString) {
                    await cache.set(permissive, for: key)
                    return permissive
                }
            }

            throw AppError.decoding
        } catch {
            throw AppError.decoding
        }
    }

    // MARK: - Fallback permissivo
    private static func permissiveParse(fromString s: String) -> [AIQuestion]? {
        func parse(_ str: String) -> Any? {
            let cleaned = str.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
            if let d = cleaned.data(using: .utf8) {
                return try? JSONSerialization.jsonObject(with: d)
            }
            return nil
        }
        guard let rootAny = parse(s) as? [String: Any] else { return nil }
        let arrAny: [Any]
        if let qs = rootAny["items"] as? [Any] { arrAny = qs }
        else if let qs = rootAny["questions"] as? [Any] { arrAny = qs }
        else { return nil }

        var result: [AIQuestion] = []
        for el in arrAny {
            guard let q = el as? [String: Any] else { continue }
            let prompt = (q["prompt"] ?? q["question"] ?? "") as? String ?? ""
            let explanation = "" // ignorar explicações por enquanto
            
            var options: [AIOption] = []
            if let raw = q["options"] {
                if let arr = raw as? [Any] {
                    for item in arr {
                        if let s = item as? String {
                            options.append(AIOption(id: UUID(), text: s))
                        } else if let o = item as? [String: Any] {
                            let t = (o["text"] ?? o["label"] ?? o["option"] ?? "") as? String ?? ""
                            options.append(AIOption(id: UUID(), text: t))
                        }
                    }
                } else if let dict = raw as? [String: Any] {
                    // Formato { "A": "...", "B": "...", "C": "...", "D": "..." }
                    let letters = ["A", "B", "C", "D"]
                    for letter in letters {
                        if let text = dict[letter] as? String {
                            options.append(AIOption(id: UUID(), text: text))
                        }
                    }
                }
            }
            if options.count < 2 { options = [AIOption(id: UUID(), text: "Opção A"), AIOption(id: UUID(), text: "Opção B")] }
            var idx: Int = 0
            if let v = q["correctAnswerIndex"] { idx = Self.coerceIndex(v, count: options.count) }
            else if let v = q["correct"] { idx = Self.coerceIndex(v, count: options.count) }
            else if let v = q["answerIndex"] { idx = Self.coerceIndex(v, count: options.count) }
            else if let answer = q["answer"] as? String {
                // Converte "A", "B", "C", "D" para índice
                let answerUpper = answer.uppercased()
                if let letterIndex = answerUpper.first?.asciiValue, letterIndex >= 65, letterIndex <= 68 {
                    idx = Int(letterIndex - 65) // A=0, B=1, C=2, D=3
                    if idx >= options.count { idx = 0 }
                }
            }
            result.append(AIQuestion(id: UUID(), prompt: prompt, options: options, correctAnswerIndex: idx, explanation: explanation))
        }
        return result.isEmpty ? nil : result
    }

    private static func coerceIndex(_ any: Any, count: Int) -> Int {
        if let n = any as? Int { return (0..<count).contains(n) ? n : 0 }
        if let s = any as? String {
            if let n = Int(s) { return (0..<count).contains(n) ? n : 0 }
            if let c = s.uppercased().unicodeScalars.first { let idx = Int(c.value) - 65; return (0..<count).contains(idx) ? idx : 0 }
        }
        return 0
    }
}

// MARK: - Cache simples (com TTL) para respostas de IA
actor AICache {
    struct Key: Hashable {
        let subject: String
        let level: String
        let count: Int
        var normalized: String {
            subject.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() + "|" + level.lowercased() + "|" + String(count)
        }
    }

    private struct Entry: Codable {
        let items: [AIQuestion]
        let expiry: Date
    }

    private let ttl: TimeInterval
    private let defaults = UserDefaults.standard
    private let namespace = "ai_cache_v2_" // v2 inclui explicações

    init(ttlSeconds: TimeInterval) {
        self.ttl = ttlSeconds
    }

    func get(for key: Key) -> [AIQuestion]? {
        let k = namespace + key.normalized
        guard let data = defaults.data(forKey: k) else { return nil }
        do {
            let entry = try JSONDecoder().decode(Entry.self, from: data)
            guard Date() < entry.expiry else { return nil }
            return entry.items
        } catch {
            return nil
        }
    }

    func set(_ items: [AIQuestion], for key: Key) {
        let expiry = Date().addingTimeInterval(ttl)
        let entry = Entry(items: items, expiry: expiry)
        let k = namespace + key.normalized
        if let data = try? JSONEncoder().encode(entry) {
            defaults.set(data, forKey: k)
        }
    }
}

// MARK: - Batch Quiz Generation
extension OpenAIService {
    /// Gera um quiz completo em uma única chamada de API
    func generateFullQuiz(subject: String, level: String, count: Int) async throws -> [AIQuestion] {
        // Consome rate limit uma única vez
        let ok = await limiter.consume()
        guard ok else { throw AppError.rateLimited }
        
        var req = URLRequest(url: baseURL.appending(path: "/proxy-openai"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "subject": subject,
            "level": level,
            "count": count
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30 // Timeout maior para geração em lote
        config.timeoutIntervalForResource = 45
        let session = URLSession(configuration: config)
        let (data, resp) = try await session.data(for: req)
        
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AppError.network("O servidor da IA retornou um erro.")
        }
        
        // Tenta decodificar diretamente como array de perguntas
        let decoder = JSONDecoder()
        if let questions = try? decoder.decode([AIQuestion].self, from: data) {
            return questions.map { question in
                AIQuestion(
                    id: UUID(),
                    prompt: question.prompt,
                    options: question.options,
                    correctAnswerIndex: question.correctAnswerIndex,
                    explanation: ""
                )
            }
        }
        
        // Fallback: usa o parser permissivo
        if let asString = String(data: data, encoding: .utf8),
           let parsed = Self.permissiveParse(fromString: asString) {
            return parsed
        }
        
        throw AppError.decoding
    }
}

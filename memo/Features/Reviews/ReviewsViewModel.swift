import Foundation
import SwiftUI

@MainActor
final class ReviewsViewModel: ObservableObject {
    // Este struct representa uma revisão com todos os dados necessários para a view.
    struct ReviewDetail: Identifiable, Decodable {
        let reviewId: UUID
        let reviewData: Review
        let subjectData: Subject
        let sessionNotes: String?

        var id: UUID { reviewId }

        enum CodingKeys: String, CodingKey {
            case reviewId = "review_id"
            case reviewData = "review_data"
            case subjectData = "subject_data"
            case sessionNotes = "session_notes"
        }
        
        init(reviewId: UUID, reviewData: Review, subjectData: Subject, sessionNotes: String?) {
            self.reviewId = reviewId
            self.reviewData = reviewData
            self.subjectData = subjectData
            self.sessionNotes = sessionNotes
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.reviewId = try container.decode(UUID.self, forKey: .reviewId)
            self.sessionNotes = try container.decodeIfPresent(String.self, forKey: .sessionNotes)

            self.reviewData = try Self.decodeMixedJSON(Review.self, from: container, forKey: .reviewData)
            self.subjectData = try Self.decodeMixedJSON(Subject.self, from: container, forKey: .subjectData)
        }

        private static func decodeMixedJSON<T: Decodable>(
            _ type: T.Type,
            from container: KeyedDecodingContainer<CodingKeys>,
            forKey key: CodingKeys
        ) throws -> T {
            if let object = try? container.decode(T.self, forKey: key) {
                return object
            }

            if let jsonString = try? container.decode(String.self, forKey: key),
               let data = jsonString.data(using: .utf8) {
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            }

            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "O campo \(key.stringValue) não é um objeto JSON válido nem uma string JSON decodificável."
            )
        }
    }
    
    enum ReviewDifficulty: String {
        case facil, medio, dificil
    }
    
    @Published var reviewDetails: [ReviewDetail] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var reviewToComplete: ReviewDetail?
    @Published var showingDifficultySelector = false
    
    func fetchData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            self.reviewDetails = try await SupabaseManager.shared.client
                .rpc("get_pending_reviews_with_details")
                .execute()
                .value
            
        } catch {
            self.errorMessage = "Erro ao buscar revisões: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func startCompletionFlow(for detail: ReviewDetail) {
        self.reviewToComplete = detail
        
        // Adiciona um pequeno delay para garantir que o SwiftUI processe a mudança de estado
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundo
            self.showingDifficultySelector = true
        }
    }
    
    func completeReview(with difficulty: ReviewDifficulty) {
        guard let detail = reviewToComplete else { return }
        
        // Remove da UI primeiro para uma resposta rápida
        reviewDetails.removeAll { $0.id == detail.id }
        
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("reviews")
                    .update(["status": "completed", "last_review_difficulty": difficulty.rawValue])
                    .eq("id", value: detail.reviewData.id)
                    .execute()

                await scheduleNextReview(for: detail.reviewData, basedOn: difficulty)
                
                await HomeViewModel.shared.userDidCompleteAction()

            } catch {
                print("Erro ao completar revisão: \(error.localizedDescription)")
                await fetchData() // Recarrega os dados em caso de erro.
            }
        }
        
        // Garante que o estado seja limpo.
        self.reviewToComplete = nil
        self.showingDifficultySelector = false
    }
    
    private func scheduleNextReview(for previousReview: Review, basedOn difficulty: ReviewDifficulty) async {
        
        let nextIntervalKey: String

        switch previousReview.reviewInterval {
        case "1d":
            switch difficulty {
            case .facil:   nextIntervalKey = "7d"
            case .medio:   nextIntervalKey = "3d"
            case .dificil: nextIntervalKey = "1d"
            }
        case "3d":
            switch difficulty {
            case .facil:   nextIntervalKey = "7d"
            case .medio:   nextIntervalKey = "7d"
            case .dificil: nextIntervalKey = "1d"
            }
        case "7d":
            switch difficulty {
            case .facil:   nextIntervalKey = "30d"
            case .medio:   nextIntervalKey = "15d"
            case .dificil: nextIntervalKey = "3d"
            }
        case "15d":
            switch difficulty {
            case .facil:   nextIntervalKey = "30d"
            case .medio:   nextIntervalKey = "30d"
            case .dificil: nextIntervalKey = "7d"
            }
        case "30d":
            switch difficulty {
            case .facil:   nextIntervalKey = "90d"
            case .medio:   nextIntervalKey = "90d"
            case .dificil: nextIntervalKey = "15d"
            }
        case "90d":
            switch difficulty {
            case .facil:
                // O ciclo de revisões para esta sessão terminou.
                print("Ciclo de revisões concluído com sucesso.")
                return // Não agenda uma nova revisão
            case .medio:
                nextIntervalKey = "90d" // Repete o último intervalo
            case .dificil:
                nextIntervalKey = "30d" // Regride para 30 dias
            }
        default:
            print("AVISO: Intervalo de revisão desconhecido ('\(previousReview.reviewInterval)'). Agendando para 1 dia.")
            nextIntervalKey = "1d"
        }

        // Extrai o número de dias do texto do intervalo (ex: "7d" -> 7)
        guard let daysToAdd = Int(nextIntervalKey.replacingOccurrences(of: "d", with: "")) else {
            print("ERRO: Não foi possível extrair o número de dias do intervalo: \(nextIntervalKey)")
            return
        }

        // Calcula a nova data a partir de hoje
        let newReviewDate = Calendar.current.date(byAdding: .day, value: daysToAdd, to: Date())!
        
        struct NewReview: Encodable {
            let userId: UUID, sessionId: UUID, subjectId: UUID, reviewDate: Date, reviewInterval: String
            enum CodingKeys: String, CodingKey {
                case userId = "user_id", sessionId = "session_id", subjectId = "subject_id",
                     reviewDate = "review_date", reviewInterval = "review_interval"
            }
        }
        
        let nextReview = NewReview(
            userId: previousReview.userId,
            sessionId: previousReview.sessionId,
            subjectId: previousReview.subjectId,
            reviewDate: newReviewDate,
            reviewInterval: nextIntervalKey
        )
        
        do {
            try await SupabaseManager.shared.client.from("reviews").insert(nextReview).execute()
            print("✅ Próxima revisão agendada para \(newReviewDate.formatted()) com intervalo de \(nextIntervalKey).")
        } catch {
            print("❌ Erro ao agendar a próxima revisão: \(error.localizedDescription)")
        }
    }
}

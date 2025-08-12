// memo/Features/Reviews/ReviewsViewModel.swift

import Foundation
import SwiftUI

@MainActor
final class ReviewsViewModel: ObservableObject {
    // A sua struct ReviewDetail, que já busca os dados corretamente
    struct ReviewDetail: Identifiable, Decodable {
        let reviewId: UUID
        let reviewData: Review
        let subjectData: Subject
        let sessionNotes: String?

        var id: UUID { reviewId }

        enum CodingKeys: String, CodingKey {
            case reviewId = "review_id", reviewData = "review_data", subjectData = "subject_data", sessionNotes = "session_notes"
        }
        
        init(reviewData: Review, subjectData: Subject, sessionNotes: String?) {
            self.reviewId = reviewData.id
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

        private static func decodeMixedJSON<T: Decodable>(_ type: T.Type, from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> T {
            if let object = try? container.decode(T.self, forKey: key) { return object }
            if let jsonString = try? container.decode(String.self, forKey: key), let data = jsonString.data(using: .utf8) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            }
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "O campo \(key.stringValue) não é decodificável.")
        }
    }
    
    enum ReviewDifficulty: String {
        case facil, medio, dificil
    }
    
    // MARK: - Published Properties
    @Published private var reviewDetails: [ReviewDetail] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var reviewToComplete: ReviewDetail?
    @Published var showingCustomDifficultySelector = false
    @Published var showSuccessBadge = false

    // MARK: - Lógica de Filtros
    enum FilterType: String, CaseIterable {
        case hoje = "Hoje"
        case atrasadas = "Atrasadas"
        case proximas = "Próximas"
        case todas = "Todas"
        
        var systemImage: String {
            switch self {
            case .hoje: return "calendar.circle.fill"
            case .atrasadas: return "clock.badge.exclamationmark.fill"
            case .proximas: return "arrow.right.circle.fill"
            case .todas: return "list.bullet.circle.fill"
            }
        }
    }
    
    @Published var selectedFilter: FilterType = .hoje
    
    var filteredReviews: [ReviewDetail] {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        
        switch selectedFilter {
        case .hoje:
            return reviewDetails.filter { Calendar.current.isDateInToday($0.reviewData.reviewDate) }
        case .atrasadas:
            return reviewDetails.filter { $0.reviewData.reviewDate < today }
        case .proximas:
            return reviewDetails.filter { $0.reviewData.reviewDate > today && !Calendar.current.isDateInToday($0.reviewData.reviewDate) }
        case .todas:
            return reviewDetails
        }
    }

    // MARK: - Funções de Dados
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
            self.errorMessage = "Não foi possível buscar as suas revisões."
            print("❌ Erro em fetchData (ReviewsViewModel): \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func startCompletionFlow(for detail: ReviewDetail) {
        self.reviewToComplete = detail
        self.showingCustomDifficultySelector = true
    }
    
    func completeReview(with difficulty: ReviewDifficulty) {
        guard let detail = reviewToComplete else { return }
        
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
                
                withAnimation { showSuccessBadge = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { self.showSuccessBadge = false }
                }
            } catch {
                self.errorMessage = "Erro ao salvar a revisão. Tente novamente."
                await fetchData()
            }
        }
        
        self.reviewToComplete = nil
    }
    
    private func scheduleNextReview(for previousReview: Review, basedOn difficulty: ReviewDifficulty) async {
        let nextIntervalKey: String
        switch previousReview.reviewInterval {
        case "1d":
            switch difficulty {
            case .facil:   nextIntervalKey = "7d"; case .medio:   nextIntervalKey = "3d"; case .dificil: nextIntervalKey = "1d"
            }
        case "3d":
            switch difficulty {
            case .facil, .medio: nextIntervalKey = "7d"; case .dificil: nextIntervalKey = "1d"
            }
        case "7d":
            switch difficulty {
            case .facil:   nextIntervalKey = "30d"; case .medio:   nextIntervalKey = "15d"; case .dificil: nextIntervalKey = "3d"
            }
        case "15d":
            switch difficulty {
            case .facil, .medio: nextIntervalKey = "30d"; case .dificil: nextIntervalKey = "7d"
            }
        case "30d":
            switch difficulty {
            case .facil, .medio: nextIntervalKey = "90d"; case .dificil: nextIntervalKey = "15d"
            }
        case "90d":
            switch difficulty {
            case .facil: return
            case .medio: nextIntervalKey = "90d"
            case .dificil: nextIntervalKey = "30d"
            }
        default:
            nextIntervalKey = "1d"
        }

        guard let daysToAdd = Int(nextIntervalKey.replacingOccurrences(of: "d", with: "")) else { return }
        let newReviewDate = Calendar.current.date(byAdding: .day, value: daysToAdd, to: Date())!
        
        struct NewReview: Encodable {
            let userId: UUID, sessionId: UUID, subjectId: UUID, reviewDate: Date, reviewInterval: String
            enum CodingKeys: String, CodingKey {
                case userId = "user_id", sessionId = "session_id", subjectId = "subject_id",
                     reviewDate = "review_date", reviewInterval = "review_interval"
            }
        }
        
        let nextReview = NewReview(userId: previousReview.userId, sessionId: previousReview.sessionId, subjectId: previousReview.subjectId, reviewDate: newReviewDate, reviewInterval: nextIntervalKey)
        
        do {
            try await SupabaseManager.shared.client.from("reviews").insert(nextReview).execute()
        } catch {
            print("❌ Erro ao agendar a próxima revisão: \(error.localizedDescription)")
        }
    }
}

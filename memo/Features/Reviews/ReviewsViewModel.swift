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
            self.errorMessage = "Erro ao buscar revisões: \(error.localizedDescription)\n\nVerifique se a função 'get_pending_reviews_with_details' foi criada corretamente no seu banco de dados Supabase."
        }
        
        isLoading = false
    }
    
    func startCompletionFlow(for detail: ReviewDetail) {
        self.reviewToComplete = detail
        self.showingDifficultySelector = true
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
                
                // --- CHAMADA DIRETA PARA O VIEWMODEL COMPARTILHADO ---
                await HomeViewModel.shared.userDidCompleteAction()

            } catch {
                print("Erro ao completar revisão: \(error.localizedDescription)")
                await fetchData()
            }
        }
        
        self.reviewToComplete = nil
    }
    
    private func scheduleNextReview(for previousReview: Review, basedOn difficulty: ReviewDifficulty) async {
        let cycle = ["1d", "7d", "30d", "90d"]
        guard let currentIndex = cycle.firstIndex(of: previousReview.reviewInterval) else {
            print("Intervalo de revisão atual ('\(previousReview.reviewInterval)') não encontrado no ciclo de revisão.")
            return
        }
        
        var nextIndex = currentIndex
        switch difficulty {
        case .facil:
            nextIndex += 1
        case .medio:
            nextIndex += 0
        case .dificil:
            nextIndex = max(0, currentIndex - 1)
        }

        guard cycle.indices.contains(nextIndex) else {
            print("Fim do ciclo de revisões para esta sessão.")
            return
        }

        let nextIntervalKey = cycle[nextIndex]
        let daysToAdd = Int(nextIntervalKey.replacingOccurrences(of: "d", with: "")) ?? 1
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
        } catch {
            print("Erro ao agendar a próxima revisão: \(error.localizedDescription)")
        }
    }
}

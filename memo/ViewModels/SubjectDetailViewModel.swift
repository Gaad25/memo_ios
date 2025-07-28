//
//  SubjectDetailViewModel.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 26/05/25.
//

import Foundation

@MainActor
final class SubjectDetailViewModel: ObservableObject {
    @Published var sessions: [StudySession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchSessions(for subjectId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedSessions: [StudySession] = try await SupabaseManager.shared.client
                .from("study_sessions")
                .select()
                .eq("subject_id", value: subjectId) // Filtra as sessões para a matéria específica
                .order("start_time", ascending: false) // Ordena da mais recente para a mais antiga
                .execute()
                .value

            self.sessions = fetchedSessions
        } catch {
            self.errorMessage = "Erro ao buscar sessões: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

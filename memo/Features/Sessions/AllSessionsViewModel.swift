//
//  AllSessionsViewModel.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 13/07/25.
//
// memo/Features/Sessions/AllSessionsViewModel.swift

import Foundation
import Combine

@MainActor
final class AllSessionsViewModel: ObservableObject {
    @Published var sessions: [StudySession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var subjects: [Subject] = []
    
    @Published var selectedSubjectId: UUID? = nil {
        didSet {
            // Ao mudar o filtro, busca apenas a lista de sessões novamente.
            Task { await self.refreshSessions() }
        }
    }
    @Published var sortOption: SortOption = .dateDescending {
        didSet {
            sortSessions()
        }
    }

    enum SortOption {
        case dateDescending, dateAscending, durationDescending, durationAscending
    }

    // CORREÇÃO: Refatorado para buscar dados em paralelo e tratar os resultados.
    func fetchAllData() async {
        isLoading = true
        errorMessage = nil
        do {
            // Inicia as duas buscas em paralelo.
            async let subjectsTask = fetchSubjects()
            async let sessionsTask = fetchSessions()

            // Aguarda a conclusão de ambas e atribui os resultados.
            let (fetchedSubjects, fetchedSessions) = try await (subjectsTask, sessionsTask)

            self.subjects = fetchedSubjects
            self.sessions = fetchedSessions
            sortSessions()
        } catch {
            self.errorMessage = "Erro ao buscar dados: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // Função para atualizar apenas as sessões (usada pelo filtro).
    func refreshSessions() async {
        isLoading = true
        errorMessage = nil
        do {
            self.sessions = try await fetchSessions()
            sortSessions()
        } catch {
            self.errorMessage = "Não foi possível atualizar as sessões."
            print("❌ Erro em refreshSessions (AllSessionsViewModel): \(error.localizedDescription)")
        }
        isLoading = false
    }

    // CORREÇÃO: Agora retorna [StudySession] e pode lançar um erro.
    private func fetchSessions() async throws -> [StudySession] {
        var query = SupabaseManager.shared.client
            .from("study_sessions")
            .select()

        if let subjectId = selectedSubjectId {
            query = query.eq("subject_id", value: subjectId)
        }

        // CORREÇÃO: A variável foi alterada para 'let' e o valor é retornado.
        let fetchedSessions: [StudySession] = try await query
            .execute()
            .value

        return fetchedSessions
    }

    // CORREÇÃO: Agora retorna [Subject] e pode lançar um erro.
    private func fetchSubjects() async throws -> [Subject] {
         let fetchedSubjects: [Subject] = try await SupabaseManager.shared.client
             .from("subjects")
             .select()
             .execute()
             .value
         return fetchedSubjects
     }

    private func sortSessions() {
        switch sortOption {
        case .dateDescending:
            sessions.sort { $0.startTime > $1.startTime }
        case .dateAscending:
            sessions.sort { $0.startTime < $1.startTime }
        case .durationDescending:
            sessions.sort { $0.durationMinutes > $1.durationMinutes }
        case .durationAscending:
            sessions.sort { $0.durationMinutes < $1.durationMinutes }
        }
    }

    func deleteSession(at offsets: IndexSet) {
        let sessionsToDelete = offsets.map { sessions[$0] }
        sessions.remove(atOffsets: offsets)

        Task {
            for session in sessionsToDelete {
                do {
                    try await SupabaseManager.shared.client
                        .from("study_sessions")
                        .delete()
                        .eq("id", value: session.id)
                        .execute()
                } catch {
                    print("Erro ao deletar sessão: \(error.localizedDescription)")
                    await refreshSessions()
                }
            }
        }
    }
}

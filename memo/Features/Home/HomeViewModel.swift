import SwiftUI
import Combine

// --- Modelo da View para Metas ---
struct StudyGoalViewData: Identifiable, Equatable {
    let id: UUID
    let title: String
    let completedMinutes: Int
    let targetMinutes: Int
    let deadline: Date
    let subjectName: String?
    
    var progress: Double {
        guard targetMinutes > 0 else { return 0 }
        let calculatedProgress = Double(completedMinutes) / Double(targetMinutes)
        return min(1.0, calculatedProgress)
    }
}

// MARK: - ViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    static let shared = HomeViewModel()
    
    @Published var totalStudyMinutes: Int = 0
    @Published var recentStudyMinutes: Int = 0
    @Published var subjects: [Subject] = []
    @Published var goals: [StudyGoalViewData] = []
    @Published var userPoints: Int = 0
    @Published var userStreak: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private init() {}
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Bom dia"
        case 12..<18: return "Boa tarde"
        default:      return "Boa noite"
        }
    }
    
    func formatted(hoursAndMinutes totalMinutes: Int) -> String {
        "\(totalMinutes / 60)h \(totalMinutes % 60)m"
    }

    func refreshAllDashboardData() async {
        self.isLoading = true
        self.errorMessage = nil

        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            async let profileTask: UserProfile? = try? SupabaseManager.shared.client
                .from("user_profiles").select().eq("id", value: userId).single().execute().value

            async let subjectsTask: [Subject] = try SupabaseManager.shared.client
                .from("subjects").select().eq("user_id", value: userId).order("name", ascending: true).execute().value

            async let sessionsTask: [StudySession] = try SupabaseManager.shared.client
                .from("study_sessions").select().eq("user_id", value: userId).execute().value

            async let goalsTask: [Goal] = try SupabaseManager.shared.client
                .from("goals").select().eq("user_id", value: userId).eq("completed", value: false).execute().value

            let (profile, subjects, sessions, goals) = try await (profileTask, subjectsTask, sessionsTask, goalsTask)
            if let profile = profile {
                self.userPoints = profile.points
                self.userStreak = profile.currentStreak
            }

            self.subjects = subjects
            processDashboardSummary(from: sessions)
            processGoals(goals: goals, sessions: sessions, subjects: subjects)

        } catch {
            self.errorMessage = "Falha ao carregar dados."
            print("❌ ERRO em refreshAllDashboardData: \(error)")
        }

        self.isLoading = false
    }

    func userDidCompleteAction() async {
        print("--- 🏁 Iniciando userDidCompleteAction ---")
        
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            // 1. Garante que o perfil do usuário existe
            try await SupabaseManager.shared.client.rpc("ensure_user_profile_exists").execute()
            
            // 2. Busca o perfil atual para obter os valores a serem incrementados
            let profile: UserProfile = try await SupabaseManager.shared.client
                .from("user_profiles").select().eq("id", value: userId).single().execute().value
            
            // 3. Calcula os novos valores
            let newPoints = profile.points + 10
            var newStreak = profile.currentStreak
            if let lastStudyDate = profile.lastStudyDate {
                if Calendar.current.isDateInYesterday(lastStudyDate) {
                    newStreak += 1
                } else if !Calendar.current.isDateInToday(lastStudyDate) {
                    newStreak = 1
                }
            } else {
                newStreak = 1
            }
            
            // --- INÍCIO DA CORREÇÃO FINAL (Análise do seu amigo) ---
            // 4. Cria a struct para a atualização
            struct ProfileUpdate: Encodable {
                let points: Int
                let current_streak: Int
                let last_study_date: Date
            }
            
            let updates = ProfileUpdate(
                points: newPoints,
                current_streak: newStreak,
                last_study_date: Date()
            )
            
            // 5. Executa o UPDATE sem pedir o resultado de volta.
            //    Isto evita o erro "PGRST116" se nenhuma linha for afetada.
            try await SupabaseManager.shared.client
                .from("user_profiles")
                .update(updates)
                .eq("id", value: userId)
                .execute() // Apenas executa, sem .select() ou .single()
            
            print("✅ Operação de UPDATE enviada ao Supabase.")
            // --- FIM DA CORREÇÃO FINAL ---
                
            // 6. Recarrega todos os dados do dashboard para a UI refletir as mudanças
            print("6. Recarregando todos os dados do dashboard...")
            await refreshAllDashboardData()
            print("--- ✅ Processo userDidCompleteAction concluído! ---")

        } catch {
            print("❌ ERRO CRÍTICO em userDidCompleteAction: \(error)")
            await MainActor.run {
                self.errorMessage = "Não foi possível salvar o seu progresso."
                self.isLoading = false
            }
        }
    }

    /// Updates the user's points and streak after a study-related action.
    /// This follows the rules:
    ///   - if the last study was yesterday, increment the streak
    ///   - if the last study was today, keep the streak as is
    ///   - if the last study was before yesterday, reset the streak to 1
    ///   - if the user has never studied, start the streak at 1
    func updateGamificationData() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            // Ensure the user profile exists before attempting to update it
            try await SupabaseManager.shared.client.rpc("ensure_user_profile_exists").execute()

            var profile: UserProfile = try await SupabaseManager.shared.client
                .from("user_profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            let today = Calendar.current.startOfDay(for: Date())

            if let lastStudy = profile.lastStudyDate {
                if Calendar.current.isDateInYesterday(lastStudy) {
                    profile.currentStreak += 1
                } else if !Calendar.current.isDateInToday(lastStudy) {
                    profile.currentStreak = 1
                }
            } else {
                profile.currentStreak = 1
            }

            profile.lastStudyDate = today
            profile.points += 10

            struct ProfileUpdate: Encodable {
                let points: Int
                let current_streak: Int
                let last_study_date: Date
            }

            let updates = ProfileUpdate(
                points: profile.points,
                current_streak: profile.currentStreak,
                last_study_date: today
            )

            try await SupabaseManager.shared.client
                .from("user_profiles")
                .update(updates)
                .eq("id", value: userId)
                .execute()

            self.userPoints = profile.points
            self.userStreak = profile.currentStreak

        } catch {
            print("❌ Error updating gamification: \(error.localizedDescription)")
        }
    }

    private func processDashboardSummary(from sessions: [StudySession]?) {
        guard let sessions = sessions else { return }
        totalStudyMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        recentStudyMinutes = sessions.filter { $0.startTime >= sevenDaysAgo }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private func processGoals(goals: [Goal], sessions: [StudySession], subjects: [Subject]) {
        self.goals = goals.map { goal in
            let targetMins = Int(goal.targetHours * 60)
            let completedMins: Int
            if let subjectId = goal.subjectId {
                completedMins = sessions.filter { $0.subjectId == subjectId }.reduce(0) { $0 + $1.durationMinutes }
            } else {
                completedMins = sessions.reduce(0) { $0 + $1.durationMinutes }
            }
            let subjectName = subjects.first { $0.id == goal.subjectId }?.name
            return StudyGoalViewData(id: goal.id, title: goal.title, completedMinutes: completedMins, targetMinutes: targetMins, deadline: goal.endDate, subjectName: subjectName)
        }
    }
    
        func deleteSubject(_ subjectToDelete: Subject) {
            // Remove da UI primeiro para uma resposta rápida
            subjects.removeAll { $0.id == subjectToDelete.id }
            
            Task {
                do {
                    try await SupabaseManager.shared.client
                        .from("subjects")
                        .delete()
                        .eq("id", value: subjectToDelete.id) // Usamos o ID do objeto
                        .execute()
                } catch {
                    print("❌ Erro ao apagar matéria: \(error.localizedDescription)")
                    // Se der erro, recarrega tudo para garantir consistência
                    await refreshAllDashboardData()
                }
            }
        }
        
        func deleteGoal(_ goalToDelete: StudyGoalViewData) {
            // Remove da UI primeiro
            goals.removeAll { $0.id == goalToDelete.id }

            Task {
                do {
                    try await SupabaseManager.shared.client
                        .from("goals")
                        .delete()
                        .eq("id", value: goalToDelete.id) // Usamos o ID do objeto
                        .execute()
                } catch {
                    print("❌ Erro ao apagar meta: \(error.localizedDescription)")
                    await refreshAllDashboardData()
                }
            }
        }
    }

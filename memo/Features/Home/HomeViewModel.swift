import SwiftUI
import Combine

// --- Modelo da View para Metas ---
struct StudyGoalViewData: Identifiable {
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
    
    func deleteSubject(at offsets: IndexSet) {
        let subjectsToDelete = offsets.map { self.subjects[$0] }
        let subjectIdsToDelete = subjectsToDelete.map { $0.id.uuidString }
        
        self.subjects.remove(atOffsets: offsets)
        
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("subjects")
                    .delete()
                    .in("id", values: subjectIdsToDelete)
                    .execute()
            } catch {
                print("❌ Erro ao apagar matéria: \(error.localizedDescription)")
                await refreshAllDashboardData()
            }
        }
    }
    
    func deleteGoal(at offsets: IndexSet) {
        let goalsToDelete = offsets.map { self.goals[$0] }
        let goalIdsToDelete = goalsToDelete.map { $0.id.uuidString }

        self.goals.remove(atOffsets: offsets)

        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("goals")
                    .delete()
                    .in("id", values: goalIdsToDelete)
                    .execute()
            } catch {
                print("❌ Erro ao apagar meta: \(error.localizedDescription)")
                await refreshAllDashboardData()
            }
        }
    }
}
    // MARK: - Views
    struct HomeView: View {
        // Usa a instância compartilhada do ViewModel
        @StateObject private var viewModel = HomeViewModel.shared
        @State private var isAddingSubject = false
        @State private var isAddingGoal = false
        
        var body: some View {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        Text(viewModel.greeting)
                            .font(.largeTitle.bold())
                            .padding(.top)
                        
                        SummaryCard(
                            total: viewModel.formatted(hoursAndMinutes: viewModel.totalStudyMinutes),
                            activeGoals: viewModel.goals.count,
                            recent: viewModel.formatted(hoursAndMinutes: viewModel.recentStudyMinutes),
                            points: viewModel.userPoints,
                            streak: viewModel.userStreak,
                            onRefresh: {
                                Task {
                                    await viewModel.refreshAllDashboardData()
                                }
                            }
                        )
                        
                        SectionHeader(title: "Matérias") { isAddingSubject = true }
                        
                        if viewModel.isLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else if viewModel.subjects.isEmpty {
                            Text("Nenhuma matéria cadastrada.").font(.subheadline).foregroundColor(.secondary).padding().frame(maxWidth: .infinity).background(CardBackground())
                        } else {
                            List {
                                ForEach(viewModel.subjects) { subject in
                                    NavigationLink(destination: SubjectDetailView(subject: subject, onSubjectUpdated: {
                                        Task { await viewModel.refreshAllDashboardData() }
                                    })) {
                                        SubjectRow(subject: subject)
                                    }
                                }
                                .onDelete(perform: viewModel.deleteSubject)
                            }
                            .listStyle(.plain).frame(height: CGFloat(viewModel.subjects.count) * 65).background(CardBackground())
                        }
                        
                        SectionHeader(title: "Metas de Estudo") { isAddingGoal = true }
                        
                        if viewModel.goals.isEmpty && !viewModel.isLoading {
                            Text("Nenhuma meta ativa.").font(.subheadline).foregroundColor(.secondary).padding().frame(maxWidth: .infinity).background(CardBackground())
                        } else {
                            List {
                                ForEach(viewModel.goals) { goal in
                                    GoalCard(goal: goal).listRowInsets(EdgeInsets()).listRowSeparator(.hidden)
                                }
                                .onDelete(perform: viewModel.deleteGoal)
                            }
                            .listStyle(.plain).frame(height: CGFloat(viewModel.goals.count) * 110).scrollDisabled(true).background(CardBackground())
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationBarHidden(true)
                .onAppear { Task { await viewModel.refreshAllDashboardData() } }
                .sheet(isPresented: $isAddingSubject) { AddSubjectView(subjectToEdit: nil, onDone: { Task { await viewModel.refreshAllDashboardData() } }) }
                .sheet(isPresented: $isAddingGoal) { AddGoalView(subjects: viewModel.subjects) { Task { await viewModel.refreshAllDashboardData() } } }
            }
        }
    }
    
    // MARK: - Components
    private struct GoalCard: View {
        let goal: StudyGoalViewData
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(goal.title).fontWeight(.semibold)
                if let subjectName = goal.subjectName { Text(subjectName).font(.caption).foregroundColor(.secondary) }
                ProgressView(value: goal.progress).progressViewStyle(.linear)
                HStack {
                    Text("\(goal.completedMinutes / 60)h \(goal.completedMinutes % 60)m de \(goal.targetMinutes / 60)h").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("Prazo: \(goal.deadline.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundColor(.secondary)
                }
            }
            .padding().background(CardBackground())
        }
    }
    
    private struct SectionHeader: View {
        let title: String
        var action: () -> Void
        var body: some View {
            HStack {
                Text(title).font(.title3.bold())
                Spacer()
                Button("+ NOVA \(title.uppercased().split(separator: " ").first ?? "")", action: action).font(.callout.weight(.semibold))
            }
        }
    }
    
    private struct SubjectRow: View {
        let subject: Subject
        var body: some View {
            HStack(spacing: 16) {
                Circle().fill(subject.swiftUIColor).frame(width: 16, height: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text(subject.name).fontWeight(.semibold)
                    Text(subject.category).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 12).padding(.horizontal, 16).contentShape(Rectangle())
        }
    }
    
    private struct SummaryCard: View {
        let total: String, activeGoals: Int, recent: String, points: Int, streak: Int
        var onRefresh: () -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text("\(points)").font(.system(.headline, design: .rounded).bold())
                        Text("Pontos").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").foregroundColor(.orange)
                        Text("\(streak)").font(.system(.headline, design: .rounded).bold())
                        Text(streak == 1 ? "Dia" : "Dias").font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 8)
                Divider()
                VStack(spacing: 6) {
                    Text(total).font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Tempo Total de Estudo").font(.caption).foregroundColor(.secondary)
                }
                Button(action: onRefresh) {
                    Label("Atualizar Dados", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 4) { Text("\(activeGoals) Metas Ativas").fontWeight(.semibold) }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(recent).fontWeight(.semibold)
                        Text("Progresso Recente").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .padding().background(CardBackground())
        }
    }
    
    private struct CardBackground: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.secondary.opacity(0.1)))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }
    
    // MARK: - Preview
    struct HomeView_Previews: PreviewProvider {
        static var previews: some View {
            HomeView()
        }
    }


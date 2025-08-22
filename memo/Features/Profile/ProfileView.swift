import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var homeViewModel = HomeViewModel.shared
    @State private var showingSettings = false
    @State private var showingFriends = false
    @State private var showingDisplayNameEditor = false
    @State private var showingFirstTimeDisplayName = false
    @State private var isLoading = true
    @State private var totalQuestions = 0
    @State private var aiQuestions = 0
    @State private var friendsCount = 0
    
    // Computed property para exibir o recorde semanal
    private var displayMaxWeeklyPoints: Int {
        guard let profile = session.userProfile else { return 0 }
        return max(profile.maxWeeklyPoints, profile.weeklyPoints)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header com configurações
                    headerView
                    
                    if isLoading {
                        loadingView
                    } else {
                        // Avatar e nome
                        profileHeader
                        
                        // Estatísticas principais em destaque
                        mainStatsSection
                        
                        // Link para estatísticas completas
                        statisticsNavigationSection
                        
                        // Lista detalhada de estatísticas
                        detailedStatsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView().environmentObject(session)
            }
            .sheet(isPresented: $showingFriends) {
                FriendsView()
            }
            .sheet(isPresented: $showingDisplayNameEditor) {
                if let profile = session.userProfile {
                    DisplayNameEditorView(
                        displayName: .constant(profile.displayName ?? ""),
                        isFirstTime: false,
                        onSave: { newName in
                            let result = await session.updateDisplayName(newName)
                            return result.map { _ in () }
                        },
                        onCancel: {
                            showingDisplayNameEditor = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingFirstTimeDisplayName) {
                if let profile = session.userProfile {
                    DisplayNameEditorView(
                        displayName: .constant(profile.displayName ?? ""),
                        isFirstTime: true,
                        onSave: { newName in
                            let result = await session.updateDisplayName(newName)
                            return result.map { _ in () }
                        },
                        onCancel: {
                            showingFirstTimeDisplayName = false
                        }
                    )
                }
            }
            .task {
                await loadProfileData()
            }
            .refreshable {
                await loadProfileData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            Text("Meu Perfil")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Carregando perfil...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            if let profile = session.userProfile {
                ProfileAvatarView(selectedAvatar: .constant(profile.selectedAvatar))
            } else {
                ProfileAvatarView(selectedAvatar: .constant("zoe_default"))
            }
            
            // Nome do utilizador
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(displayNameText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingDisplayNameEditor = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color.dsPrimary)
                    }
                }
                
                if let objective = session.userProfile?.studyObjective {
                    Text("Objetivo: \(objective)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var mainStatsSection: some View {
        VStack(spacing: 16) {
            // Primeira linha: Pontos da semana e Streak
            HStack(spacing: 16) {
                MainStatCard(
                    title: "Pontos da Semana",
                    value: "\(session.userProfile?.weeklyPoints ?? 0)",
                    icon: "star.fill",
                    color: .yellow
                )
                
                MainStatCard(
                    title: "Streak Atual",
                    value: "\(homeViewModel.userStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            
            // Segunda linha: Botão dos amigos (largura completa)
            Button(action: {
                showingFriends = true
            }) {
                FriendsCard(friendsCount: friendsCount)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var statisticsNavigationSection: some View {
        NavigationLink(destination: StatisticsView()) {
            StatisticsNavigationCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Estatísticas Detalhadas")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                StatRow(
                    title: "Tempo Total de Estudo",
                    value: homeViewModel.formatted(hoursAndMinutes: homeViewModel.totalStudyMinutes),
                    icon: "clock.fill",
                    iconColor: .blue
                )
                
                StatRow(
                    title: "Total de Questões Feitas",
                    value: "\(totalQuestions)",
                    icon: "questionmark.circle.fill",
                    iconColor: .green
                )
                
                StatRow(
                    title: "Streak Máxima",
                    value: "\(session.userProfile?.maxStreak ?? 0) dias",
                    icon: "trophy.fill",
                    iconColor: .orange
                )
                
                StatRow(
                    title: "Recorde de Pontos na Semana",
                    value: "\(displayMaxWeeklyPoints)",
                    icon: "crown.fill",
                    iconColor: .yellow
                )
                
                StatRow(
                    title: "Questões Resolvidas com a Zoe",
                    value: "\(aiQuestions)",
                    icon: "brain.head.profile",
                    iconColor: .purple
                )
                
                StatRow(
                    title: "Pontos Totais",
                    value: "\(session.userProfile?.points ?? 0)",
                    icon: "star.circle.fill",
                    iconColor: .indigo
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadProfileData() async {
        isLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            // Carregar perfil do utilizador
            group.addTask {
                await session.loadUserProfile()
            }
            
            // Carregar estatísticas de questões
            group.addTask {
                await loadQuestionStats()
            }
            
            // Refresh dos dados do home
            group.addTask {
                await homeViewModel.refreshAllDashboardData()
            }
            
            // Carregar número de amigos
            group.addTask {
                await loadFriendsCount()
            }
        }
        
        // Verificar se é primeira vez (sem displayName) após carregar
        if let profile = session.userProfile, 
           profile.displayName == nil || profile.displayName?.isEmpty == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showingFirstTimeDisplayName = true
            }
        }
        
        isLoading = false
    }
    
    private func loadQuestionStats() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            // Contar total de sessões (aproximação para questões)
            let sessions: [StudySession] = try await SupabaseManager.shared.client
                .from("study_sessions")
                .select("*")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            // Contar reviews (questões de revisão)
            let reviews: [Review] = try await SupabaseManager.shared.client
                .from("reviews")
                .select("*")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            await MainActor.run {
                // Estimativa: cada sessão = ~10 questões + reviews
                self.totalQuestions = (sessions.count * 10) + reviews.count
                // Para AI questions, podemos usar uma estimativa baseada em sessões recentes
                self.aiQuestions = sessions.filter { 
                    Calendar.current.isDate($0.startTime, inSameDayAs: Date()) 
                }.count * 5
            }
        } catch {
            print("❌ Erro ao carregar estatísticas de questões: \(error)")
        }
    }
    
    // MARK: - Display Name Management
    
    private var displayNameText: String {
        if let displayName = session.userProfile?.displayName, !displayName.isEmpty {
            return displayName
        }
        return "Definir Nome"
    }
    
    private func loadFriendsCount() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            let friendships: [Friendship] = try await SupabaseManager.shared.client
                .from("friendships")
                .select("*")
                .eq("status", value: "accepted")
                .or("user_id_1.eq.\(userId),user_id_2.eq.\(userId)")
                .execute()
                .value
            
            await MainActor.run {
                self.friendsCount = friendships.count
            }
            
        } catch {
            print("❌ Erro ao carregar contagem de amigos: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct MainStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(iconColor)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Friends Card Component

struct FriendsCard: View {
    let friendsCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Ícone de amigos
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person.2.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            // Informações dos amigos
            VStack(alignment: .leading, spacing: 2) {
                Text("Meus Amigos")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(friendsCount) amigo\(friendsCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Seta
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Statistics Navigation Card Component

struct StatisticsNavigationCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // Ícone de estatísticas
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            // Informações das estatísticas
            VStack(alignment: .leading, spacing: 4) {
                Text("Minhas Estatísticas")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Visualize gráficos e tendências detalhadas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Seta de navegação
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color.green.opacity(0.1),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Functions

}

#Preview {
    ProfileView()
        .environmentObject(SessionManager())
}

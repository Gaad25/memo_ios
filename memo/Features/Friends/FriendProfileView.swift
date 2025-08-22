import SwiftUI

struct FriendProfileView: View {
    let friend: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var friendStats: FriendStats?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    if isLoading {
                        loadingView
                    } else {
                        // Stats Comparison
                        statsComparisonSection
                        
                        // Detailed Stats
                        detailedStatsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(friend.displayName ?? "Amigo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadFriendStats()
            }
        }
    }
    
    // MARK: - View Components
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.dsPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                avatarImage
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            }
            
            // Name and objective
            VStack(spacing: 8) {
                Text(friend.displayName ?? "Amigo")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let objective = friend.studyObjective {
                    Text("Objetivo: \(objective)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 20)
    }
    
    private var avatarImage: some View {
        Group {
            if friend.selectedAvatar == "zoe_default" {
                Image("ZoeAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: symbolFor(avatarId: friend.selectedAvatar))
                    .font(.system(size: 40))
                    .foregroundColor(Color.dsPrimary)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Carregando estatísticas...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var statsComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparação Semanal")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ComparisonCard(
                    title: "Pontos da Semana",
                    friendValue: friend.weeklyPoints,
                    myValue: friendStats?.myWeeklyPoints ?? 0,
                    icon: "star.fill",
                    color: .yellow
                )
                
                ComparisonCard(
                    title: "Streak Atual",
                    friendValue: friend.currentStreak,
                    myValue: friendStats?.myCurrentStreak ?? 0,
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
    }
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Estatísticas do Amigo")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                FriendStatRow(
                    title: "Pontos Totais",
                    value: "\(friend.points)",
                    icon: "star.circle.fill",
                    iconColor: .indigo
                )
                
                FriendStatRow(
                    title: "Streak Máxima",
                    value: "\(friend.maxStreak) dias",
                    icon: "trophy.fill",
                    iconColor: .orange
                )
                
                FriendStatRow(
                    title: "Recorde Semanal",
                    value: "\(friend.maxWeeklyPoints) pontos",
                    icon: "crown.fill",
                    iconColor: .yellow
                )
                
                if let stats = friendStats {
                    FriendStatRow(
                        title: "Tempo Total de Estudo",
                        value: formatMinutes(stats.totalStudyMinutes),
                        icon: "clock.fill",
                        iconColor: .blue
                    )
                    
                    FriendStatRow(
                        title: "Sessões Completadas",
                        value: "\(stats.totalSessions)",
                        icon: "checkmark.circle.fill",
                        iconColor: .green
                    )
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadFriendStats() async {
        do {
            // Carregar estatísticas do usuário atual para comparação
            let currentUserId = try await SupabaseManager.shared.client.auth.session.user.id
            let currentUserProfile: [UserProfile] = try await SupabaseManager.shared.client
                .from("user_profiles")
                .select("*")
                .eq("id", value: currentUserId)
                .execute()
                .value
            
            // Carregar sessões de estudo do amigo para calcular estatísticas adicionais
            let friendSessions: [StudySession] = try await SupabaseManager.shared.client
                .from("study_sessions")
                .select("*")
                .eq("user_id", value: friend.id)
                .execute()
                .value
            
            let totalMinutes = friendSessions.reduce(0) { $0 + $1.durationMinutes }
            
            await MainActor.run {
                self.friendStats = FriendStats(
                    myWeeklyPoints: currentUserProfile.first?.weeklyPoints ?? 0,
                    myCurrentStreak: currentUserProfile.first?.currentStreak ?? 0,
                    totalStudyMinutes: totalMinutes,
                    totalSessions: friendSessions.count
                )
                self.isLoading = false
            }
            
        } catch {
            print("❌ Erro ao carregar estatísticas do amigo: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func symbolFor(avatarId: String) -> String {
        switch avatarId {
        case "zoe_studying":
            return "book.fill"
        case "zoe_reading":
            return "eyeglasses"
        case "zoe_celebrating":
            return "star.fill"
        case "zoe_thinking":
            return "brain.head.profile"
        default:
            return "person.fill"
        }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
}

// MARK: - Supporting Models

struct FriendStats {
    let myWeeklyPoints: Int
    let myCurrentStreak: Int
    let totalStudyMinutes: Int
    let totalSessions: Int
}

// MARK: - Supporting Views

struct ComparisonCard: View {
    let title: String
    let friendValue: Int
    let myValue: Int
    let icon: String
    let color: Color
    
    var isWinning: Bool {
        return myValue > friendValue
    }
    
    var isTied: Bool {
        return myValue == friendValue
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 4) {
                // Friend's value
                HStack(spacing: 4) {
                    Text("Amigo:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(friendValue)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isWinning ? .secondary : color)
                }
                
                // My value with comparison indicator
                HStack(spacing: 4) {
                    Text("Você:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(myValue)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isWinning ? color : .secondary)
                    
                    if !isTied {
                        Image(systemName: isWinning ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundColor(isWinning ? .green : .red)
                    } else {
                        Image(systemName: "equal.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct FriendStatRow: View {
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

#Preview {
    FriendProfileView(
        friend: UserProfile(
            id: UUID(),
            points: 1250,
            currentStreak: 7,
            lastStudyDate: Date(),
            studyObjective: "ENEM 2024",
            weeklyPoints: 320,
            maxStreak: 15,
            maxWeeklyPoints: 450,
            selectedAvatar: "zoe_default",
            displayName: "João Silva"
        )
    )
}

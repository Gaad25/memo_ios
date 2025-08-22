import SwiftUI

struct RankingView: View {
    @StateObject private var viewModel = RankingViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header com informações da semana
                    competitionWeeklyCard
                    
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.ranking.isEmpty {
                        // Estado vazio para nenhum participante
                        emptyStateView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    } else {
                        // Card pessoal do utilizador atual
                        currentUserCard
                        
                        // Podium para top 3
                        if viewModel.ranking.count >= 3 {
                            podiumSection
                        }
                        
                        // Lista completa do ranking
                        rankingListSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Ranking da Semana")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.fetchRankingIfNeeded()
            }
            .refreshable {
                await viewModel.refreshRanking()
            }
        }
    }
    
    // MARK: - View Components
    
    private var competitionWeeklyCard: some View {
        VStack(spacing: 16) {
            // Título da competição
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Competição Semanal")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Ranking atualizado em tempo real")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color(.separator))
            
            // Informações do período e reset
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text("Período: \(weekPeriodText)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Text("Os pontos são zerados todo domingo à meia-noite")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        }
        .modifier(CardBackgroundModifier())
    }
    
    private var currentUserCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color.dsPrimary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sua Posição")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let profile = viewModel.currentUserProfile,
                       let displayName = profile.displayName, !displayName.isEmpty {
                        Text("Olá, \(displayName)!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Defina o seu nome no Perfil para aparecer no ranking!")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color(.separator))
            
            HStack {
                // Posição
                VStack(alignment: .leading, spacing: 4) {
                    Text("Posição")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let position = viewModel.currentUserPosition {
                        Text("#\(position)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.dsPrimary)
                    } else {
                        Text("--")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Pontos
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Pontos da Semana")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.currentUserWeeklyPoints)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.dsPrimary)
                }
            }
            
            // Mensagem motivacional
            if viewModel.currentUserWeeklyPoints == 0 {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Text("Complete uma sessão de estudo para ganhar pontos!")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
        }
        .modifier(CardBackgroundModifier())
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Carregando ranking...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var podiumSection: some View {
        VStack(spacing: 16) {
            Text("Pódium da Semana")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .bottom, spacing: 8) {
                // 2º lugar
                if viewModel.ranking.count >= 2 {
                    podiumPlace(user: viewModel.ranking[1], position: 2, height: 80)
                }
                
                // 1º lugar (mais alto)
                podiumPlace(user: viewModel.ranking[0], position: 1, height: 100)
                
                // 3º lugar
                if viewModel.ranking.count >= 3 {
                    podiumPlace(user: viewModel.ranking[2], position: 3, height: 60)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var rankingListSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Classificação Completa")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(viewModel.ranking.count) participantes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array(viewModel.ranking.enumerated()), id: \.element.id) { index, user in
                    if index == 0 {
                        // Primeiro lugar com destaque especial
                        RankingRowView(
                            user: user,
                            position: index + 1,
                            isCurrentUser: user.id == viewModel.currentUserId,
                            viewModel: viewModel
                        )
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.15),
                                    Color.orange.opacity(0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.4), lineWidth: 2)
                        )
                    } else {
                        // Outros lugares com estilo normal
                        RankingRowView(
                            user: user,
                            position: index + 1,
                            isCurrentUser: user.id == viewModel.currentUserId,
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
    }
    
    private var currentUserPositionSection: some View {
        Group {
            if let position = viewModel.currentUserPosition, position > 10 {
                VStack(spacing: 12) {
                    Divider()
                    
                    HStack {
                        Text("Sua Posição:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(position)º lugar")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.dsPrimary)
                    }
                    
                    Text("Continue estudando para subir no ranking!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(Color.dsPrimary.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Erro ao carregar ranking")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Tentar Novamente") {
                Task {
                    await viewModel.refreshRanking()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Ícone grande
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
                .padding(.top, 20)
            
            // Texto principal
            VStack(spacing: 8) {
                Text("O Pódium espera por si!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Convide os seus amigos para o Memo e comecem uma competição amigável.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Botão de convidar amigos
            Button(action: shareApp) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                    
                    Text("Convidar Amigos")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.dsPrimary, Color.dsPrimary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .modifier(CardBackgroundModifier())
    }
    
    // MARK: - Helper Views
    
    private func podiumPlace(user: RankedUser, position: Int, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(viewModel.colorForPosition(position).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                avatarImage(for: user.selectedAvatar)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                // Crown para o primeiro lugar
                if position == 1 {
                    VStack {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .offset(y: -25)
                        Spacer()
                    }
                }
            }
            
            // Nome
            Text(user.userName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Pontos
            Text("\(viewModel.formattedPoints(user.weeklyPoints))")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(viewModel.colorForPosition(position))
            
            // Pódium
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            viewModel.colorForPosition(position),
                            viewModel.colorForPosition(position).opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
                .cornerRadius(8, corners: [.topLeft, .topRight])
                .overlay(
                    Text(viewModel.emojiForPosition(position))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
        .frame(maxWidth: .infinity)
    }
    
    private func avatarImage(for avatarId: String) -> some View {
        Group {
            if avatarId == "zoe_default" {
                Image("ZoeAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: symbolFor(avatarId: avatarId))
                    .font(.system(size: 20))
                    .foregroundColor(Color.dsPrimary)
            }
        }
    }
    
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
    
    // MARK: - Helper Functions
    
    private func shareApp() {
        let text = "Descubra o Memo! 📚✨ O melhor app para estudar e competir com amigos. Baixe agora e vamos estudar juntos!"
        let items: [Any] = [text]
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Para iPad
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            activityViewController.popoverPresentationController?.sourceView = window
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            activityViewController.popoverPresentationController?.permittedArrowDirections = []
            
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    // MARK: - Computed Properties
    
    private var weekPeriodText: String {
        let calendar = Calendar.current
        let now = Date()
        
        // Encontrar o início da semana (domingo)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
}

// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    RankingView()
}

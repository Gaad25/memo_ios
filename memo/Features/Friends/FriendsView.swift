import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: FriendsTab = .friends
    @State private var showingAddFriend = false
    @State private var selectedFriend: UserProfile?
    
    enum FriendsTab: String, CaseIterable {
        case friends = "Meus Amigos"
        case pending = "Pedidos Pendentes"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                tabPickerSection
                
                // Content
                TabView(selection: $selectedTab) {
                    friendsListView
                        .tag(FriendsTab.friends)
                    
                    pendingRequestsView
                        .tag(FriendsTab.pending)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Amizades")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.refreshData()
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView()
            }
            .sheet(item: $selectedFriend) { friend in
                FriendProfileView(friend: friend)
            }
            .alert("Erro", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - View Components
    
    private var tabPickerSection: some View {
        HStack(spacing: 0) {
            ForEach(FriendsTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .medium)
                            
                            if tab == .pending && viewModel.getPendingCount() > 0 {
                                Text("\(viewModel.getPendingCount())")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                        }
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.dsPrimary : Color.clear)
                            .frame(height: 2)
                    }
                    .foregroundColor(selectedTab == tab ? Color.dsPrimary : .secondary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    private var friendsListView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.friends.isEmpty {
                emptyFriendsView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.friends) { friend in
                            FriendRowView(
                                friend: friend,
                                onTap: {
                                    selectedFriend = friend
                                },
                                onRemove: {
                                    Task {
                                        await viewModel.removeFriend(friend)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
    }
    
    private var pendingRequestsView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.pendingRequests.isEmpty {
                emptyPendingView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.pendingRequests) { request in
                            PendingRequestRowView(
                                request: request,
                                onAccept: {
                                    Task {
                                        await viewModel.acceptRequest(request)
                                    }
                                },
                                onDecline: {
                                    Task {
                                        await viewModel.declineRequest(request)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Carregando...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyFriendsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Nenhum amigo ainda")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Adicione amigos para comparar estatísticas e se motivar mutuamente!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingAddFriend = true
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Adicionar Primeiro Amigo")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding()
                .background(Color.dsPrimary)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyPendingView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Nenhum pedido pendente")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Quando alguém enviar um pedido de amizade, aparecerá aqui.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views

struct FriendRowView: View {
    let friend: UserProfile
    let onTap: () -> Void
    let onRemove: () -> Void
    
    @State private var showingRemoveAlert = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                avatarView
                
                // Friend Info
                friendInfoView
                
                Spacer()
                
                // Stats
                statsView
                
                // Menu
                menuButton
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Remover Amigo", isPresented: $showingRemoveAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Remover", role: .destructive) {
                onRemove()
            }
        } message: {
            Text("Tem certeza que deseja remover \(friend.displayName ?? "este amigo") da sua lista de amigos?")
        }
    }
    
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color.dsPrimary.opacity(0.1))
                .frame(width: 50, height: 50)
            
            avatarImage
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        }
    }
    
    private var avatarImage: some View {
        Group {
            if friend.selectedAvatar == "zoe_default" {
                Image("ZoeAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: symbolFor(avatarId: friend.selectedAvatar))
                    .font(.system(size: 20))
                    .foregroundColor(Color.dsPrimary)
            }
        }
    }
    
    private var friendInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(friend.displayName ?? "Amigo")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let objective = friend.studyObjective {
                Text(objective)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var statsView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text("\(friend.weeklyPoints)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("\(friend.currentStreak)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var menuButton: some View {
        Menu {
            Button(action: onTap) {
                Label("Ver Perfil", systemImage: "person.fill")
            }
            
            Button(role: .destructive, action: {
                showingRemoveAlert = true
            }) {
                Label("Remover Amigo", systemImage: "person.badge.minus")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
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
}

struct PendingRequestRowView: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            avatarView
            
            // Request Info
            requestInfoView
            
            Spacer()
            
            // Action Buttons
            actionButtons
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 50, height: 50)
            
            avatarImage
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        }
    }
    
    private var avatarImage: some View {
        Group {
            if let profile = request.senderProfile, profile.selectedAvatar == "zoe_default" {
                Image("ZoeAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: symbolFor(avatarId: request.senderProfile?.selectedAvatar ?? "person.fill"))
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var requestInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(request.senderProfile?.displayName ?? "Utilizador")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Quer ser seu amigo")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(timeAgoString(from: request.createdAt))
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button(action: onAccept) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                    Text("Aceitar")
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Button(action: onDecline) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                    Text("Recusar")
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
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
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "agora"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m atrás"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h atrás"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d atrás"
        }
    }
}

#Preview {
    FriendsView()
}

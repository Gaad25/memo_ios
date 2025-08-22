import SwiftUI

struct AddFriendView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var hasSearched: Bool = false

    // Alertas locais
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                headerSection
                searchSection
                resultsSection
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Adicionar Amigo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
            // Sucesso
            .alert("Sucesso", isPresented: $showingSuccessAlert) {
                Button("OK") {}
            } message: {
                Text(successMessage)
            }
            // Erro (binding reativo de verdade)
            .alert(
                "Erro",
                isPresented: Binding<Bool>(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.clearError() } }
                )
            ) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            // Se o VM emitir .error, propagamos para o alerta acima
            .onChange(of: viewModel.friendRequestState) { _, newState in
                if case .error(let msg) = newState {
                    viewModel.errorMessage = msg
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(Color.dsPrimary)

            Text("Encontre novos amigos")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Procure outros estudantes pelo nome de exibição e conecte-se para comparar estatísticas.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pesquisar Utilizador")
                .font(.headline)
                .fontWeight(.semibold)

            HStack {
                TextField("Digite o nome de exibição", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.search)
                    .onSubmit { performSearch() }

                Button(action: performSearch) {
                    HStack {
                        if viewModel.isSearching { ProgressView().scaleEffect(0.8) }
                        else { Image(systemName: "magnifyingglass") }
                    }
                    .frame(width: 44, height: 36)
                    .background(Color.dsPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSearching)
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.isSearching {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Procurando…")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            } else if hasSearched && viewModel.searchResults.isEmpty {
                Text("Nenhum resultado encontrado.")
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            } else if !viewModel.searchResults.isEmpty {
                HStack {
                    Text("Resultados da Pesquisa")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(viewModel.searchResults.count) encontrado(s)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.searchResults, id: \.id) { user in
                        UserSearchRow(
                            user: user,
                            isLoading: viewModel.sendingToUserId == user.id && (viewModel.friendRequestState == .loading),
                            onAddFriend: { Task { await addFriend(user) } }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Actions

    private func performSearch() {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        hasSearched = true
        Task { await viewModel.searchUsers(byName: term) }
    }

    private func addFriend(_ user: UserSearchResult) async {
        await viewModel.sendFriendRequest(to: user)
        await MainActor.run {
            if viewModel.errorMessage == nil {
                successMessage = "Pedido de amizade enviado para \((user.displayName ?? "usuário"))!"
                showingSuccessAlert = true
            }
        }
    }
}

// MARK: - Linha de resultado

struct UserSearchRow: View {
    let user: UserSearchResult
    let isLoading: Bool
    let onAddFriend: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            avatarView
            userInfoView
            Spacer()
            actionButton
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
            if user.selectedAvatar == "zoe_default" {
                Image("ZoeAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: symbolFor(avatarId: user.selectedAvatar))
                    .font(.system(size: 20))
                    .foregroundColor(Color.dsPrimary)
            }
        }
    }

    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.displayName ?? "Usuário")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                Label("\(user.weeklyPoints)", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Label("\(user.currentStreak)", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let status = user.friendshipStatus {
                statusBadge(status)
            }
        }
    }

    // MARK: - Botões / Badges

    @ViewBuilder
    private var actionButton: some View {
        if let status = user.friendshipStatus {
            statusActionButton(status)
        } else if user.canSendRequest {
            Button(action: onAddFriend) {
                HStack(spacing: 6) {
                    if isLoading { ProgressView().scaleEffect(0.8) }
                    else {
                        Image(systemName: "person.badge.plus")
                        Text("Adicionar")
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.dsPrimary)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func statusActionButton(_ status: FriendshipStatus) -> some View {
        switch status {
        case .pending:
            Text("Pendente")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

        case .accepted:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text("Amigo")
            }
            .font(.caption)
            .foregroundColor(.green)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)

        case .declined:
            Button(action: onAddFriend) {
                if isLoading { ProgressView().scaleEffect(0.8) }
                else { Text("Tentar Novamente") }
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.dsPrimary)
            .foregroundColor(.white)
            .cornerRadius(6)
            .disabled(isLoading)

        case .blocked:
            Text("Bloqueado")
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private func statusBadge(_ status: FriendshipStatus) -> some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColorFor(status))
            .foregroundColor(textColorFor(status))
            .cornerRadius(4)
    }

    // MARK: - Helpers

    private func symbolFor(avatarId: String) -> String {
        switch avatarId {
        case "zoe_studying": return "book.fill"
        case "zoe_reading": return "eyeglasses"
        case "zoe_celebrating": return "star.fill"
        case "zoe_thinking": return "brain.head.profile"
        default: return "person.fill"
        }
    }

    private func backgroundColorFor(_ status: FriendshipStatus) -> Color {
        switch status {
        case .pending:  return .orange.opacity(0.2)
        case .accepted: return .green.opacity(0.2)
        case .declined: return .red.opacity(0.2)
        case .blocked:  return .red.opacity(0.3)
        }
    }

    private func textColorFor(_ status: FriendshipStatus) -> Color {
        switch status {
        case .pending:  return .orange
        case .accepted: return .green
        case .declined: return .red
        case .blocked:  return .red
        }
    }
}

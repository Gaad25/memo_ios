import Foundation
import SwiftUI

@MainActor
final class FriendsViewModel: ObservableObject {

    // MARK: - Estado público

    // Listagens
    @Published var friends: [UserProfile] = []
    @Published var pendingRequests: [FriendRequest] = []

    // Busca
    @Published var searchResults: [UserSearchResult] = []
    @Published var isSearching: Bool = false

    // Carregamentos gerais
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Identidade
    @Published var currentUserId: UUID?

    // Ação: enviar pedido de amizade
    @Published var friendRequestState: LoadingState = .idle
    @Published var sendingToUserId: UUID?

    enum LoadingState: Equatable {
        case idle
        case loading
        case success(String)
        case error(String)

        var isFinished: Bool {
            switch self {
            case .success, .error: return true
            default: return false
            }
        }
    }

    // MARK: - Init

    init() {}

    // MARK: - Dados (amigos e pedidos)

    func refreshData() async {
        isLoading = true
        errorMessage = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchFriends() }
            group.addTask { await self.fetchPendingRequests() }
        }

        isLoading = false
    }

    func fetchFriends() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            currentUserId = userId

            let friendships: [Friendship] = try await SupabaseManager.shared.client
                .from("friendships")
                .select("*")
                .eq("status", value: "accepted")
                .or("user_id_1.eq.\(userId),user_id_2.eq.\(userId)")
                .execute()
                .value

            let friendIds = friendships.compactMap { f -> UUID? in
                if f.userId1 == userId { return f.userId2 }
                if f.userId2 == userId { return f.userId1 }
                return nil
            }

            if friendIds.isEmpty {
                self.friends = []
                return
            }

            let profiles: [UserProfile] = try await SupabaseManager.shared.client
                .from("user_profiles")
                .select("*")
                .in("id", values: friendIds)
                .execute()
                .value

            self.friends = profiles

        } catch {
            self.errorMessage = "Erro ao carregar amigos: \(error.localizedDescription)"
            print("❌ Erro ao buscar amigos: \(error)")
        }
    }

    func fetchPendingRequests() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            let friendships: [Friendship] = try await SupabaseManager.shared.client
                .from("friendships")
                .select("*")
                .eq("user_id_2", value: userId)
                .eq("status", value: "pending")
                .neq("action_user_id", value: userId)
                .execute()
                .value

            guard !friendships.isEmpty else {
                await MainActor.run { self.pendingRequests = [] }
                return
            }

            let senderIds = friendships.map { $0.userId1 }
            let senders: [UserProfile] = try await SupabaseManager.shared.client
                .from("user_profiles")
                .select("*")
                .in("id", values: senderIds)
                .execute()
                .value

            let byId = Dictionary(uniqueKeysWithValues: senders.map { ($0.id, $0) })

            let requests: [FriendRequest] = friendships.map { f in
                FriendRequest(
                    fromUserId: f.userId1,
                    toUserId: f.userId2,
                    createdAt: f.createdAt ?? Date(),
                    senderProfile: byId[f.userId1]
                )
            }

            await MainActor.run { self.pendingRequests = requests }

        } catch {
            await MainActor.run { self.errorMessage = "Erro ao carregar pedidos: \(error.localizedDescription)" }
            print("❌ Erro ao carregar pedidos pendentes: \(error)")
        }
    }




    // MARK: - Ações (aceitar / recusar / remover)

    func acceptRequest(_ request: FriendRequest) async {
        do {
            // quem está aceitando
            let me = try await SupabaseManager.shared.client.auth.session.user.id

            struct StatusUpdate: Encodable {
                let status: String
                let action_user_id: UUID  // registra quem fez a ação
            }
            let update = StatusUpdate(status: "accepted", action_user_id: me)

            try await SupabaseManager.shared.client
                .from("friendships")
                .update(update)
                .eq("user_id_1", value: request.fromUserId)
                .eq("user_id_2", value: request.toUserId)
                .eq("status", value: "pending")
                .execute()

            // UI
            pendingRequests.removeAll { $0.id == request.id }
            if let profile = request.senderProfile {
                friends.append(profile)
            } else {
                await fetchFriends()
            }

        } catch {
            self.errorMessage = "Erro ao aceitar pedido: \(error.localizedDescription)"
            print("❌ Erro ao aceitar pedido: \(error)")
        }
    }




    func declineRequest(_ request: FriendRequest) async {
        do {
            try await SupabaseManager.shared.client
                .from("friendships")
                .delete()
                .eq("user_id_1", value: request.fromUserId)
                .eq("user_id_2", value: request.toUserId)
                .eq("status", value: "pending")
                .execute()

            pendingRequests.removeAll { $0.id == request.id }

        } catch {
            self.errorMessage = "Erro ao recusar pedido: \(error.localizedDescription)"
            print("❌ Erro ao recusar pedido: \(error)")
        }
    }

    func removeFriend(_ friendProfile: UserProfile) async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            try await SupabaseManager.shared.client
                .from("friendships")
                .delete()
                .or("and(user_id_1.eq.\(userId),user_id_2.eq.\(friendProfile.id)),and(user_id_1.eq.\(friendProfile.id),user_id_2.eq.\(userId))")
                .execute()

            friends.removeAll { $0.id == friendProfile.id }

        } catch {
            self.errorMessage = "Erro ao remover amigo: \(error.localizedDescription)"
            print("❌ Erro ao remover amigo: \(error)")
        }
    }

    // MARK: - Busca (corrigido: .neq ANTES do .limit)

    func searchUsers(byName name: String) async {
        let term = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            // sessão opcional
            let me: UUID? = (try? await SupabaseManager.shared.client.auth.session)?.user.id
            if currentUserId == nil { currentUserId = me }

            let selectCols = "id, display_name, selected_avatar, weekly_points, points, current_streak"

            let users: [UserSearchResult]
            if let me {
                // ⚠️ Aqui aplicamos .neq ANTES do .limit
                users = try await SupabaseManager.shared.client
                    .from("user_profiles")
                    .select(selectCols)
                    .ilike("display_name", pattern: "%\(term)%")
                    .neq("id", value: me)
                    .limit(20)
                    .execute()
                    .value
            } else {
                users = try await SupabaseManager.shared.client
                    .from("user_profiles")
                    .select(selectCols)
                    .ilike("display_name", pattern: "%\(term)%")
                    .limit(20)
                    .execute()
                    .value
            }

            // Se não temos sessão, não dá pra checar amizades por RLS → devolve sem status
            guard let me else {
                self.searchResults = users.map { u in
                    var x = u; x.friendshipStatus = nil; x.canSendRequest = true; return x
                }
                #if DEBUG
                print("✅ Busca retornou \(users.count) usuário(s) (sem sessão)")
                #endif
                return
            }

            var results: [UserSearchResult] = []
            for var user in users {
                let existing: [Friendship] = try await SupabaseManager.shared.client
                    .from("friendships")
                    .select("*")
                    .or("and(user_id_1.eq.\(me),user_id_2.eq.\(user.id)),and(user_id_1.eq.\(user.id),user_id_2.eq.\(me))")
                    .limit(1)
                    .execute()
                    .value

                if let friendship = existing.first {
                    user.friendshipStatus = friendship.status
                    user.canSendRequest = friendship.status == .declined
                } else {
                    user.friendshipStatus = nil
                    user.canSendRequest = true
                }

                results.append(user)
            }

            self.searchResults = results
            #if DEBUG
            print("✅ Busca retornou \(results.count) usuário(s)")
            #endif

        } catch {
            self.errorMessage = "Erro na pesquisa: \(error.localizedDescription)"
            print("❌ Erro ao pesquisar usuários: \(error)")
        }
    }

    // MARK: - Enviar pedido (sessão garantida + feedback)

    func sendFriendRequest(to user: UserSearchResult) async {
        sendingToUserId = user.id
        friendRequestState = .loading
        errorMessage = nil

        // Sessão
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            let msg = "Sua sessão expirou. Faça login novamente."
            friendRequestState = .error(msg)
            errorMessage = msg
            sendingToUserId = nil
            print("⚠️ sessionMissing ao enviar pedido.")
            return
        }

        let currentId = session.user.id
        if currentId == user.id {
            let msg = "Você não pode enviar pedido para você mesmo."
            friendRequestState = .error(msg)
            errorMessage = msg
            sendingToUserId = nil
            return
        }

        do {
            struct FriendshipInsert: Encodable {
                let user_id_1: UUID
                let user_id_2: UUID
                let status: String
                let action_user_id: UUID
                let created_at: Date
            }

            let payload = FriendshipInsert(
                user_id_1: currentId,
                user_id_2: user.id,
                status: "pending",
                action_user_id: currentId,
                created_at: Date()
            )

            #if DEBUG
            print("📤 Enviando pedido -> \((user.displayName ?? "Usuário")) [\(user.id)]")
            #endif

            try await SupabaseManager.shared.client
                .from("friendships")
                .insert(payload)
                .execute()

            if let idx = searchResults.firstIndex(where: { $0.id == user.id }) {
                searchResults[idx].friendshipStatus = .pending
                searchResults[idx].canSendRequest = false
            }

            friendRequestState = .success("Pedido de amizade enviado para \((user.displayName ?? "usuário"))!")
            sendingToUserId = nil

        } catch {
            let raw = error.localizedDescription.lowercased()
            let message: String
            if raw.contains("duplicate key") || raw.contains("unique constraint") {
                message = "Você já tem um pedido/amizade com este usuário."
            } else if raw.contains("permission") || raw.contains("policy") || raw.contains("rls") {
                message = "Sem permissão para enviar o pedido. Verifique sua sessão."
            } else if raw.contains("jwt") || raw.contains("auth") {
                message = "Sua sessão expirou. Faça login novamente."
            } else {
                message = "Não foi possível enviar o pedido. Tente novamente."
            }

            friendRequestState = .error(message)
            errorMessage = message
            sendingToUserId = nil
            print("❌ Erro ao enviar pedido de amizade: \(error)")
        }
    }

    // MARK: - Helpers

    func clearError() { errorMessage = nil }
    func getFriendCount() -> Int { friends.count }
    func getPendingCount() -> Int { pendingRequests.count }
}

import Foundation

// MARK: - Status
enum FriendshipStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case blocked  = "blocked"

    var displayName: String {
        switch self {
        case .pending:  return "Pendente"
        case .accepted: return "Aceito"
        case .declined: return "Recusado"
        case .blocked:  return "Bloqueado"
        }
    }
}

// MARK: - Friendship (tabela sem coluna id)
struct Friendship: Codable, Identifiable {
    // Identificador computado para SwiftUI
    var id: String { "\(userId1.uuidString)_\(userId2.uuidString)" }

    let userId1: UUID
    let userId2: UUID
    let status: FriendshipStatus
    let actionUserId: UUID?
    let createdAt: Date?
    let updatedAt: Date?

    var friendProfile: UserProfile?

    enum CodingKeys: String, CodingKey {
        case userId1      = "user_id_1"
        case userId2      = "user_id_2"
        case status
        case actionUserId = "action_user_id"
        case createdAt    = "created_at"
        case updatedAt    = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId1      = try c.decode(UUID.self, forKey: .userId1)
        userId2      = try c.decode(UUID.self, forKey: .userId2)
        actionUserId = try c.decodeIfPresent(UUID.self, forKey: .actionUserId)
        let statusString = (try? c.decode(String.self, forKey: .status)) ?? "pending"
        status = FriendshipStatus(rawValue: statusString) ?? .pending
        createdAt = Friendship.decodeISODate(from: c, key: .createdAt)
        updatedAt = Friendship.decodeISODate(from: c, key: .updatedAt)
        friendProfile = nil
    }

    init(
        userId1: UUID,
        userId2: UUID,
        status: FriendshipStatus,
        actionUserId: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.userId1 = userId1
        self.userId2 = userId2
        self.status = status
        self.actionUserId = actionUserId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.friendProfile = nil
    }

    // Helpers de data
    static func decodeISODate<Keys: CodingKey>(from container: KeyedDecodingContainer<Keys>, key: Keys) -> Date? {
        if let str = try? container.decode(String.self, forKey: key),
           let parsed = parseISODate(str) { return parsed }
        if let direct = try? container.decode(Date.self, forKey: key) { return direct }
        return nil
    }
    static func parseISODate(_ str: String) -> Date? {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: str) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: str)
    }
}

// MARK: - FriendRequest (DTO para UI)
struct FriendRequest: Codable, Identifiable {
    // Também sem coluna id → computado
    var id: String { "\(fromUserId.uuidString)_\(toUserId.uuidString)" }

    let fromUserId: UUID
    let toUserId: UUID
    let createdAt: Date
    var senderProfile: UserProfile?

    enum CodingKeys: String, CodingKey {
        case fromUserId = "user_id_1"
        case toUserId   = "user_id_2"
        case createdAt  = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fromUserId = try c.decode(UUID.self, forKey: .fromUserId)
        toUserId   = try c.decode(UUID.self, forKey: .toUserId)
        createdAt  = Friendship.decodeISODate(from: c, key: .createdAt) ?? Date()
        senderProfile = nil
    }

    init(fromUserId: UUID, toUserId: UUID, createdAt: Date = Date(), senderProfile: UserProfile? = nil) {
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.createdAt = createdAt
        self.senderProfile = senderProfile
    }
}

// MARK: - Resultado de busca
struct UserSearchResult: Codable, Identifiable {
    let id: UUID
    let displayName: String?
    let selectedAvatar: String
    let weeklyPoints: Int
    let points: Int
    let currentStreak: Int

    var friendshipStatus: FriendshipStatus?
    var canSendRequest: Bool = true

    enum CodingKeys: String, CodingKey {
        case id
        case displayName    = "display_name"
        case selectedAvatar = "selected_avatar"
        case weeklyPoints   = "weekly_points"
        case points
        case currentStreak  = "current_streak"
    }

    var effectiveDisplayName: String {
        if let dn = displayName, !dn.isEmpty { return dn }
        return "Utilizador \(id.uuidString.prefix(8))"
    }
}

import Foundation

struct RankedUser: Codable, Identifiable {
    let id: UUID
    let userName: String
    let selectedAvatar: String
    let weeklyPoints: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userName = "user_name"
        case selectedAvatar = "selected_avatar"
        case weeklyPoints = "weekly_points"
    }
    
    // Inicializador customizado para lidar com diferentes tipos de user_name
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        selectedAvatar = try container.decodeIfPresent(String.self, forKey: .selectedAvatar) ?? "zoe_default"
        weeklyPoints = try container.decodeIfPresent(Int.self, forKey: .weeklyPoints) ?? 0
        
        // Prioriza o display_name, depois tenta UUID, senão usa fallback
        if let displayName = try? container.decodeIfPresent(String.self, forKey: .userName), 
           !displayName.isEmpty {
            userName = displayName
        } else if let nameUUID = try? container.decode(UUID.self, forKey: .userName) {
            // Se o user_name for um UUID (como id), criar um nome amigável
            userName = "Utilizador \(nameUUID.uuidString.prefix(8))"
        } else {
            userName = "Utilizador Anônimo"
        }
    }
    
    // Inicializador direto para testes
    init(id: UUID, userName: String, selectedAvatar: String, weeklyPoints: Int) {
        self.id = id
        self.userName = userName
        self.selectedAvatar = selectedAvatar
        self.weeklyPoints = weeklyPoints
    }
}

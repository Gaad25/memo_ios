import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var points: Int
    var currentStreak: Int
    var lastStudyDate: Date?
    var studyObjective: String?
    var weeklyPoints: Int
    var maxStreak: Int
    var maxWeeklyPoints: Int
    var selectedAvatar: String
    var displayName: String?

    enum CodingKeys: String, CodingKey {
        case id, points
        case currentStreak = "current_streak"
        case lastStudyDate = "last_study_date"
        case studyObjective = "study_objective"
        case weeklyPoints = "weekly_points"
        case maxStreak = "max_streak"
        case maxWeeklyPoints = "max_weekly_points"
        case selectedAvatar = "selected_avatar"
        case displayName = "display_name"
    }

    // Inicializador customizado para lidar com diferentes formatos de data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        points = try container.decode(Int.self, forKey: .points)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        studyObjective = try container.decodeIfPresent(String.self, forKey: .studyObjective)
        weeklyPoints = try container.decodeIfPresent(Int.self, forKey: .weeklyPoints) ?? 0
        maxStreak = try container.decodeIfPresent(Int.self, forKey: .maxStreak) ?? 0
        maxWeeklyPoints = try container.decodeIfPresent(Int.self, forKey: .maxWeeklyPoints) ?? 0
        selectedAvatar = try container.decodeIfPresent(String.self, forKey: .selectedAvatar) ?? "zoe_default"
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)

        // Tenta descodificar a data
        if let dateString = try container.decodeIfPresent(String.self, forKey: .lastStudyDate) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: dateString) {
                lastStudyDate = date
            } else {
                // Se falhar, tenta o formato YYYY-MM-DD
                let shortFormatter = DateFormatter()
                shortFormatter.dateFormat = "yyyy-MM-dd"
                if let date = shortFormatter.date(from: dateString) {
                    lastStudyDate = date
                } else {
                    lastStudyDate = nil
                }
            }
        } else {
            lastStudyDate = nil
        }
    }
    
    // Inicializador conveniente para testes e previews
    init(id: UUID, points: Int, currentStreak: Int, lastStudyDate: Date?, studyObjective: String?, weeklyPoints: Int, maxStreak: Int, maxWeeklyPoints: Int, selectedAvatar: String, displayName: String?) {
        self.id = id
        self.points = points
        self.currentStreak = currentStreak
        self.lastStudyDate = lastStudyDate
        self.studyObjective = studyObjective
        self.weeklyPoints = weeklyPoints
        self.maxStreak = maxStreak
        self.maxWeeklyPoints = maxWeeklyPoints
        self.selectedAvatar = selectedAvatar
        self.displayName = displayName
    }
}

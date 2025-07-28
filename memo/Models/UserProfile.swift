//
//  UserProfile.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 21/07/25.
//
import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var points: Int
    var currentStreak: Int
    var lastStudyDate: Date?

    enum CodingKeys: String, CodingKey {
        case id, points
        case currentStreak = "current_streak"
        case lastStudyDate = "last_study_date"
    }

    // Inicializador customizado para lidar com diferentes formatos de data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        points = try container.decode(Int.self, forKey: .points)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)

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
}

//
//  Goal.swift.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 26/05/25.
//

import Foundation

struct Goal: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let subjectId: UUID?
    var title: String
    var targetHours: Double
    var endDate: Date
    var completed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case subjectId = "subject_id"
        case title
        case targetHours = "target_hours"
        case endDate = "end_date"
        case completed
    }
}

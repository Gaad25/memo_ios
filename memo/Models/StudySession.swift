//
//  StudySession.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 26/05/25.
//

import Foundation

struct StudySession: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let subjectId: UUID
    let startTime: Date
    let endTime: Date
    let durationMinutes: Int
    let questionsAttempted: Int?
    let questionsCorrect: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case subjectId = "subject_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case durationMinutes = "duration_minutes"
        case questionsAttempted = "questions_attempted"
        case questionsCorrect = "questions_correct"
        case notes
    }
}

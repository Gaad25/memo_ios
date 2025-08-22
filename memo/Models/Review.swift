import Foundation

struct Review: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let sessionId: UUID
    let subjectId: UUID
    let reviewDate: Date
    var status: String
    let reviewInterval: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionId = "session_id"
        case subjectId = "subject_id"
        case reviewDate = "review_date"
        case status
        case reviewInterval = "review_interval"
    }
}

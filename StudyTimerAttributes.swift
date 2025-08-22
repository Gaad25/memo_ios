// Dentro de StudyTimerAttributes.swift (ficheiro partilhado)
import ActivityKit
import Foundation

struct StudyTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timerRange: ClosedRange<Date>
        var isRunning: Bool
        var pauseDate: Date? // Guardamos a data em que foi pausado
    }

    // Fixed non-changing properties about your activity go here!
    var subjectName: String
}


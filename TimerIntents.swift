import AppIntents
import Combine

// Objeto para comunicar eventos da Live Activity para a App
class TimerIntentManager: ObservableObject {
    static let shared = TimerIntentManager()
    let subject = PassthroughSubject<TimerAction, Never>()
}

enum TimerAction {
    case pause, resume, end
}

struct PauseResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pausar/Retomar Cronómetro"

    @Parameter(title: "Is Paused")
    var isPaused: Bool

    init(isPaused: Bool) {
        self.isPaused = isPaused
    }

    init() {
        self.isPaused = false
    }

    func perform() async throws -> some IntentResult {
        TimerIntentManager.shared.subject.send(isPaused ? .resume : .pause)
        return .result()
    }
}

struct EndTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Terminar Sessão"

    func perform() async throws -> some IntentResult {
        TimerIntentManager.shared.subject.send(.end)
        return .result()
    }
}


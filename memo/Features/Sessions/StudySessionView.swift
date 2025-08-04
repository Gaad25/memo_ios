import SwiftUI
import Combine
import UserNotifications

struct StudySessionView: View {
    @Environment(\.dismiss) var dismiss
    let subject: Subject
    
    private struct ReturnedSession: Codable {
        let id: UUID, userId: UUID, subjectId: UUID, startTime: Date
        enum CodingKeys: String, CodingKey {
            case id, userId = "user_id", subjectId = "subject_id", startTime = "start_time"
        }
    }
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: AnyCancellable?
    @State private var isRunning = true
    @State private var isSummaryView = false
    @State private var questionsAttempted: String = ""
    @State private var questionsCorrect: String = ""
    @State private var notes: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                if isSummaryView { summaryForm } else { timerView }
            }
            .onAppear(perform: startTimer)
            .onDisappear(perform: stopTimer)
        }
    }
    
    // MARK: - Subviews
    
    private var timerView: some View {
        VStack {
            Spacer()
            Text(subject.name)
                .font(.largeTitle.bold())
                .foregroundColor(subject.swiftUIColor)
            
            timeDisplayWithControls
                .padding(.vertical, 40)
            
            HStack(spacing: 30) {
                Button(action: toggleTimer) {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                }
                
                Button(action: finishSession) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }
            }
            Spacer()
        }
    }
    
    private var timeDisplayWithControls: some View {
        HStack(spacing: 20) {
            timeComponentControl(unit: .hours, value: hours)
            timeComponentControl(unit: .minutes, value: minutes)
            VStack {
                Text(String(format: "%02d", seconds))
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                Text("Seg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func timeComponentControl(unit: TimeUnit, value: Int) -> some View {
        VStack {
            Button(action: { adjustTime(by: unit.rawValue, unit: unit) }) {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.title)
            }
            .disabled(isRunning)

            Text(String(format: "%02d", value))
                .font(.system(size: 70, weight: .bold, design: .rounded))
            
            Button(action: { adjustTime(by: -unit.rawValue, unit: unit) }) {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title)
            }
            .disabled(isRunning || elapsedTime < unit.rawValue)
        }
        .opacity(isRunning ? 0.5 : 1.0)
    }
    
    private var summaryForm: some View {
        Form {
            Section("Resumo da Sessão") {
                Text("Duração: \(formattedTime(elapsedTime))")
                TextField("Questões Tentadas (opcional)", text: $questionsAttempted)
                    .keyboardType(.numberPad)
                TextField("Questões Corretas (opcional)", text: $questionsCorrect)
                    .keyboardType(.numberPad)
            }
            
            Section("Anotações") {
                TextEditor(text: $notes)
                    .frame(height: 150)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage).foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Salvar Sessão")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Descartar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                if isLoading {
                    ProgressView()
                } else {
                    Button("Salvar") {
                        saveSession() // Chamada direta, sem Task ou await.
                    }
                }
            }
        }
    }

    // MARK: - Funções do Cronômetro
    
    private enum TimeUnit: TimeInterval {
        case hours = 3600
        case minutes = 60
    }
    
    private var hours: Int { Int(elapsedTime) / 3600 }
    private var minutes: Int { (Int(elapsedTime) % 3600) / 60 }
    private var seconds: Int { Int(elapsedTime) % 60 }
    
    private func adjustTime(by amount: TimeInterval, unit: TimeUnit) {
        let newTime = elapsedTime + amount
        if newTime >= 0 {
            elapsedTime = newTime
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if isRunning {
                    elapsedTime += 1
                }
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func toggleTimer() {
        isRunning.toggle()
    }
    
    private func finishSession() {
        isRunning = false
        stopTimer()
        isSummaryView = true
    }
    
    // MARK: - Funções de Lógica e Salvamento
    
    private func formattedTime(_ totalSeconds: TimeInterval) -> String {
        let h = Int(totalSeconds) / 3600
        let m = (Int(totalSeconds) % 3600) / 60
        let s = Int(totalSeconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    private func saveSession() {
        isLoading = true
        
        Task {
            do {
                let durationInMinutes = max(1, Int(round(elapsedTime / 60)))
                let qAttempted = Int(questionsAttempted)
                let qCorrect = Int(questionsCorrect)
                let startTime = Date().addingTimeInterval(-elapsedTime)
                
                let user = try await SupabaseManager.shared.client.auth.session.user
                
                struct InsertableSession: Encodable {
                    let userId: UUID, subjectId: UUID, startTime: Date, endTime: Date, durationMinutes: Int,
                        questionsAttempted: Int?, questionsCorrect: Int?, notes: String?
                    enum CodingKeys: String, CodingKey {
                        case userId = "user_id", subjectId = "subject_id", startTime = "start_time", endTime = "end_time", durationMinutes = "duration_minutes", questionsAttempted = "questions_attempted", questionsCorrect = "questions_correct", notes
                    }
                }
                
                let sessionToInsert = InsertableSession(userId: user.id, subjectId: subject.id, startTime: startTime, endTime: Date(), durationMinutes: durationInMinutes, questionsAttempted: qAttempted, questionsCorrect: qCorrect, notes: notes.isEmpty ? nil : notes)
                
                let returnedSession: ReturnedSession = try await SupabaseManager.shared.client
                    .from("study_sessions").insert(sessionToInsert, returning: .representation)
                    .select("id, user_id, subject_id, start_time").single().execute().value

                await scheduleReviews(for: returnedSession)
                
                await HomeViewModel.shared.userDidCompleteAction()
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Erro ao salvar: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func scheduleReviews(for session: ReturnedSession) async {
        struct NewReview: Encodable {
            let userId: UUID, sessionId: UUID, subjectId: UUID, reviewDate: Date, reviewInterval: String
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id", sessionId = "session_id", subjectId = "subject_id",
                     reviewDate = "review_date", reviewInterval = "review_interval"
            }
        }
        let firstReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: session.startTime)!
        
        let firstReview = NewReview(
            userId: session.userId,
            sessionId: session.id,
            subjectId: session.subjectId,
            reviewDate: firstReviewDate,
            reviewInterval: "1d"
        )
        do {
            try await SupabaseManager.shared.client.from("reviews").insert(firstReview).execute()
            
            // Agendamos também a notificação local para esta primeira revisão.
            scheduleLocalNotification(subjectName: subject.name, reviewDate: firstReviewDate, intervalText: "1 dia")
            print("✅ Primeira revisão agendada para \(firstReviewDate.formatted()).")

        } catch {
            print("❌ Erro ao agendar a primeira revisão no Supabase: \(error.localizedDescription)")
        }
    }

    private func scheduleLocalNotification(subjectName: String, reviewDate: Date, intervalText: String) {
            // --- INÍCIO DA MODIFICAÇÃO (Fase 2) ---
            // 1. Verifica se as notificações estão habilitadas pelo usuário.
            let notificationsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.notificationsEnabled)
            guard notificationsEnabled else {
                print("🔔 Notificações desabilitadas pelo usuário. Nenhuma notificação agendada.")
                return
            }

            // 2. Carrega a hora de notificação preferida do usuário.
            let notificationTime = (UserDefaults.standard.object(forKey: UserDefaultsKeys.notificationTime) as? Date) ?? {
                var components = DateComponents()
                components.hour = 9
                components.minute = 0
                return Calendar.current.date(from: components) ?? Date()
            }()
            // --- FIM DA MODIFICAÇÃO ---

            let content = UNMutableNotificationContent()
            content.title = "Memo: Hora da Revisão!"
            content.body = "Está na hora de revisar o conteúdo de '\(subjectName)' (revisão de \(intervalText))."
            content.sound = .default
            
            // 3. Usa a data da revisão com a hora e minuto definidos pelo usuário.
            var triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reviewDate)
            triggerDateComponents.hour = Calendar.current.component(.hour, from: notificationTime)
            triggerDateComponents.minute = Calendar.current.component(.minute, from: notificationTime)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Erro ao agendar notificação local: \(error.localizedDescription)")
                } else {
                    let scheduledDate = Calendar.current.date(from: triggerDateComponents)
                    print("Notificação para '\(subjectName)' agendada para \(scheduledDate?.formatted() ?? "data inválida").")
                }
            }
        }
    }

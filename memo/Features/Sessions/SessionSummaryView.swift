// memo/Features/Sessions/SessionSummaryView.swift

import SwiftUI
import UserNotifications

struct SessionSummaryView: View {
    @Environment(\.dismiss) var dismiss
    let subject: Subject
    let elapsedTime: TimeInterval

    // MARK: - State
    @State private var questionsAttempted: String = ""
    @State private var questionsCorrect: String = ""
    @State private var notes: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showToast = false
    @State private var notesShake = 0
    
    // Struct para decodificar o retorno do Supabase
    private struct ReturnedSession: Codable {
        let id: UUID
        let userId: UUID
        let subjectId: UUID
        let startTime: Date
        
        enum CodingKeys: String, CodingKey {
            case id, userId = "user_id", subjectId = "subject_id", startTime = "start_time"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Resumo da Sessão") {
                    // Usando o Text com cor secundária para se assemelhar a um campo desabilitado
                    HStack {
                        Text("Duração")
                        Spacer()
                        Text(formattedTime(elapsedTime))
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("Questões Tentadas (opcional)", text: $questionsAttempted)
                        .keyboardType(.numberPad)
                    
                    TextField("Questões Corretas (opcional)", text: $questionsCorrect)
                        .keyboardType(.numberPad)
                }
                
                Section("Anotações") {
                    // Usamos um placeholder para o TextEditor
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Adicione as suas anotações aqui...")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 150)
                            .accessibilityLabel("Anotações da sessão")
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Salvar Sessão")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Descartar") { Haptics.light(); dismiss() }
                        .accessibilityLabel("Descartar")
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Salvar") {
                            Haptics.light()
                            Task { await saveSession() }
                        }
                        .disabled(isLoading)
                        .accessibilityLabel("Salvar")
                    }
                }
            }
            .toast($showToast, message: "Sessão salva!")
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    // MARK: - Funções de Lógica e Salvamento
    
    private func formattedTime(_ totalSeconds: TimeInterval) -> String {
        let h = Int(totalSeconds) / 3600
        let m = (Int(totalSeconds) % 3600) / 60
        let s = Int(totalSeconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    private func saveSession() async {
        isLoading = true
        
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
            
            // Salva a última matéria estudada para "Continuar de Onde Parou"
            UserDefaults.standard.set(subject.id.uuidString, forKey: UserDefaultsKeys.lastStudiedSubjectID)

            await HomeViewModel.shared.userDidCompleteAction()

            Haptics.success()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
            
        } catch {
            errorMessage = "Erro ao salvar: \(error.localizedDescription)"
            isLoading = false
            Haptics.error()
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
            scheduleLocalNotification(subjectName: subject.name, reviewDate: firstReviewDate, intervalText: "1 dia")
            #if DEBUG
            print("✅ Primeira revisão agendada para \(firstReviewDate.formatted()).")
            #endif
        } catch {
            #if DEBUG
            print("❌ Erro ao agendar a primeira revisão no Supabase: \(error.localizedDescription)")
            #endif
        }
    }

    private func scheduleLocalNotification(subjectName: String, reviewDate: Date, intervalText: String) {
        let notificationsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.notificationsEnabled)
        guard notificationsEnabled else {
            #if DEBUG
            print("🔔 Notificações desabilitadas pelo usuário.")
            #endif
            return
        }

        let notificationTime = (UserDefaults.standard.object(forKey: UserDefaultsKeys.notificationTime) as? Date) ?? {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }()

        let content = UNMutableNotificationContent()
        content.title = "Memo: Hora da Revisão!"
        content.body = "Está na hora de rever o conteúdo de '\(subjectName)' (revisão de \(intervalText))."
        content.sound = .default
        
        var triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: reviewDate)
        triggerDateComponents.hour = Calendar.current.component(.hour, from: notificationTime)
        triggerDateComponents.minute = Calendar.current.component(.minute, from: notificationTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                #if DEBUG
                print("Erro ao agendar notificação local: \(error.localizedDescription)")
                #endif
            } else {
                let scheduledDate = Calendar.current.date(from: triggerDateComponents)
                #if DEBUG
                print("Notificação para '\(subjectName)' agendada para \(scheduledDate?.formatted() ?? "data inválida").")
                #endif
            }
        }
    }
}

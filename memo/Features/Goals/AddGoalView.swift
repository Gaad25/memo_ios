import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    
    // Lista de matérias existentes para o usuário poder associar a uma meta
    let subjects: [Subject]
    var onGoalAdded: () -> Void

    @State private var title: String = ""
    @State private var targetHours: String = ""
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    @State private var selectedSubjectId: UUID?

    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var titleError: String?
    @State private var hoursError: String?
    @State private var titleShake = 0
    @State private var hoursShake = 0
    @State private var showToast = false
    @FocusState private var focus: Field?
    private enum Field { case title, hours }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalhes da Meta") {
                    TextField("Título (Ex: Dominar Cálculo 1)", text: $title)
                        .modifier(PrimaryTextFieldStyle(isInvalid: titleError != nil))
                        .modifier(ShakeEffect(shakes: titleShake))
                        .focused($focus, equals: .title)
                        .submitLabel(.next)
                        .onChange(of: title) { _, _ in validateTitle() }
                        .accessibilityLabel("Título da meta")
                    if let titleError { Text(titleError).foregroundColor(.dsError).font(.footnote) }

                    TextField("Horas de Estudo (Ex: 30)", text: $targetHours)
                        .keyboardType(.decimalPad)
                        .modifier(PrimaryTextFieldStyle(isInvalid: hoursError != nil))
                        .modifier(ShakeEffect(shakes: hoursShake))
                        .focused($focus, equals: .hours)
                        .onChange(of: targetHours) { _, _ in validateHours() }
                        .accessibilityLabel("Horas de estudo")
                    if let hoursError { Text(hoursError).foregroundColor(.dsError).font(.footnote) }

                    DatePicker("Prazo Final", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .accessibilityLabel("Selecionar prazo final")
                        .onChange(of: endDate) { _, _ in Haptics.light() }
                }

                Section("Matéria (Opcional)") {
                    Picker("Associar a uma Matéria", selection: $selectedSubjectId) {
                        Text("Nenhuma").tag(UUID?.none)
                        ForEach(subjects) { subject in
                            HStack {
                                Circle().fill(subject.swiftUIColor).frame(width: 12, height: 12)
                                Text(subject.name)
                            }
                            .tag(UUID?.some(subject.id))
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .sensoryFeedback(.impact(weight: .light), trigger: selectedSubjectId)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Nova Meta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { Haptics.light(); dismiss() }
                        .accessibilityLabel("Cancelar")
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading { ProgressView() } else {
                        Button("Salvar") {
                            Haptics.light()
                            Task { await saveGoal() }
                        }
                        .disabled(!isValid)
                        .accessibilityLabel("Salvar")
                    }
                }
            }
            .toast($showToast, message: "Meta criada!")
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func saveGoal() async {
        validateTitle(); validateHours()
        guard isValid, let hours = Double(targetHours) else {
            Haptics.error()
            withAnimation(.easeIn(duration: 0.12)) { titleShake += 1; hoursShake += 1 }
            return
        }

        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await SupabaseManager.shared.client.auth.user()
            
            struct NewGoal: Encodable {
                let userId: UUID
                let subjectId: UUID?
                let title: String
                let targetHours: Double
                let endDate: Date
                
                enum CodingKeys: String, CodingKey {
                    case userId = "user_id", subjectId = "subject_id", title, targetHours = "target_hours", endDate = "end_date"
                }
            }
            
            let goalData = NewGoal(userId: user.id, subjectId: selectedSubjectId, title: title, targetHours: hours, endDate: endDate)
            
            try await SupabaseManager.shared.client.from("goals").insert(goalData).execute()
            
            onGoalAdded()
            Haptics.success()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
            
        } catch {
            errorMessage = "Erro ao salvar meta: \(error.localizedDescription)"
            Haptics.error()
        }
        
        isLoading = false
    }

    private var isValid: Bool { titleError == nil && hoursError == nil && !title.isEmpty && !targetHours.isEmpty }
    private func validateTitle() {
        titleError = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "O título é obrigatório." : nil
    }
    private func validateHours() {
        if targetHours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { hoursError = "Informe as horas."; return }
        hoursError = Double(targetHours) == nil ? "Horas inválidas." : nil
    }
}

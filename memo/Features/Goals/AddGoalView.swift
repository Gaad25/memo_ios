//
//  AddGoalView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 26/05/25.
//

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

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalhes da Meta") {
                    TextField("Título (Ex: Dominar Cálculo 1)", text: $title)
                    TextField("Horas de Estudo (Ex: 30)", text: $targetHours)
                        .keyboardType(.decimalPad)
                    DatePicker("Prazo Final", selection: $endDate, displayedComponents: .date)
                }

                Section("Matéria (Opcional)") {
                    Picker("Associar a uma Matéria", selection: $selectedSubjectId) {
                        Text("Nenhuma").tag(UUID?.none)
                        ForEach(subjects) { subject in
                            Text(subject.name).tag(UUID?.some(subject.id))
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Nova Meta")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading { ProgressView() } else {
                        Button("Salvar") {
                            Task { await saveGoal() }
                        }
                        .disabled(title.isEmpty || targetHours.isEmpty)
                    }
                }
            }
        }
    }

    private func saveGoal() async {
        guard let hours = Double(targetHours) else {
            errorMessage = "Por favor, insira um número válido de horas."
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
            dismiss()
            
        } catch {
            errorMessage = "Erro ao salvar meta: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

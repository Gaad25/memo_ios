import SwiftUI

struct AddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    
    // Propriedade para receber uma matéria existente (para edição)
    let subjectToEdit: Subject?
    var onDone: () -> Void // Renomeado de onSubjectUpserted para onDone
    
    @State private var name: String
    @State private var category: String
    @State private var color: Color
    
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    // Inicializador customizado para lidar com Adicionar e Editar
    init(subjectToEdit: Subject? = nil, onDone: @escaping () -> Void) {
        self.subjectToEdit = subjectToEdit
        self.onDone = onDone
        
        if let subject = subjectToEdit {
            _name = State(initialValue: subject.name)
            _category = State(initialValue: subject.category)
            _color = State(initialValue: Color(hex: subject.color))
        } else {
            _name = State(initialValue: "")
            _category = State(initialValue: "")
            _color = State(initialValue: .blue)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalhes da Matéria")) {
                    TextField("Nome da Matéria", text: $name)
                    TextField("Categoria (Ex: Exatas)", text: $category)
                    ColorPicker("Cor da Matéria", selection: $color, supportsOpacity: false)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(subjectToEdit == nil ? "Nova Matéria" : "Editar Matéria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Salvar") {
                            Task {
                                await saveChanges()
                            }
                        }
                        .disabled(name.isEmpty)
                    }
                }
            }
        }
    }
    
    private func saveChanges() async {
        isLoading = true
        errorMessage = nil
        
        guard let hexColor = color.toHex() else {
            errorMessage = "A cor selecionada é inválida. Por favor, escolha outra."
            isLoading = false
            return
        }
        
        do {
            // Se subjectToEdit não for nulo, estamos atualizando (UPDATE)
            if let subject = subjectToEdit {
                struct UpdatedSubject: Encodable {
                    let name: String
                    let category: String
                    let color: String
                }
                let updatedSubject = UpdatedSubject(name: name, category: category, color: hexColor)
                
                try await SupabaseManager.shared.client
                    .from("subjects")
                    .update(updatedSubject)
                    .eq("id", value: subject.id)
                    .execute()
                
            // Senão, estamos criando um novo (INSERT)
            } else {
                let user = try await SupabaseManager.shared.client.auth.user()
                struct NewSubject: Encodable {
                    let name: String
                    let category: String
                    let color: String
                    let userId: UUID
                    
                    enum CodingKeys: String, CodingKey {
                        case name, category, color, userId = "user_id"
                    }
                }
                let newSubject = NewSubject(name: name, category: category, color: hexColor, userId: user.id)
                try await SupabaseManager.shared.client.from("subjects").insert(newSubject).execute()
            }
            
            onDone()
            dismiss()
            
        } catch {
            errorMessage = "Erro ao salvar matéria: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// Pequena extensão para converter Color para Hex
extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(red) * 255),
            lroundf(Float(green) * 255),
            lroundf(Float(blue) * 255)
        )
    }
}

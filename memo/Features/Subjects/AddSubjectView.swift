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
    @State private var showToast = false
    @State private var nameError: String?
    @State private var nameShake = 0
    @FocusState private var focused: Field?
    private enum Field { case name, category }

    // UI State
    @State private var showColorPicker = false
    
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
                // Pré-visualização (cartão)
                Section {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(color)
                            .frame(width: 42, height: 42)
                            .shadow(color: color.opacity(0.25), radius: 8, y: 6)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "Nome da Matéria" : name)
                                .font(.headline)
                                .foregroundStyle(Color.dsTextPrimary)
                            Text(category.isEmpty ? "Categoria" : category)
                                .font(.subheadline)
                                .foregroundStyle(Color.dsTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .systemBackground))
                            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
                    )
                    .listRowBackground(Color.clear)
                }

                // Detalhes da Matéria
                Section(header: Text("Detalhes da Matéria")) {
                    // Nome
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nome da Matéria")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dsTextSecondary)

                        HStack(spacing: 10) {
                            Image(systemName: "book.fill")
                                .foregroundStyle(Color.dsTextTertiary)
                            TextField("Digite o nome da matéria", text: $name)
                                .submitLabel(.next)
                                .focused($focused, equals: .name)
                                .accessibilityLabel("Nome da matéria")
                                .onChange(of: name) { _, _ in validateName() }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(uiColor: .systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    nameError != nil ? Color.dsError : (focused == .name ? Color.dsPrimary.opacity(0.35) : Color.gray.opacity(0.2)),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: .black.opacity(focused == .name ? 0.06 : 0), radius: 12, y: 6)
                        .modifier(ShakeEffect(shakes: nameShake))

                        if let nameError { Text(nameError).foregroundColor(.dsError).font(.footnote) }
                    }

                    // Categoria (campo de texto)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Categoria")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dsTextSecondary)

                        HStack(spacing: 10) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(Color.dsTextTertiary)
                            TextField("Digite a categoria (ex.: Exatas)", text: $category)
                                .submitLabel(.done)
                                .focused($focused, equals: .category)
                                .accessibilityLabel("Categoria da matéria")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(uiColor: .systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    focused == .category ? Color.dsPrimary.opacity(0.35) : Color.gray.opacity(0.2),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: .black.opacity(focused == .category ? 0.06 : 0), radius: 12, y: 6)
                    }

                    // Cor (abre seletor)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cor da Matéria")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.dsTextSecondary)

                        Button {
                            Haptics.light()
                            showColorPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "paintpalette.fill")
                                    .foregroundStyle(Color.dsTextTertiary)
                                Text("Selecionar cor")
                                    .foregroundStyle(Color.dsTextPrimary)
                                Spacer()
                                Circle().fill(color).frame(width: 20, height: 20)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(uiColor: .systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.0), radius: 12, y: 6)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Selecionar cor da matéria")
                    }
                }

                if let errorMessage = errorMessage {
                    Section { Text(errorMessage).foregroundColor(.red) }
                }
            }
            .navigationTitle(subjectToEdit == nil ? "Nova Matéria" : "Editar Matéria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { Haptics.light(); dismiss() }
                        .accessibilityLabel("Cancelar")
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Salvar") {
                            Haptics.light()
                            Task { await saveChanges() }
                        }
                        .disabled(!isValid)
                        .tint(.dsPrimary)
                        .accessibilityLabel("Salvar")
                    }
                }
            }
            .toast($showToast, message: subjectToEdit == nil ? "Matéria criada!" : "Matéria atualizada!")
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showColorPicker) {
                NavigationStack {
                    Form {
                        ColorPicker("Cor da Matéria", selection: $color, supportsOpacity: false)
                            .onChange(of: color) { _, _ in Haptics.light() }
                    }
                    .navigationTitle("Selecionar Cor")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("OK") { Haptics.light(); showColorPicker = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func saveChanges() async {
        validateName()
        guard isValid else {
            Haptics.error()
            withAnimation(.easeIn(duration: 0.12)) { nameShake += 1 }
            return
        }

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
            Haptics.success()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
            
        } catch {
            errorMessage = "Erro ao salvar matéria: \(error.localizedDescription)"
            Haptics.error()
        }
        
        isLoading = false
    }
    
    private var isValid: Bool { nameError == nil && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private func validateName() {
        nameError = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "O nome é obrigatório." : nil
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

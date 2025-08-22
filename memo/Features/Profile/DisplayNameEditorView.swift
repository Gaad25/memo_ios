import SwiftUI

struct DisplayNameEditorView: View {
    @Binding var displayName: String
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showingValidationError: Bool = false
    
    let isFirstTime: Bool
    let onSave: (String) async -> Result<Void, DisplayNameError>
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Input field
                inputSection
                
                // Validation info
                validationInfoSection
                
                Spacer()
                
                // Action buttons
                actionButtonsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .navigationTitle(isFirstTime ? "Bem-vindo!" : "Editar Nome")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(isFirstTime)
            .toolbar {
                if !isFirstTime {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancelar") {
                            onCancel()
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .alert("Erro de Validação", isPresented: $showingValidationError) {
                Button("OK") {
                    showingValidationError = false
                }
            } message: {
                Text(errorMessage ?? "Nome inválido")
            }
        }
        .onAppear {
            inputText = displayName
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            if isFirstTime {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(Color.dsPrimary)
                
                Text("Escolha seu nome de exibição")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Este nome será mostrado no ranking e outras interações sociais do app.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.dsPrimary)
                
                Text("Alterar nome de exibição")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nome de Exibição")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Digite seu nome", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .disabled(isLoading)
                .onSubmit {
                    Task {
                        await saveDisplayName()
                    }
                }
            
            // Character count
            HStack {
                Spacer()
                Text("\(inputText.count)/15")
                    .font(.caption)
                    .foregroundColor(inputText.count > 15 ? .red : .secondary)
            }
        }
    }
    
    private var validationInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Requisitos:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                ValidationRow(
                    text: "Entre 3 a 15 caracteres",
                    isValid: inputText.count >= 3 && inputText.count <= 15
                )
                
                ValidationRow(
                    text: "Apenas letras, números e espaços",
                    isValid: isValidCharacters(inputText)
                )
                
                ValidationRow(
                    text: "Não pode estar vazio",
                    isValid: !inputText.trimmingCharacters(in: .whitespaces).isEmpty
                )
            }
        }
        .padding(16)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await saveDisplayName()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    
                    Text(isFirstTime ? "Confirmar e Continuar" : "Salvar Alterações")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidInput ? Color.dsPrimary : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isValidInput || isLoading)
            
            if !isFirstTime {
                Button("Cancelar") {
                    onCancel()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .disabled(isLoading)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidInput: Bool {
        validateDisplayName(inputText).isValid
    }
    
    // MARK: - Helper Functions
    
    private func saveDisplayName() async {
        let validation = validateDisplayName(inputText)
        
        guard validation.isValid else {
            errorMessage = validation.errorMessage
            showingValidationError = true
            return
        }
        
        isLoading = true
        
        let result = await onSave(inputText.trimmingCharacters(in: .whitespaces))
        
        isLoading = false
        
        switch result {
        case .success:
            displayName = inputText.trimmingCharacters(in: .whitespaces)
            onCancel() // Fecha o modal
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingValidationError = true
        }
    }
    
    private func validateDisplayName(_ name: String) -> (isValid: Bool, errorMessage: String?) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        
        if trimmed.isEmpty {
            return (false, "O nome não pode estar vazio")
        }
        
        if trimmed.count < 3 {
            return (false, "O nome deve ter pelo menos 3 caracteres")
        }
        
        if trimmed.count > 15 {
            return (false, "O nome deve ter no máximo 15 caracteres")
        }
        
        if !isValidCharacters(trimmed) {
            return (false, "Use apenas letras, números e espaços")
        }
        
        return (true, nil)
    }
    
    private func isValidCharacters(_ text: String) -> Bool {
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces)
        return text.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
}

// MARK: - Supporting Views

struct ValidationRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.subheadline)
                .foregroundColor(isValid ? .green : .secondary)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(isValid ? .primary : .secondary)
            
            Spacer()
        }
    }
}

#Preview {
    DisplayNameEditorView(
        displayName: .constant(""),
        isFirstTime: true,
        onSave: { _ in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return .success(())
        },
        onCancel: {}
    )
}

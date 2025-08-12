// memo/Features/Authentication/RegisterView.swift

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var acceptTerms = false
    
    @State private var isLoading = false
    @State private var validationErrors: [Field: String] = [:]
    @State private var registrationAttempts = 0

    @FocusState var focusedField: Field?
    enum Field: Hashable {
        case name, email, password, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Header (Com mais destaque)
                VStack(spacing: 8) {
                    Image("ic_memo_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120) // Tamanho aumentado
                        .padding(.top, 20)
                    
                    Text("Crie sua Conta")
                        .font(.largeTitle) // Mais hierarquia
                        .fontWeight(.bold)
                    
                    Text("Comece a otimizar seus estudos hoje mesmo.")
                        .font(.subheadline)
                        .foregroundColor(.dsTextSecondary)
                }
                .padding(.bottom, 16)
                
                // MARK: - Bloco de Inputs (Com ícones e bordas)
                VStack(spacing: 16) {
                    IconTextField(iconName: "person.fill", placeholder: "Nome completo", text: $name, isInvalid: validationErrors[.name] != nil, focusedField: $focusedField, field: .name)
                        .textContentType(.name)
                    
                    IconTextField(iconName: "envelope.fill", placeholder: "E-mail", text: $email, isInvalid: validationErrors[.email] != nil, focusedField: $focusedField, field: .email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    IconTextField(iconName: "lock.fill", placeholder: "Senha (mínimo 6 caracteres)", text: $password, isSecure: true, isInvalid: validationErrors[.password] != nil, focusedField: $focusedField, field: .password)
                        .textContentType(.newPassword)

                    IconTextField(iconName: "lock.fill", placeholder: "Confirmar senha", text: $confirmPassword, isSecure: true, isInvalid: validationErrors[.confirmPassword] != nil, focusedField: $focusedField, field: .confirmPassword)
                        .textContentType(.newPassword)

                    // Mostra a primeira mensagem de erro encontrada
                    if let firstError = firstErrorMessage {
                        Text(firstError)
                            .font(.caption)
                            .foregroundColor(.dsError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                    }
                }
                
                // MARK: - Termos de Uso (Com mais espaçamento)
                Toggle(isOn: $acceptTerms) {
                    Text("Eu li e aceito os [termos de uso](https://apple.com) e a [política de privacidade](https://apple.com).")
                        .font(.callout)
                        .tint(.dsPrimary) // Cor do link consistente
                }
                .toggleStyle(CheckboxToggleStyle())
                .padding(.vertical, 16) // Mais respiro
                
                // MARK: - Botão de Ação
                Button(action: handleRegistration) {
                    if isLoading { ProgressView().tint(.white) }
                    else { Text("Criar Conta") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!acceptTerms || isLoading || !areFieldsValid) // Lógica de desabilitar mais clara
                .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
                
                // Botão para voltar
                Button("Já tem uma conta? **Faça login**") { dismiss() }
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .modifier(ShakeEffect(shakes: registrationAttempts * 2))
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationBarHidden(true) // Esconde a barra de navegação padrão
    }

    // Propriedades computadas para validação e erros
    private var areFieldsValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
    }

    private var firstErrorMessage: String? {
        // Retorna a primeira mensagem de erro para exibir
        if let nameError = validationErrors[.name] { return nameError }
        if let emailError = validationErrors[.email] { return emailError }
        if let passwordError = validationErrors[.password] { return passwordError }
        if let confirmError = validationErrors[.confirmPassword] { return confirmError }
        return nil
    }

    // Funções (semelhantes a antes)
    private func handleRegistration() { /* ... */ }
    private func validateFields() -> Bool { /* ... */ return true }
}

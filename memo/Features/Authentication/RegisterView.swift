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
    @State private var errorText: String?
    @State private var isLoading = false
    @State private var validationErrors: [Field: String] = [:]
    @State private var registrationError: String?
    @State private var registrationAttempts = 0
    @State private var showSuccessAlert = false
    // ❌ removido: needsEmailConfirmation (não precisamos mais)

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
                        .frame(width: 120)
                        .padding(.top, 20)
                    
                    Text("Crie sua Conta")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Comece a otimizar seus estudos hoje mesmo.")
                        .font(.subheadline)
                        .foregroundColor(.dsTextSecondary)
                }
                .padding(.bottom, 16)
                
                // MARK: - Bloco de Inputs (Com ícones e bordas)
                VStack(spacing: 16) {
                    IconTextField(
                        iconName: "person.fill",
                        placeholder: "Nome completo",
                        text: $name,
                        isInvalid: validationErrors[.name] != nil,
                        focusedField: $focusedField,
                        field: .name
                    )
                    .textContentType(.name)
                    
                    IconTextField(
                        iconName: "envelope.fill",
                        placeholder: "E-mail",
                        text: $email,
                        isInvalid: validationErrors[.email] != nil,
                        focusedField: $focusedField,
                        field: .email
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)

                    IconTextField(
                        iconName: "lock.fill",
                        placeholder: "Senha (mínimo 6 caracteres)",
                        text: $password,
                        isSecure: true,
                        isInvalid: validationErrors[.password] != nil,
                        focusedField: $focusedField,
                        field: .password
                    )
                    .textContentType(.newPassword)

                    IconTextField(
                        iconName: "lock.fill",
                        placeholder: "Confirmar senha",
                        text: $confirmPassword,
                        isSecure: true,
                        isInvalid: validationErrors[.confirmPassword] != nil,
                        focusedField: $focusedField,
                        field: .confirmPassword
                    )
                    .textContentType(.newPassword)

                    // Mostra erros de validação ou de registro
                    if let registrationError = registrationError {
                        Text(registrationError)
                            .font(.caption)
                            .foregroundColor(.dsError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                    } else if let firstError = firstErrorMessage {
                        Text(firstError)
                            .font(.caption)
                            .foregroundColor(.dsError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                    }
                }
                
                // MARK: - Termos de Uso (Com mais espaçamento)
                Toggle(isOn: $acceptTerms) {
                    Text("Eu li e aceito os termos de uso e a política de privacidade.")
                        .font(.callout)
                }
                .toggleStyle(CheckboxToggleStyle())
                .padding(.top, 16)

                HStack(spacing: 8) {
                    Link("Ver Termos de Uso",
                         destination: URL(string: "https://gaad25.github.io/memo_legal/")!)
                        .font(.footnote)

                    Text("|")
                        .font(.footnote)

                    Link("Ver Política de Privacidade",
                         destination: URL(string: "https://gaad25.github.io/memo_privacidade/")!)
                        .font(.footnote)
                }
                .padding(.leading, 32)
                .tint(.dsPrimary)
                .padding(.bottom, 16)
                
                // MARK: - Botão de Ação
                Button(action: handleRegistration) {
                    if isLoading { ProgressView().tint(.white) }
                    else { Text("Criar Conta") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!acceptTerms || isLoading || !areFieldsValid)
                .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
                
                // Botão para voltar
                Button("Já tem uma conta? **Faça login**") { dismiss() }
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .modifier(ShakeEffect(shakes: registrationAttempts * 2))
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .onChange(of: name) { _, _ in
            validationErrors.removeValue(forKey: .name)
            registrationError = nil
        }
        .onChange(of: email) { _, _ in
            validationErrors.removeValue(forKey: .email)
            registrationError = nil
        }
        .onChange(of: password) { _, _ in
            validationErrors.removeValue(forKey: .password)
            registrationError = nil
        }
        .onChange(of: confirmPassword) { _, _ in
            validationErrors.removeValue(forKey: .confirmPassword)
            registrationError = nil
        }
        // ✅ Pop-up único de sucesso que retorna para a tela de login
        .alert("Conta criada com sucesso! 🎉", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }  // volta para a tela anterior (Login)
        } message: {
            Text("Faça login com seu e-mail e senha para continuar.")
        }
    }

    // Propriedades computadas para validação e erros
    private var areFieldsValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
    }

    private var firstErrorMessage: String? {
        if let nameError = validationErrors[.name] { return nameError }
        if let emailError = validationErrors[.email] { return emailError }
        if let passwordError = validationErrors[.password] { return passwordError }
        if let confirmError = validationErrors[.confirmPassword] { return confirmError }
        return nil
    }

    // MARK: - Actions
    
    private func handleRegistration() {
        focusedField = nil
        
        // Limpa erros anteriores
        validationErrors.removeAll()
        registrationError = nil
        
        // Valida campos
        guard validateFields() else {
            withAnimation(.default) {
                registrationAttempts += 1
            }
            return
        }
        
        // Inicia processo de registro
        isLoading = true
        
        Task {
            await handleRegistrationAsync()
        }
    }
    
    private func handleRegistrationAsync() async {
        registrationError = nil
        
        do {
            try await session.signUp(email: email, password: password, displayName: name)

            // ➜ IMPORTANTE:
            // Se você desativou a verificação de e-mail, o Supabase pode retornar uma sessão já logada.
            // Para garantir que o usuário volte para a tela de login (como você pediu),
            // fazemos signOut aqui. Se você preferir manter logado, remova a linha abaixo.
            await session.signOut()

            await MainActor.run {
                self.showSuccessAlert = true
                self.isLoading = false
            }
        } catch let error as AuthManagerError {
            await MainActor.run {
                switch error {
                case .custom(let message):
                    self.registrationError = message
                default:
                    self.registrationError = "Ocorreu um erro inesperado."
                }
                withAnimation { registrationAttempts += 1 }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.registrationError = error.localizedDescription
                withAnimation { registrationAttempts += 1 }
                self.isLoading = false
            }
        }
    }
    
    private func validateFields() -> Bool {
        var isValid = true
        
        // Validação do nome
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors[.name] = "Nome é obrigatório"
            isValid = false
        } else if name.count < 2 {
            validationErrors[.name] = "Nome deve ter pelo menos 2 caracteres"
            isValid = false
        }
        
        // Validação do email
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors[.email] = "Email é obrigatório"
            isValid = false
        } else if !isValidEmail(email) {
            validationErrors[.email] = "Formato de email inválido"
            isValid = false
        }
        
        // Validação da senha
        if password.isEmpty {
            validationErrors[.password] = "Senha é obrigatória"
            isValid = false
        } else if password.count < 6 {
            validationErrors[.password] = "Senha deve ter pelo menos 6 caracteres"
            isValid = false
        }
        
        // Validação da confirmação de senha
        if confirmPassword.isEmpty {
            validationErrors[.confirmPassword] = "Confirmação de senha é obrigatória"
            isValid = false
        } else if password != confirmPassword {
            validationErrors[.confirmPassword] = "Senhas não coincidem"
            isValid = false
        }
        
        return isValid
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

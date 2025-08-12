// memo/Features/Authentication/ForgotPasswordView.swift

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var submissionAttempts = 0
    @State private var emailError: String?
    
    @State private var showSuccessAlert = false

    // --- ALTERAÇÃO AQUI (1/2) ---
    // Trocamos o Bool por um enum para ser compatível com o IconTextField
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case email
    }
    // ----------------------------

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // MARK: - Header
                VStack(spacing: 8) {
                    Text("Recuperar Senha")
                        .font(.largeTitle.bold())
                    
                    Text("Digite o seu e-mail de registo. Enviaremos um link para que possa redefinir a sua senha.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                // MARK: - Email Field
                VStack(alignment: .leading, spacing: 4) {
                    // --- ALTERAÇÃO AQUI (2/2) ---
                    // Adicionamos os parâmetros 'focusedField' e 'field' que faltavam
                    IconTextField(
                        iconName: "envelope.fill",
                        placeholder: "E-mail",
                        text: $email,
                        isInvalid: emailError != nil,
                        focusedField: $focusedField,
                        field: .email
                    )
                    // ----------------------------
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    
                    if let emailError {
                        Text(emailError)
                            .font(.caption)
                            .foregroundColor(.dsError)
                            .padding(.horizontal, 8)
                    }
                }
                .modifier(ShakeEffect(shakes: submissionAttempts * 2))

                Spacer()

                // MARK: - Action Button
                Button(action: handlePasswordReset) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Enviar Link de Recuperação")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isLoading || email.isEmpty)
                .sensoryFeedback(.impact(weight: .light), trigger: isLoading)

            }
            .padding()
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .alert("Verifique o seu E-mail", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Se uma conta com o e-mail \(email) existir, um link para redefinir a sua senha foi enviado.")
            }
            .onChange(of: email) { _,_ in emailError = nil }
            // Focamos o campo de e-mail assim que a tela aparece
            .onAppear {
                focusedField = .email
            }
        }
    }

    // Funções de validação e de handle... (permanecem as mesmas)
    private func handlePasswordReset() {
        focusedField = nil
        guard validateEmail() else {
            withAnimation { submissionAttempts += 1 }
            return
        }
        isLoading = true
        // Lógica de envio...
    }

    private func validateEmail() -> Bool {
        if email.isEmpty || !email.contains("@") {
            emailError = "Por favor, insira um e-mail válido."
            return false
        }
        emailError = nil
        return true
    }
}

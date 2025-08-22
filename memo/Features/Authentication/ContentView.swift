// memo/Features/Authentication/ContentView.swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: SessionManager
    
    // MARK: - State
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var isLoading = false
    @State private var loginAttempts = 0
    @State private var authError: AuthError?
    

    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case email, password
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header
                    VStack(spacing: 16) {
                        Image("ic_memo_logo")
                            .resizable().scaledToFit().frame(width: 150)
                        Text("Entrar na sua conta")
                            .font(.headline).fontWeight(.bold)
                    }
                    .padding(.top, 60).padding(.bottom, 24)

                    // Form Fields
                    VStack(spacing: 16) {
                        IconTextField(iconName: "envelope.fill", placeholder: "E-mail", text: $email, isInvalid: authError != nil, focusedField: $focusedField, field: .email)
                            .keyboardType(.emailAddress).textContentType(.emailAddress).autocapitalization(.none)

                        IconTextField(
                            iconName: "lock.fill",
                            placeholder: "Senha",
                            text: $password,
                            isSecure: true,
                            isInvalid: authError != nil,
                            focusedField: $focusedField,
                            field: .password
                        )
                        .textContentType(.password)
                    }
                    
                    if let authError {
                        Text(authError.description).font(.footnote).foregroundColor(.dsError)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                    }
                    
                    HStack {
                        Toggle(isOn: $rememberMe) { Text("Lembrar").font(.callout) }
                            .toggleStyle(CheckboxToggleStyle())
                        Spacer()
                        NavigationLink("Esqueceu a senha?") { ForgotPasswordView() }
                            .font(.callout).tint(.dsPrimary)
                    }
                    .padding(.top, 8)

                    // Action Buttons
                    VStack(spacing: 24) {
                        Button(action: { Task { await handleLogin() } }) {
                            if isLoading { ProgressView().tint(.white) }
                            else { Text("Entrar") }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading)
                        .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
                        .modifier(ShakeEffect(shakes: loginAttempts * 2))

                        NavigationLink("Não tem uma conta? **Crie uma agora**") { RegisterView() }
                    }
                    .padding(.top, 40)
                }
                .padding(.horizontal, 24)
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .onChange(of: email) { _,_ in authError = nil }
            .onChange(of: password) { _,_ in authError = nil }
        }
    }
    
    private func handleLogin() async {
        focusedField = nil
        isLoading = true
        authError = nil
        
        await session.signIn(email: email, password: password)
        
        if let errorMessage = session.errorMessage {
            self.authError = .custom(message: errorMessage)
            withAnimation(.default) {
                loginAttempts += 1
            }
        } else if session.isLoggedIn {
            // Login bem-sucedido
            if rememberMe {
                // As credenciais já foram salvas no SessionManager.signIn()
                print("✅ Login bem-sucedido - credenciais salvas")
            } else {
                session.clearCredentials()
            }
        }
        isLoading = false
    }
    
    private enum AuthError: Error, CustomStringConvertible {
        case custom(message: String)
        var description: String {
            switch self {
            case .custom(let message):
                return "Falha ao entrar: \(message)"
            }
        }
    }
}

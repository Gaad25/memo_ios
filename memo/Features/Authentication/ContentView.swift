// memo/Features/Authentication/ContentView.swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: SessionManager

    @State private var email: String = ""
    @State private var senha: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var rememberCredentials: Bool = false
    @State private var navigateToRegister: Bool = false
    
    // NOVO ESTADO: Para controlar a apresentação da tela de recuperação
    @State private var showingForgotPassword = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color(uiColor: .systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Image("ic_memo_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 125)
                            .padding(.vertical, 40)

                        Text("Entrar na sua conta")
                            .font(.title2.bold())
                            .padding(.bottom, 20)

                        VStack(spacing: 16) {
                            TextField("E-mail", text: $email)
                                .padding(12)
                                .background(.background)
                                .cornerRadius(8)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)

                            SecureField("Senha", text: $senha)
                                .padding(12)
                                .background(.background)
                                .cornerRadius(8)
                        }

                        // --- INÍCIO DA MUDANÇA ---
                        HStack {
                            // Adicionamos o Toggle de "Lembrar credenciais" aqui
                            Toggle(isOn: $rememberCredentials) {
                                Text("Lembrar")
                                    .font(.footnote)
                            }
                            .toggleStyle(CheckboxToggleStyle()) // Usando o estilo customizado

                            Spacer()

                            Button("Esqueceu a senha?") {
                                showingForgotPassword = true
                            }
                            .font(.footnote)
                            .foregroundColor(.blue)
                        }
                        .padding(.bottom, 10)
                        // --- FIM DA MUDANÇA ---

                        if showError {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if isLoading {
                            ProgressView().padding(.vertical, 16)
                        }

                        Button("Entrar") {
                            Task { await login() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 10)

                        Text("OU")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 20)

                        Button(action: { /* Lógica de login com Google */ }) {
                            HStack {
                                Image("ic_google_logo")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                Text("Entrar com o Google")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.background)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

                        Spacer()

                        Button(action: { navigateToRegister = true }) {
                            Text("Não tem uma conta? **Crie uma agora**")
                                .font(.subheadline)
                        }
                        .padding(.top, 30)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView().environmentObject(session)
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                RegisterView().environmentObject(session)
            }
        }
    }
    // MARK: - Ação login (usa SessionManager)
    func login() async {
        let trimmedEmail  = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass   = senha.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPass.isEmpty else {
            errorMessage = "Preencha todos os campos."
            showError    = true
            return
        }

        isLoading  = true
        showError  = false

        // Limpa qualquer erro anterior do SessionManager
        session.errorMessage = nil
        
        await session.signIn(email: trimmedEmail, password: trimmedPass)

        if let err = session.errorMessage {
            errorMessage = "Falha ao entrar: \(err)"
            showError    = true
        } else {
            // SUCESSO: Verifica se deve salvar as credenciais
            if rememberCredentials {
                session.saveCredentials(email: trimmedEmail, password: trimmedPass)
            } else {
                // Se não for para lembrar, garante que credenciais antigas sejam limpas
                session.clearCredentials()
            }
        }

        isLoading = false
    }
}

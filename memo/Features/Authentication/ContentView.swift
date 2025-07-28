// memo/Features/Authentication/ContentView.swift

import SwiftUI

// ... (O CheckboxToggleStyle continua o mesmo)
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                configuration.label
            }
        })
        .buttonStyle(.plain)
    }
}


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
            ScrollView {
                VStack(spacing: 0) {

                    // --- Logo e título ---
                    Image("ic_memo_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 150)
                        .padding(.bottom, 32)

                    Text("Entrar")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.bottom, 16)

                    // --- Campos ---
                    TextField("E-mail", text: $email)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.bottom, 16)

                    SecureField("Senha", text: $senha)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                        .padding(.bottom, 8)

                    HStack {
                        Spacer()
                        // MODIFICAÇÃO: Transformado em botão
                        Button("Esqueceu a senha?") {
                            showingForgotPassword = true
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 16)

                    // --- Erro ---
                    if showError {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 16)
                    }

                    // --- Toggle lembrar ---
                    HStack {
                        Toggle(isOn: $rememberCredentials) {
                            Text("Lembrar credenciais")
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        Spacer()
                    }
                    .padding(.bottom, 16)

                    // --- Loading ---
                    if isLoading { ProgressView().padding(.bottom, 16) }

                    // --- Botão Entrar ---
                    Button(action: { Task { await login() } }) {
                        Text("Entrar")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.bottom, 24)

                    // --- Social login e registrar ---
                    Text("──────────  Entrar com  ─────────")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.bottom, 16)

                    Image("ic_google_logo")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .padding(.bottom, 24)

                    Button(action: { navigateToRegister = true }) {
                        Text("Criar Conta")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.bottom, 16)
                    .navigationDestination(isPresented: $navigateToRegister) {
                        RegisterView().environmentObject(session)
                    }
                }
                .padding(24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            // NOVO MODIFICADOR: Apresenta a tela como uma "folha" modal
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView().environmentObject(session)
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

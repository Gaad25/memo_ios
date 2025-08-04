import SwiftUI

struct RegisterView: View {
    // injeta o mesmo SessionManager usado no app inteiro
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    // ── Campos de formulário ─────────────────────────────────────────────
    @State private var nome            = ""
    @State private var email           = ""
    @State private var senha           = ""
    @State private var confirmarSenha  = ""
    @State private var aceitarTermos   = false

    // ── Estados de UI ────────────────────────────────────────────────────
    @State private var showError             = false
    @State private var errorMessage          = ""
    @State private var isLoading             = false
    @State private var showSuccessAlert      = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Fundo gradiente sutil, igual ao do Login
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color(uiColor: .systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        Text("Crie sua conta")
                            .font(.title2.bold())
                            .padding(.top, 40)
                            .padding(.bottom, 20)

                        // Campos
                        VStack(spacing: 16) {
                            TextField("Nome completo", text: $nome)
                                .styledTextField() // Reutilizando seu modifier!

                            TextField("E-mail", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .styledTextField()

                            SecureField("Senha", text: $senha)
                                .styledTextField()

                            SecureField("Confirmar senha", text: $confirmarSenha)
                                .styledTextField()
                        }

                        // Erro
                        if showError {
                            Text(errorMessage)
                                .font(.footnote.bold())
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Termos
                        Toggle(isOn: $aceitarTermos) {
                            Text("Aceito os termos de uso e política de privacidade")
                                .font(.caption)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        .padding(.vertical, 10)

                        // Loading
                        if isLoading { ProgressView().padding(.vertical, 16) }

                        // Botão Cadastrar
                        Button("Cadastrar", action: { Task { await registerUser() } })
                            .buttonStyle(PrimaryButtonStyle()) // Aplicando o estilo aqui também
                            .disabled(!aceitarTermos) // Boa prática desabilitar se os termos não forem aceitos

                        Spacer()
                        
                        // Já tem conta
                        Button("Já tem uma conta? **Faça login**") { dismiss() }
                            .font(.subheadline)
                            .padding(.top, 30)
                    }
                    .padding(24)
                }
            }
            .navigationBarHidden(true)
            .alert("Cadastro realizado!", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            }
        }
    }

    // Seu modifier `styledTextField` já está ótimo, pode mantê-lo como está no final do arquivo.

    // MARK: - Cadastro + login
    @MainActor
    private func registerUser() async {
        // Validações locais
        guard validarCampos() else { return }

        isLoading = true
        showError = false
        defer { isLoading = false }

        do {
            // Cria conta direto no Supabase
            try await SupabaseManager.shared.client.auth.signUp(email: email, password: senha) //


            // Faz login automático via SessionManager
            await session.signIn(email: email, password: senha)

            showSuccessAlert = true
        } catch {
            errorMessage = "Erro no cadastro: \(error.localizedDescription)"
            showError = true
        }
    }

    private func validarCampos() -> Bool {
        let nomeOk   = !nome.trimmingCharacters(in: .whitespaces).isEmpty
        let emailOk  = !email.trimmingCharacters(in: .whitespaces).isEmpty
        let senhaOk  = !senha.isEmpty && senha == confirmarSenha

        switch false {
        case nomeOk:
            errorMessage = "Preencha o nome."
        case emailOk:
            errorMessage = "Preencha o e-mail."
        case senhaOk:
            errorMessage = "Senhas não coincidem."
        case aceitarTermos:
            errorMessage = "Aceite os termos de uso."
        default:
            return true
        }
        showError = true
        return false
    }
}

// MARK: - Reusable modifier
private extension View {
    func styledTextField() -> some View {
        self.padding(12)
            .background(RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1))
    }
}

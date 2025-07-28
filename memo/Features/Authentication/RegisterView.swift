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
            ScrollView {
                VStack(spacing: 16) {

                    // Logo + título
                    Image("ic_memo_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .padding(.top, 32)

                    Text("Crie sua conta")
                        .font(.title.bold())
                        .padding(.bottom, 16)

                    // Campos
                    TextField("Nome completo", text: $nome)
                        .styledTextField()

                    TextField("E-mail", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .styledTextField()

                    SecureField("Senha", text: $senha)
                        .styledTextField()

                    SecureField("Confirmar senha", text: $confirmarSenha)
                        .styledTextField()

                    // Erro
                    if showError {
                        Text(errorMessage)
                            .font(.footnote.bold())
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Termos
                    Toggle(isOn: $aceitarTermos) {
                        Text("Aceito os termos de uso e política de privacidade")
                            .font(.footnote)
                    }

                    // Loading
                    if isLoading { ProgressView() }

                    // Botão Cadastrar
                    Button("Cadastrar", action: { Task { await registerUser() } })
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.vertical)

                    // Já tem conta
                    Button("Já tem uma conta? Faça login") { dismiss() }
                        .foregroundColor(.blue)
                        .font(.footnote)
                }
                .padding(24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarHidden(true)
            .alert("Cadastro realizado!", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            }
        }
    }

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

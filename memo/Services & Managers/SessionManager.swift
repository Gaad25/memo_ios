import SwiftUI
import Supabase

// MARK: - Authentication Errors
enum AuthManagerError: Error {
    case emailConfirmationRequired
    case networkError(Error)
    case unknown(Error)
    case custom(message: String)
}

// MARK: - Display Name Errors
enum DisplayNameError: LocalizedError {
    case networkError
    case duplicateName
    case invalidName
    case profanityDetected
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Erro de conexão. Tente novamente."
        case .duplicateName:
            return "Este nome já está em uso. Escolha outro."
        case .invalidName:
            return "Nome inválido. Verifique os requisitos."
        case .profanityDetected:
            return "Este nome de exibição não é permitido."
        case .unknown:
            return "Erro desconhecido. Tente novamente."
        }
    }
}

// Auxiliar para decodificar a resposta da Edge Function
private struct UpdateDisplayNameResponse: Decodable {
    let profile: UserProfile
}

/// `SessionManager` coordinates user authentication state.
/// The Supabase client and credential persistence are injected to make
/// the manager easier to test and to reduce global dependencies.
@MainActor
final class SessionManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading  = false
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile?

    private let client: SupabaseClient
    private let credentialsStore: CredentialsStore

    init(
        client: SupabaseClient = SupabaseManager.shared.client,
        credentialsStore: CredentialsStore = CredentialsStore()
    ) {
        self.client = client
        self.credentialsStore = credentialsStore
    }

    // Tenta fazer login automático ao iniciar o app
    func attemptAutoLogin() async {
        guard let credentials = credentialsStore.load() else { return }

        isLoading = true
        await signIn(email: credentials.email, password: credentials.password, isAutoLogin: true)
        isLoading = false
    }

    // Login
    // Adicionamos um parâmetro para diferenciar o login manual do automático
    func signIn(email: String, password: String, isAutoLogin: Bool = false) async {
        if !isAutoLogin { isLoading = true }
        defer { if !isAutoLogin { isLoading = false } }

        do {
            try await client.auth.signIn(email: email, password: password)
            
            // Limpa erro anterior se login foi bem-sucedido
            errorMessage = nil
            
            // Salva credenciais apenas para login manual bem-sucedido
            if !isAutoLogin {
                saveCredentials(email: email, password: password)
            }
            
            withAnimation { isLoggedIn = true }
        } catch {
            print("❌ Erro no SignIn: \(error.localizedDescription)")
            errorMessage = formatAuthError(error)
            
            // Se o login automático falhar, limpa as credenciais inválidas.
            if isAutoLogin { credentialsStore.clear() }
        }
    }
    
    // Registro de nova conta
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        do {
            let response = try await client.auth.signUp(email: email, password: password)

            if response.session == nil {
                throw AuthManagerError.emailConfirmationRequired
            }
            
            // Se chegou aqui, o login foi automático (sucesso total)
            // Salva credenciais para login automático
            saveCredentials(email: email, password: password)
            await MainActor.run { self.isLoggedIn = true }
            
        } catch let error as AuthManagerError {
            throw error // Re-lança o nosso erro personalizado
        } catch {
            // Lança um erro formatado para outros problemas do Supabase
            throw AuthManagerError.custom(message: self.formatAuthError(error))
        }
    }

    // Logout
    func signOut() async {
        try? await client.auth.signOut()
        credentialsStore.clear() // Limpa as credenciais ao sair
        withAnimation {
            isLoggedIn = false
            userProfile = nil // Limpa o perfil ao fazer logout
        }
    }
    
    // MARK: - User Profile Management
    
    // Carrega o perfil do usuário do Supabase
    func loadUserProfile() async {
        do {
            let userId = try await client.auth.session.user.id
            
            let response: [UserProfile] = try await client
                .from("user_profiles")
                .select("*")
                .eq("id", value: userId)
                .execute()
                .value
            
            await MainActor.run {
                self.userProfile = response.first
            }
        } catch {
            print("❌ Erro ao carregar perfil do usuário: \(error)")
        }
    }
    
    // Atualiza o display name do usuário
    func updateDisplayName(_ newName: String) async -> Result<String, DisplayNameError> {
        // 1) Filtro no Cliente (Feedback Rápido)
        let badWords: Set<String> = [
            // Palavrões comuns
            "idiota", "estupido", "burro", "merda", "caralho",
            "porra", "fdp", "viado", "gay", "puta", "vadia",
            // Palavras reservadas do sistema
            "admin", "suporte", "memo", "oficial", "bot"
        ]
        let cleanedName = newName.lowercased()
        if badWords.contains(where: { cleanedName.contains($0) }) {
            return .failure(.profanityDetected)
        }
        
        // 2) Chamar a Edge Function
        do {
            // URL base das Functions
            let baseURL = URL(string: "https://rrbebclkhexlfkexqrvf.supabase.co/functions/v1")!
            var request = URLRequest(url: baseURL.appending(path: "/update-display-name"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Token de autenticação
            if let session = try? await client.auth.session {
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            }
            
            // ⚠️ Corrigido: o backend espera "displayName"
            let body = ["displayName": newName]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // Chamada HTTP
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Verificação do status code
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError)
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                // Tenta mapear erros específicos retornados pela função
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = dict["error"] as? String {
                    if message.localizedCaseInsensitiveContains("não é permitido") {
                        return .failure(.profanityDetected)
                    }
                    if message.localizedCaseInsensitiveContains("já está em uso") ||
                       message.localizedCaseInsensitiveContains("already in use") {
                        return .failure(.duplicateName)
                    }
                }
                return .failure(.networkError)
            }
            
            // 3) Decodificar e reatribuir o perfil COMPLETO (dispara @Published)
            let decoded = try JSONDecoder().decode(UpdateDisplayNameResponse.self, from: data)
            await MainActor.run {
                self.userProfile = decoded.profile
            }
            
            // Retorna o nome efetivo (do backend) para consumo do chamador
            return .success(decoded.profile.displayName ?? newName)
            
        } catch {
            print("❌ Erro ao atualizar display name: \(error)")
            return .failure(.networkError)
        }
    }

    // MARK: - Gerenciamento de Credenciais

    // Salva as credenciais de forma segura.
    // NOTA: O e-mail (que não é um segredo) ainda é salvo no UserDefaults para
    // sabermos qual conta procurar no Keychain ao reabrir o app. A senha
    // é salva de forma segura no Keychain.
    func saveCredentials(email: String, password: String) {
        credentialsStore.save(email: email, password: password)
    }

    // Limpa as credenciais salvas.
    func clearCredentials() {
        credentialsStore.clear()
    }
    
    // MARK: - Tratamento de Erros
    
    // Converte erros do Supabase em mensagens amigáveis para o usuário
    func formatAuthError(_ error: Error) -> String {
        let errorMessage = error.localizedDescription
        
        // Verifica o conteúdo da string de erro para traduzir
        if errorMessage.contains("Invalid login credentials") {
            return "E-mail ou senha incorretos. Por favor, tente novamente."
        } else if errorMessage.contains("User already registered") ||
                  errorMessage.contains("email already registered") {
            return "Este e-mail já está em uso. Tente fazer login."
        } else if errorMessage.contains("Password should be at least 6 characters") ||
                  errorMessage.contains("password is too weak") {
            return "A sua senha precisa de ter pelo menos 6 caracteres."
        } else if errorMessage.contains("invalid email") ||
                  errorMessage.contains("email format") {
            return "Por favor, insira um endereço de e-mail válido."
        } else if errorMessage.contains("network") ||
                  errorMessage.contains("connection") ||
                  errorMessage.contains("timeout") {
            return "Problema de conexão. Verifique sua internet e tente novamente."
        } else if errorMessage.contains("rate limit") ||
                  errorMessage.contains("too many requests") {
            return "Muitas tentativas seguidas. Aguarde alguns minutos antes de tentar novamente."
        } else if errorMessage.contains("email not confirmed") ||
                  errorMessage.contains("confirmation") {
            return "Confirme seu e-mail antes de fazer login. Verifique sua caixa de entrada."
        } else if errorMessage.contains("signup disabled") {
            return "Novos registros estão temporariamente desabilitados. Tente mais tarde."
        } else if errorMessage.contains("invalid password") {
            return "Senha inválida. Verifique se digitou corretamente."
        } else if errorMessage.contains("weak password") {
            return "Escolha uma senha mais forte com pelo menos 6 caracteres."
        }
        
        // Fallback para erros não mapeados
        return "Ocorreu um erro inesperado. Por favor, tente mais tarde."
    }
}

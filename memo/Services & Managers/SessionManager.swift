//
//  SessionManager.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 22/05/25.
//
// memo/Services & Managers/SessionManager.swift

import SwiftUI
import Supabase

/// `SessionManager` coordinates user authentication state.
/// The Supabase client and credential persistence are injected to make
/// the manager easier to test and to reduce global dependencies.
@MainActor
final class SessionManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading  = false
    @Published var errorMessage: String?

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
            withAnimation { isLoggedIn = true }
        } catch {
            errorMessage = error.localizedDescription
            // Se o login automático falhar, limpa as credenciais inválidas.
            if isAutoLogin { credentialsStore.clear() }
        }
    }

    // Logout
    func signOut() async {
        try? await client.auth.signOut()
        credentialsStore.clear() // Limpa as credenciais ao sair
        withAnimation { isLoggedIn = false }
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
}

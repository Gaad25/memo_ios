//
//  SessionManager.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 22/05/25.
//
// memo/Services & Managers/SessionManager.swift

import SwiftUI
import Supabase

@MainActor
final class SessionManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading  = false
    @Published var errorMessage: String?

    // Chaves para salvar as credenciais no UserDefaults
    private let emailKey = "memoAppUserEmail"
    private let passwordKey = "memoAppUserPassword"

    // Tenta fazer login automático ao iniciar o app
    func attemptAutoLogin() async {
        guard let (email, password) = loadCredentials() else {
            return
        }
        
        isLoading = true
        await signIn(email: email, password: password, isAutoLogin: true)
        isLoading = false
    }

    // Login
    // Adicionamos um parâmetro para diferenciar o login manual do automático
    func signIn(email: String, password: String, isAutoLogin: Bool = false) async {
        if !isAutoLogin {
            isLoading = true
        }
        defer {
            if !isAutoLogin {
                isLoading = false
            }
        }

        do {
            try await SupabaseManager.shared.client.auth.signIn(email: email,
                                                                 password: password)
            withAnimation { isLoggedIn = true }
        } catch {
            errorMessage = error.localizedDescription
            // Se o login automático falhar, limpa as credenciais inválidas.
            if isAutoLogin {
                clearCredentials()
            }
        }
    }

    // Logout
    func signOut() async {
        try? await SupabaseManager.shared.client.auth.signOut()
        clearCredentials() // Limpa as credenciais ao sair
        withAnimation { isLoggedIn = false }
    }
    
    // MARK: - Gerenciamento de Credenciais
    
    // Salva as credenciais
    // NOTA DE SEGURANÇA: UserDefaults não é o ideal para senhas.
    // Para um app em produção, o correto seria usar o Keychain do iOS.
    func saveCredentials(email: String, password: String) {
        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(password, forKey: passwordKey)
    }
    
    // Carrega as credenciais
    private func loadCredentials() -> (email: String, password: String)? {
        guard let email = UserDefaults.standard.string(forKey: emailKey),
              let password = UserDefaults.standard.string(forKey: passwordKey) else {
            return nil
        }
        return (email, password)
    }
    
    // Limpa as credenciais
    func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: passwordKey)
    }
}

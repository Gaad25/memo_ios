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
    
    // Salva as credenciais de forma segura.
    // NOTA: O e-mail (que não é um segredo) ainda é salvo no UserDefaults para
    // sabermos qual conta procurar no Keychain ao reabrir o app. A senha
    // é salva de forma segura no Keychain.
    func saveCredentials(email: String, password: String) {
        UserDefaults.standard.set(email, forKey: emailKey)
        do {
            try KeychainHelper.save(password: password, forEmail: email)
        } catch {
            // Em um app real, seria bom logar este erro.
            print("❌ Erro ao salvar senha no Keychain: \(error)")
        }
    }
    
    // Carrega as credenciais.
    private func loadCredentials() -> (email: String, password: String)? {
        // Carrega o e-mail do UserDefaults.
        guard let email = UserDefaults.standard.string(forKey: emailKey) else {
            return nil
        }
        
        do {
            // Usa o e-mail para buscar a senha no Keychain.
            if let password = try KeychainHelper.load(forEmail: email) {
                return (email, password)
            }
        } catch {
            print("❌ Erro ao carregar senha do Keychain: \(error)")
        }
        
        return nil
    }
    
    // Limpa as credenciais salvas.
    func clearCredentials() {
        // Primeiro, tentamos pegar o e-mail salvo para saber qual entrada apagar do Keychain.
        if let email = UserDefaults.standard.string(forKey: emailKey) {
            do {
                try KeychainHelper.delete(forEmail: email)
            } catch {
                print("❌ Erro ao apagar senha do Keychain: \(error)")
            }
        }
        
        // Por fim, removemos o e-mail do UserDefaults.
        UserDefaults.standard.removeObject(forKey: emailKey)
        // A chave da senha não é mais usada, mas é bom remover caso ainda exista em instalações antigas.
        UserDefaults.standard.removeObject(forKey: passwordKey)
    }
}

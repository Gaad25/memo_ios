import Foundation
import Supabase

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userEmail: String? = nil

    private let client = SupabaseManager.shared.client

    func signUp(email: String, password: String, name: String) async throws {
        let session = try await client.auth.signUp(email: email, password: password)

        // Salva o usuário na tabela "usuarios"
        try await client.from("usuarios").insert([
            [
                "id": session.user.id.uuidString,
                "email": email,
                "nome": name
            ]
        ]).execute()

        self.isAuthenticated = true
        self.userEmail = email
    }

    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        self.isAuthenticated = true
        self.userEmail = session.user.email
    }

    func signOut() async throws {
        try await client.auth.signOut()
        self.isAuthenticated = false
        self.userEmail = nil
    }

    func checkSession() async {
        do {
            let user = try await client.auth.session.user
            self.isAuthenticated = true
            self.userEmail = user.email
        } catch {
            self.isAuthenticated = false
        }
    }
}


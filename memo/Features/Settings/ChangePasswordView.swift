//
//  ChangePasswordView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 04/08/25.
//
// memo/Features/Settings/ChangePasswordView.swift

import SwiftUI
import Supabase

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    
    // Estados para os campos de senha
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    // Estados para controle de UI
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Nova Senha"),
                    footer: Text("A senha deve ter no mínimo 6 caracteres.")
                ) {
                    SecureField("Nova Senha", text: $newPassword)
                    SecureField("Confirmar Nova Senha", text: $confirmPassword)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Alterar Senha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Salvar") {
                            Task { await updateUserPassword() }
                        }
                        .disabled(newPassword.isEmpty || newPassword != confirmPassword)
                    }
                }
            }
            .alert("Sucesso", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Sua senha foi alterada com sucesso.")
            }
        }
    }

    private func updateUserPassword() async {
        guard newPassword == confirmPassword else {
            errorMessage = "As senhas não coincidem."
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "A senha deve ter no mínimo 6 caracteres."
            return
        }
        
        isLoading = true
        errorMessage = nil

        do {
            // Cria o atributo de usuário para atualização
            let userAttributes = UserAttributes(password: newPassword)
            
            // Chama a função de atualização de usuário do Supabase Auth
            try await SupabaseManager.shared.client.auth.update(user: userAttributes)
            
            // Se a atualização for bem-sucedida, mostra o alerta
            showSuccessAlert = true
            
        } catch {
            errorMessage = "Não foi possível alterar a senha. Erro: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePasswordView()
    }
}

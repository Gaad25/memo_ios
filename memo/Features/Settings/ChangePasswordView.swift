//
//  ChangePasswordView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 04/08/25.
//
// memo/Features/Settings/ChangePasswordView.swift

import SwiftUI
import Supabase
@preconcurrency import Combine

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    
    // Estados para os campos de senha
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    // Estados para controle de UI
    @State private var errorMessage: String?
    @State private var newPasswordError: String?
    @State private var confirmPasswordError: String?
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var showSuccessCheck = false
    @State private var newPasswordShake = 0
    @State private var confirmPasswordShake = 0
    @FocusState private var focusedField: Field?

    private enum Field { case new, confirm }

    private var isValid: Bool {
        newPasswordError == nil && confirmPasswordError == nil && !newPassword.isEmpty && !confirmPassword.isEmpty
    }

    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("Alterar Senha")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .alert("Sucesso", isPresented: $showSuccessAlert) {
                    Button("OK") { dismiss() }
                } message: {
                    Text("Sua senha foi alterada com sucesso.")
                }
                .overlay(alignment: .center) { successOverlay }
                .scrollDismissesKeyboard(.interactively)
        }
        .onChange(of: newPassword) { _, _ in validateNewPassword() }
        .onChange(of: confirmPassword) { _, _ in validateConfirmPassword() }
    }

    @ViewBuilder
    private var formContent: some View {
        Form {
            passwordSection
            errorSection
        }
    }

    @ViewBuilder
    private var passwordSection: some View {
        Section(
            header: Text("Nova Senha"),
            footer: Text("A senha deve ter no mínimo 6 caracteres e as senhas devem coincidir.")
        ) {
            SecureField("Nova Senha", text: $newPassword)
                .textContentType(.newPassword)
                .submitLabel(.next)
                .focused($focusedField, equals: .new)
                .modifier(PrimaryTextFieldStyle(isInvalid: newPasswordError != nil))
                .modifier(ShakeEffect(shakes: newPasswordShake))
                .accessibilityLabel("Nova senha")
                .accessibilityHint("Informe a nova senha com no mínimo seis caracteres")
                .onChange(of: newPassword) { _, _ in Haptics.light(); validateNewPassword() }

            if let npError = newPasswordError {
                Text(npError).foregroundColor(.dsError).font(.footnote)
            }

            SecureField("Confirmar Nova Senha", text: $confirmPassword)
                .textContentType(.newPassword)
                .submitLabel(.done)
                .focused($focusedField, equals: .confirm)
                .modifier(PrimaryTextFieldStyle(isInvalid: confirmPasswordError != nil))
                .modifier(ShakeEffect(shakes: confirmPasswordShake))
                .accessibilityLabel("Confirmar nova senha")
                .accessibilityHint("Repita a nova senha")
                .onChange(of: confirmPassword) { _, _ in Haptics.light(); validateConfirmPassword() }

            if let cpError = confirmPasswordError {
                Text(cpError).foregroundColor(.dsError).font(.footnote)
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let message = errorMessage {
            Section { Text(message).foregroundColor(.red) }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancelar") { Haptics.light(); dismiss() }
                .accessibilityLabel("Cancelar")
                .accessibilityHint("Fechar sem salvar alterações")
        }
        ToolbarItem(placement: .confirmationAction) {
            if isLoading {
                ProgressView()
            } else {
                Button("Salvar") {
                    Haptics.light()
                    Task { await updateUserPassword() }
                }
                .disabled(!isValid)
                .accessibilityLabel("Salvar")
                .accessibilityHint("Salvar nova senha")
            }
        }
    }

    @ViewBuilder
    private var successOverlay: some View {
        if showSuccessCheck {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color.dsSuccess)
                .transition(.scale.combined(with: .opacity))
                .opacity(showSuccessCheck ? 1 : 0)
                .scaleEffect(showSuccessCheck ? 1 : 0.7)
        }
    }

    private func updateUserPassword() async {
        validateNewPassword(); validateConfirmPassword()
        guard isValid else {
            Haptics.error()
            withAnimation(.easeIn(duration: 0.12)) { newPasswordShake += 1; confirmPasswordShake += 1 }
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
            Haptics.success()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showSuccessCheck = true }
            showSuccessAlert = true
            
        } catch {
            errorMessage = "Não foi possível alterar a senha. Erro: \(error.localizedDescription)"
            Haptics.error()
        }
        
        isLoading = false
    }

    private func validateNewPassword() {
        if newPassword.count < 6 {
            newPasswordError = "A senha deve ter no mínimo 6 caracteres."
        } else {
            newPasswordError = nil
        }
    }
    private func validateConfirmPassword() {
        if !confirmPassword.isEmpty && confirmPassword != newPassword {
            confirmPasswordError = "As senhas não coincidem."
        } else {
            confirmPasswordError = nil
        }
    }
}

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePasswordView()
    }
}

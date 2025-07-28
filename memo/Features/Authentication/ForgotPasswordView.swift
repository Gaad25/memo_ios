//
//  ForgotPasswordView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 13/07/25.
//
// memo/Features/Authentication/ForgotPasswordView.swift

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Recuperar Senha")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 30)

                Text("Digite seu e-mail de cadastro. Enviaremos um link para você redefinir sua senha.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                TextField("E-mail", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

                if isLoading {
                    ProgressView()
                } else {
                    Button(action: {
                        Task { await requestPasswordReset() }
                    }) {
                        Text("Enviar Link de Recuperação")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
            .alert("Verifique seu E-mail", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text(alertMessage)
            }
            .alert("Erro", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func requestPasswordReset() async {
        isLoading = true
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            // CORREÇÃO: O nome correto da função é 'resetPasswordForEmail'
            try await SupabaseManager.shared.client.auth.resetPasswordForEmail(trimmedEmail)
            alertMessage = "Um link para redefinir sua senha foi enviado para \(trimmedEmail)."
            showSuccessAlert = true
        } catch {
            alertMessage = "Não foi possível iniciar a recuperação de senha. Verifique o e-mail digitado ou tente novamente mais tarde. Erro: \(error.localizedDescription)"
            showErrorAlert = true
        }
        isLoading = false
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}

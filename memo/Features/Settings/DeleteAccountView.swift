import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var session: SessionManager
    
    @State private var confirmationText = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    private let confirmationPhrase = "APAGAR"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Apagar sua conta?")
                    .font(.largeTitle.bold())
                
                Text("Esta ação é **permanente** e todos os seus dados de estudo (matérias, sessões, metas e progresso) serão perdidos para sempre.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Text("Para confirmar, digite **\(confirmationPhrase)** no campo abaixo:")
                    .font(.headline)
                    .padding(.top)
                
                TextField(confirmationPhrase, text: $confirmationText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .multilineTextAlignment(.center)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage).foregroundColor(.red).font(.footnote)
                }
                
                if isLoading {
                    ProgressView()
                }
                
                Spacer()

                Button("Apagar Conta Permanentemente", role: .destructive) {
                    Task { await deleteAccount() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .tint(.red)
                .disabled(confirmationText != confirmationPhrase)
                
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
    
    private func deleteAccount() async {
        guard confirmationText == confirmationPhrase else {
            errorMessage = "O texto de confirmação não corresponde."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Esta função será criada no Supabase na próxima etapa
            try await SupabaseManager.shared.client.rpc("delete_user_account").execute()
            
            // Força o logout no app
            await session.signOut()
            
        } catch {
            errorMessage = "Ocorreu um erro ao apagar sua conta: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

struct DeleteAccountView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteAccountView()
    }
}

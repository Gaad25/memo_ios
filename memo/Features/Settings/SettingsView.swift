//
//  SettingsView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 13/07/25.
//
// memo/Features/Settings/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    // Injeta o SessionManager para podermos chamar a função de logout.
    @EnvironmentObject private var session: SessionManager

    @State private var showingSignOutAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Sair da Conta", role: .destructive) {
                        showingSignOutAlert = true
                    }
                }
            }
            .navigationTitle("Configurações")
            .alert("Deseja realmente sair?", isPresented: $showingSignOutAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Sair", role: .destructive) {
                    // Executa a função de logout do SessionManager.
                    Task {
                        await session.signOut()
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SessionManager())
    }
}

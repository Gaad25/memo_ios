// memo/Features/Settings/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false

    @AppStorage(UserDefaultsKeys.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(UserDefaultsKeys.notificationTime) private var notificationTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            // Usando List com estilo .insetGrouped para uma UI moderna
            List {
                notificationsSection
                accountSection
                supportSection
                signOutSection // Seção dedicada para Sair
            }
            .navigationTitle("Configurações")
            .sheet(isPresented: $showingDeleteAccountAlert) {
                DeleteAccountView().environmentObject(session)
            }
            .alert("Deseja realmente sair?", isPresented: $showingSignOutAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Sair", role: .destructive) {
                    Task { await session.signOut() }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var notificationsSection: some View {
        Section(header: Text("Notificações")) {
            Toggle(isOn: $notificationsEnabled) {
                SettingsRowView(
                    iconName: "bell.badge.fill",
                    title: "Lembretes de Revisão",
                    iconColor: .purple
                )
            }
            
            if notificationsEnabled {
                DatePicker(
                    "Horário",
                    selection: $notificationTime,
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }
    
    private var accountSection: some View {
        Section(header: Text("Conta")) {
            NavigationLink(destination: ChangePasswordView()) {
                SettingsRowView(
                    iconName: "key.fill",
                    title: "Alterar Senha",
                    iconColor: .gray
                )
            }
            
            Button(action: { showingDeleteAccountAlert = true }) {
                SettingsRowView(
                    iconName: "trash.fill",
                    title: "Apagar Conta",
                    iconColor: .red,
                    isDestructive: true
                )
            }
        }
    }
    
    private var supportSection: some View {
        Section(header: Text("Sobre e Suporte")) {
            Link(destination: URL(string: "mailto:suporte@exemplo.com")!) {
                SettingsRowView(
                    iconName: "paperplane.fill",
                    title: "Fale Conosco",
                    iconColor: .blue
                )
            }
            
            Link(destination: URL(string: "https://apps.apple.com/app/idYOUR_APP_ID")!) {
                SettingsRowView(
                    iconName: "star.fill",
                    title: "Avaliar na App Store",
                    iconColor: .yellow
                )
            }
            
            SettingsRowView(
                iconName: "info.circle.fill",
                title: "Versão",
                iconColor: .secondary,
                value: appVersion
            )
        }
    }
    
    private var signOutSection: some View {
        Section {
            Button(action: { showingSignOutAlert = true }) {
                HStack {
                    Spacer()
                    Text("Sair da Conta")
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Reusable Row View

// Para manter o design consistente, criamos uma View reutilizável para cada linha.
struct SettingsRowView: View {
    let iconName: String
    let title: String
    let iconColor: Color
    var value: String? = nil
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(iconColor)
                .cornerRadius(8)
            
            Text(title)
                .foregroundColor(isDestructive ? .red : .primary)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SessionManager())
    }
}

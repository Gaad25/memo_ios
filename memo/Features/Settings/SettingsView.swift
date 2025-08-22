// memo/Features/Settings/SettingsView.swift

import SwiftUI
import UserNotifications
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var showingSignOutAlert = false
    @State private var showingDeleteDialog = false
    @State private var showingDeleteSheet = false
    @State private var showNotificationsRationale = false

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
            Form {
                notificationsSection
                accountSection
                supportSection
            }
            .formStyle(.grouped)
            .listSectionSpacing(32)
            .navigationTitle("Configurações")
            .sheet(isPresented: $showingDeleteSheet) {
                DeleteAccountView().environmentObject(session)
            }
            .alert("Ativar lembretes?", isPresented: $showNotificationsRationale) {
                Button("Agora não", role: .cancel) {
                    notificationsEnabled = false
                }
                Button("Permitir") {
                    Task { await requestNotificationPermissionIfNeeded() }
                }
            } message: {
                Text("Vamos lembrar você no horário escolhido para revisar seus estudos.")
            }
            .confirmationDialog(
                            "Apagar conta?",
                            isPresented: $showingDeleteDialog,
                            titleVisibility: Visibility.visible
                        ) {
                Button("Apagar Conta", role: .destructive) { showingDeleteSheet = true }
                Button("Cancelar", role: .cancel) { }
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
        Section(header: Text("Notificações").font(.headline).textCase(.none)) {
            Toggle(isOn: $notificationsEnabled) {
                SettingsRowView(
                    iconName: "bell.badge.fill",
                    title: "Lembretes de Revisão",
                    iconBackground: .dsIcon
                )
            }
            .sensoryFeedback(.impact(weight: .light), trigger: notificationsEnabled)
            .onChange(of: notificationsEnabled) { _, isOn in
                guard isOn else { return }
                showNotificationsRationale = true
            }

            if notificationsEnabled {
                DatePicker(
                    "Horário",
                    selection: $notificationTime,
                    displayedComponents: .hourAndMinute
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityLabel("Horário das notificações")
                .accessibilityHint("Selecione o horário diário para os lembretes de revisão")
            }
        }
        .animation(.easeInOut, value: notificationsEnabled)
    }
    
    private var accountSection: some View {
        Section(header: Text("Conta").font(.headline).textCase(.none)) {
            NavigationLink(destination: ChangePasswordView().transition(.move(edge: .trailing))) {
                SettingsRowView(
                    iconName: "key.fill",
                    title: "Alterar Senha",
                    iconBackground: .dsIcon
                )
            }
            .simultaneousGesture(TapGesture().onEnded { Haptics.light() })

            Button(action: {
                Haptics.light()
                showingDeleteDialog = true
            }) {
                SettingsRowView(
                    iconName: "trash.fill",
                    title: "Apagar Conta",
                    iconBackground: .dsIconDestructive,
                    isDestructive: true
                )
            }

            Button(action: {
                Haptics.light()
                showingSignOutAlert = true
            }) {
                SettingsRowView(
                    iconName: "rectangle.portrait.and.arrow.right.fill",
                    title: "Sair da Conta",
                    iconBackground: .dsIconDestructive,
                    isDestructive: true
                )
            }
        }
    }
    
    private var supportSection: some View {
        Section(header: Text("Sobre e Suporte").font(.headline).textCase(.none)) {
            Link(destination: URL(string: "mailto:suporte@exemplo.com")!) {
                SettingsRowView(
                    iconName: "paperplane.fill",
                    title: "Fale Conosco",
                    iconBackground: .dsIcon
                )
            }
            .simultaneousGesture(TapGesture().onEnded { Haptics.light() })

            Link(destination: URL(string: "https://apps.apple.com/app/idYOUR_APP_ID")!) {
                SettingsRowView(
                    iconName: "star.fill",
                    title: "Avaliar na App Store",
                    iconBackground: .dsIcon
                )
            }
            .simultaneousGesture(TapGesture().onEnded { Haptics.light() })

            SettingsRowView(
                iconName: "info.circle.fill",
                title: "Versão",
                iconBackground: .dsIcon,
                value: appVersion
            )
        }
    }
}

// MARK: - Notifications
private extension SettingsView {
    func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if !granted {
                    await MainActor.run { notificationsEnabled = false }
                }
            } catch {
                await MainActor.run { notificationsEnabled = false }
            }
        case .denied:
            // Sugerir abrir ajustes
            await MainActor.run {
                notificationsEnabled = false
            }
            if let url = URL(string: UIApplication.openSettingsURLString) {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Reusable Row View

// Para manter o design consistente, criamos uma View reutilizável para cada linha.
struct SettingsRowView: View {
    let iconName: String
    let title: String
    let iconBackground: Color
    var value: String? = nil
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.body)
                .foregroundColor(isDestructive ? .red : .primary)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .accessibilityLabel(title)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SessionManager())
    }
}

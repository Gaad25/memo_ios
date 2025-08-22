import SwiftUI
import ActivityKit

@main
struct MemoApp: App {
    @StateObject private var session = SessionManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            contentView
                .dynamicTypeSize(.xSmall ... .accessibility3)
                .onAppear {
                    Task {
                        await session.attemptAutoLogin()
                        // Garante que não ficam Live Activities órfãs ao abrir o app
                        await terminateOrphanedActivities()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        // Ação opcional: Se quisermos terminar a atividade
                        // quando a app vai para o background, podemos fazer isso aqui.
                        // Por agora, a limpeza no onAppear é a solução mais segura.
                    }
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if !hasCompletedOnboarding {
            // Se o onboarding não foi concluído, mostre-o.
            // A OnboardingView será responsável por definir hasCompletedOnboarding = true.
            OnboardingView(onFinish: {
                hasCompletedOnboarding = true
            })
        } else {
            // Se o onboarding já foi concluído, execute a lógica de login existente.
            if session.isLoading {
                VStack {
                    Text("Memo")
                        .font(.largeTitle.bold())
                    ProgressView()
                        .padding()
                }
            } else if session.isLoggedIn {
                MainTabView()
                    .environmentObject(session)
                    .environmentObject(HomeViewModel.shared)
            } else {
                ContentView()
                    .environmentObject(session)
            }
        }
    }
    
    // MARK: - Live Activity Cleanup
    
    /// Termina todas as Live Activities órfãs do cronómetro de estudos
    /// Esta função é chamada sempre que a app é iniciada para garantir
    /// que não ficam widgets "fantasma" na tela de bloqueio
    private func terminateOrphanedActivities() async {
        // Verifica se as Live Activities estão habilitadas
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        // Obtém todas as atividades ativas do tipo StudyTimerAttributes
        let activities = Activity<StudyTimerAttributes>.activities
        
        // Termina cada atividade encontrada
        for activity in activities {
            await activity.end(nil, dismissalPolicy: .immediate)
            print("Terminated orphaned activity: \(activity.id)")
        }
        
        // Log para debugging
        if !activities.isEmpty {
            print("✅ Cleaned up \(activities.count) orphaned Live Activities")
        }
    }
}

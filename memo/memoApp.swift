import SwiftUI

@main
struct MemoApp: App {
    @StateObject private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            contentView
                .onAppear {
                    Task {
                        await session.attemptAutoLogin()
                    }
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
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
        } else {
            ContentView()
                .environmentObject(session)
        }
    }
}

// memo/Features/Home/MainTabView.swift

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    // Enum para controlar a aba selecionada e os ícones
    enum Tab {
        case home, reviews, ai, ranking, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Início", systemImage: selectedTab == .home ? "house.fill" : "house")
                }
                .tag(Tab.home)

            ReviewsView()
                .tabItem {
                    Label("Revisões", systemImage: "calendar")
                }
                .tag(Tab.reviews)
            
            AIGeneratorView()
                .tabItem {
                    Label("Zoe", systemImage: "pawprint.fill")
                }
                .tag(Tab.ai)
            
            RankingView()
                .tabItem {
                    Label("Ranking", systemImage: "trophy.fill")
                }
                .tag(Tab.ranking)

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(.dsPrimary) // Define a cor de destaque para o item selecionado
    }
}

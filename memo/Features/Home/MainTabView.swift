// memo/Features/Home/MainTabView.swift

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    // Enum para controlar a aba selecionada e os ícones
    enum Tab {
        case home, reviews, ai, statistics, settings
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
                    Label("Revisões", systemImage: selectedTab == .reviews ? "calendar.day.timeline.left" : "calendar")
                }
                .tag(Tab.reviews)
            
            AIGeneratorView()
                .tabItem {
                    Label("IA", systemImage: selectedTab == .ai ? "sparkles" : "sparkle")
                }
                .tag(Tab.ai)
            
            StatisticsView()
                .tabItem {
                    Label("Estatísticas", systemImage: selectedTab == .statistics ? "chart.bar.xaxis" : "chart.bar")
                }
                .tag(Tab.statistics)

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(.dsPrimary) // Define a cor de destaque para o item selecionado
    }
}

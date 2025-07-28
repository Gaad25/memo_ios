//
//  MainTabView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 26/05/25.
//

// memo/Features/Home/MainTabView.swift

// memo/Features/Home/MainTabView.swift

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Início")
                }

            AllSessionsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Sessões")
                }
            
            // NOVA ABA DE REVISÕES
            ReviewsView()
                .tabItem {
                    Image(systemName: "calendar.day.timeline.left")
                    Text("Revisões")
                }

            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("Estatísticas")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Configurações")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(SessionManager())
    }
}

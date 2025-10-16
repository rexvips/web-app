//
//  MainTabView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    
    var body: some View {
        TabView(selection: $appCoordinator.selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: MainTab.dashboard.icon)
                    Text(MainTab.dashboard.rawValue)
                }
                .tag(MainTab.dashboard)
            
            RoutinesView()
                .tabItem {
                    Image(systemName: MainTab.routines.icon)
                    Text(MainTab.routines.rawValue)
                }
                .tag(MainTab.routines)
            
            MeditationView()
                .tabItem {
                    Image(systemName: MainTab.meditation.icon)
                    Text(MainTab.meditation.rawValue)
                }
                .tag(MainTab.meditation)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: MainTab.analytics.icon)
                    Text(MainTab.analytics.rawValue)
                }
                .tag(MainTab.analytics)
            
            SettingsView()
                .tabItem {
                    Image(systemName: MainTab.settings.icon)
                    Text(MainTab.settings.rawValue)
                }
                .tag(MainTab.settings)
        }
        .accentColor(.primary)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppCoordinator())
}
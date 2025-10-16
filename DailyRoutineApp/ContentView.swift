//
//  ContentView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dependencies: AppDependencies
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
    }
    
    private func checkOnboardingStatus() {
        // Check if user has completed onboarding
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        showOnboarding = !hasCompletedOnboarding
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDependencies())
        .environmentObject(AppCoordinator())
}
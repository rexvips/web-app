//
//  ContentView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appCoordinator: AppCoordinator
    @EnvironmentObject private var appDependencies: AppDependencies
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    
    var body: some View {
        NavigationStack(path: $appCoordinator.navigationPath) {
            Group {
                if onboardingViewModel.shouldShowOnboarding {
                    OnboardingView(viewModel: onboardingViewModel)
                } else {
                    MainTabView()
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                appCoordinator.view(for: route)
            }
        }
        .onAppear {
            onboardingViewModel.checkOnboardingStatus()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDependencies())
        .environmentObject(AppCoordinator())
}
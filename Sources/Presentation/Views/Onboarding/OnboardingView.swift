//
//  OnboardingView.swift
//  DailyRoutineApp
//
//  Created by GitHub Copilot on 16/10/2025.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Welcome Screen
            OnboardingPage(
                title: "Welcome to Daily Routine",
                subtitle: "Build better habits and routines with guided meditation and smart tracking",
                imageName: "figure.mind.and.body",
                color: .blue
            )
            .tag(0)
            
            // Meditation Screen
            OnboardingPage(
                title: "Mindful Meditation",
                subtitle: "Practice box breathing, 4-7-8 techniques, and custom meditation timers",
                imageName: "leaf.fill",
                color: .green
            )
            .tag(1)
            
            // Tracking Screen
            OnboardingPage(
                title: "Smart Tracking",
                subtitle: "Monitor your progress, build streaks, and get personalized insights",
                imageName: "chart.line.uptrend.xyaxis",
                color: .purple
            )
            .tag(2)
            
            // Permissions Screen
            PermissionsPage(viewModel: viewModel)
                .tag(3)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .onAppear {
            AnalyticsManager.shared.track(.screenViewed("onboarding"))
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let imageName: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundColor(color)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct PermissionsPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Enable Notifications")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Get gentle reminders for your routines, habits, and meditation sessions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Remind you of routines and habits",
                    isGranted: viewModel.notificationPermissionGranted
                ) {
                    viewModel.requestNotificationPermission()
                }
                
                PermissionRow(
                    icon: "heart.fill",
                    title: "HealthKit (Optional)",
                    description: "Track meditation sessions and heart rate",
                    isGranted: viewModel.healthKitPermissionGranted
                ) {
                    viewModel.requestHealthKitPermission()
                }
            }
            
            Spacer()
            
            Button("Get Started") {
                viewModel.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
        }
        .padding()
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Allow") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

class OnboardingViewModel: ObservableObject {
    @Published var shouldShowOnboarding = true
    @Published var notificationPermissionGranted = false
    @Published var healthKitPermissionGranted = false
    
    func checkOnboardingStatus() {
        shouldShowOnboarding = !UserDefaults.standard.bool(forKey: "onboarding_completed")
    }
    
    func requestNotificationPermission() {
        // Implementation would request notification permission
        Task {
            // Simulate permission request
            await MainActor.run {
                self.notificationPermissionGranted = true
            }
        }
    }
    
    func requestHealthKitPermission() {
        // Implementation would request HealthKit permission
        Task {
            // Simulate permission request
            await MainActor.run {
                self.healthKitPermissionGranted = true
            }
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        shouldShowOnboarding = false
        
        AnalyticsManager.shared.track(.onboardingCompleted)
        AppLogger.shared.log("Onboarding completed", level: .info, category: "Onboarding")
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel())
}